+++
title = "CPU to GPU Particle Migration in Bevy: The Billboard Illusion"
slug = "bevy-gpu-particles"
date = 2025-12-24
draft = false

[extra]
thumb = "https://ggando.b-cdn.net/bevy_gpu_particles_640.jpg"

[taxonomies]
categories = ["til"]
tags = ["rust", "bevy", "gamedev", "shader"]
+++


## The Problem

Ground explosions in my RTS game were killing performance. Each explosion spawned 150-280 ECS entities - individual particles for sparks, flash sparks, debris, dirt, smoke, and more. During artillery barrages with 6-10 simultaneous explosions, FPS tanked from 100 to 40.

The CPU particle system was nice and simple where each particle was a Bevy entity with a mesh, material, and transform. But when I spawn them multiple times to create a barrage effect, it was crushing the FPS.

So I decided to migrate to bevy_hanabi GPU particles. The idea is simple: instead of spawning hundreds of CPU entities, you get a single draw call per emitter type. Should be straightforward, right?

## The Easy Wins

The first emitters migrated relatively smoothly. Sparks, flash sparks, and parts debris went from ~100-185 entities down to 3 GPU effects. Some gotchas along the way:

**Additive blending is non-negotiable.** GPU sparks showed dark/brown backgrounds instead of glowing. bevy_hanabi defaults to `AlphaMode::Blend`, but sparks need `AlphaMode::Add`.

**Watch for hidden brightness multipliers.** GPU particles appeared orange-red instead of hot yellow-white. Turns out my CPU shader had a 4x brightness multiplier that I'd completely forgotten about. GPU gradients need the final rendered values directly.

**Velocity axis conventions differ.** bevy_hanabi's `AlongVelocity` mode uses X axis along velocity, while my CPU `VelocityAligned` used Y axis. Swap your size gradient axes.

**Drag ≠ deceleration.** `LinearDragModifier` applies velocity-proportional drag (exponential decay). My CPU used constant deceleration. Replaced drag with `AccelModifier` to match the original behavior.

## The Main Emitter Nightmare

Then I got to the main emitters that spawn directional blasts from the explosion. What started as "should be straightforward" became 8 devlogs and eventually required forking bevy_hanabi.

### The Mirroring Mystery

The core symptom was that particles appeared to travel "inward toward center then fly out the other side" - visually mirrored. I spent days investigating:

- Cross product sign flips in orientation math
- Quaternion vs axis-based rotation differences
- Camera-space vs world-space coordinate systems
- bevy_hanabi's `AlongVelocity` implementation details

I tried at least 9 different approaches to fix the orientation: Gram-Schmidt orthogonalization, world-up reference vectors, quaternion-based rotation, camera-right projection... all failed. The mirroring persisted no matter what I tried.

### The Debug Breakthrough

After days of frustration, I spawned small colored quads (R=+X velocity, G=+Y, B=+Z) instead of large blasts with UV zoom to visualize actual particle velocities (which I should have done way earlier).

**The velocities were correct the whole time.**

Particles clearly moved outward and the motion was 100% correct.

### The Actual Problem: A Visual Illusion

The "mirroring" was a perceptual illusion caused by the intense UV zoom effect. The main emitters use a 500x→1x UV zoom over their lifetime to create the "debris burst expanding from impact point" look.

Here's the math: with UV scale starting at 500x, the visible texture region at t=0 is ~0.016m (tiny center point). At t=1, it's 20m (full blast). That's an apparent expansion rate of ~13 m/s radially outward from texture center.

Meanwhile, actual particle velocity was only 3-5 m/s. The UV zoom's apparent motion completely dominated, and because it expanded from center (not bottom-pivot like CPU), it created the illusion of incorrect movement direction.

## The Actual Fixes

Once I understood what was really happening, the fixes were straightforward:

### Fix 1: UVScaleOverLifetimeModifier Bug

My custom modifier had inverted math:
```wgsl
// WRONG: multiplying sends UVs out of bounds
let uv_scaled = uv_centered * uv_scale + vec2(0.5, 0.5);
// With scale=500: UV 0.0 becomes -249.5 (samples edge/garbage)

// CORRECT: dividing zooms IN on center  
let uv_scaled = uv_centered / uv_scale + vec2(0.5, 0.5);
// With scale=500: UV 0.0 becomes 0.499 (samples center)
```

This was sampling edge pixels (solid color) instead of zooming in on the center.

### Fix 2: UV Pivot

CPU main emitters use bottom-pivot - the UV zoom expands upward along velocity. My GPU zoom expanded from center, fighting the particle motion. Added configurable pivot to the modifier.

### Fix 3: SimulationSpace::Local

bevy_hanabi defaults to `SimulationSpace::Global`, which ignores `Transform.scale`. CPU velocity was scaled, GPU was fixed. Switched to `SimulationSpace::Local`.

### Fix 4: Expression Re-evaluation

bevy_hanabi's `ExprWriter` re-evaluates `rand()` calls on every expression use. Cloning an expression doesn't preserve computed values:
```rust
let dir = rx.vec3(ry, rz).normalized();  // Uses rand()
let pos = dir.clone() * radius;          // NEW random values!
let vel = dir.clone() * speed;           // DIFFERENT random values!
// Result: pos and vel point in completely different directions
```

Fixed by reading the POSITION attribute after it's set:
```rust
let fb_pos = rx.vec3(ry, rz).normalized() * radius;
let init_pos = SetAttributeModifier::new(Attribute::POSITION, fb_pos.expr());

let pos_read = writer.attr(Attribute::POSITION);  // Read back!
let velocity = pos_read.normalized() * speed;
```

## The Cleanup

After that ordeal, the remaining emitters (dust ring, smoke cloud, wisp puffs) were refreshingly straightforward. A few notes:

- For `FaceCameraPosition` orientation, use `.with_rotation()` not `.with_axis_rotation()` for random sprite rotation
- Flipbook animation requires updating `SPRITE_INDEX` in the update phase, not just init
- Non-uniform X/Y scaling works with `SizeOverLifetimeModifier` using `Gradient<Vec3>`

## Results

| Emitter | CPU Entities | GPU Entities |
|---------|-------------|--------------|
| Main Blast | 9-17 | 1 |
| Secondary Blast | 7-13 | 1 |
| Sparks | 30-60 | 1 |
| Flash Sparks | 20-50 | 1 |
| Parts Debris | 50-75 | 1 |
| Dirt Debris | ~35 | 1 |
| Velocity Dirt | 10-15 | 1 |
| Dust Ring | 2-3 | 1 |
| Smoke Cloud | 10-15 | 1 |
| Wisp Puffs | 3 | 1 |

**Total reduction**: ~170-290 entities → ~10 entities per explosion (95% reduction)

**Performance**: 8-shell barrages now maintain 80+ FPS instead of dropping to 40.

## Key Takeaways

1. **Debug with simple visuals first.** Small colored quads revealed correct velocity when complex effects created illusions.

2. **UV zoom can overwhelm particle motion.** 500x zoom creates ~13 m/s apparent motion that drowns out 3-5 m/s actual velocity.

3. **UV zoom math is counterintuitive.** Divide to zoom in, multiply to zoom out.

4. **Expression cloning re-evaluates.** Use `attr()` to read back computed values in bevy_hanabi.

5. **SimulationSpace affects scale.** Global ignores transform scale, Local applies it.

6. **Sometimes you need to fork.** Complex VFX may require engine modifications.

The whole migration took about 9 days, with ~60% spent on the main emitters orientation/velocity issues that turned out to be mostly a visual illusion. Was it worth it? The 95% entity reduction and stable 80+ FPS during barrages say yes. But I learned a lesson to actually think with my brain during debugging rather than cursing at Claude.