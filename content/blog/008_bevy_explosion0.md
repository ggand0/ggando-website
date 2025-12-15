+++
title = "Porting Unity Particle Effects to Bevy: Billboard Explosions"
slug = "bevy-explosion0"
date = 2025-12-12
draft = false

[extra]
thumb = "https://ggando.b-cdn.net/bevy_explosion0_640.jpg"

[taxonomies]
categories = ["blog"]
tags = ["rust", "bevy", "gamedev", "shader"]
+++

<img src="https://ggando.b-cdn.net/bevy_explosion0_1280.jpg" alt="img0" width="640" style="display: block; margin: auto;"/>

#### Motivation
Rewarding outcome of actions is what makes games more engaging to play, and I think visual feedback is one of the most important factors. When you destroy the enemy for example, you want to feel that impact with a nice explosion VFX.

I’ve been building a 3D RTS game as a hobby recently, and wanted to implement a decent billboard-based explosion effect since it's essential for making the gameplay more satisfying.
However, I realized that there seem to be no open-source examples of this as far as I researched online. Perhaps it's also because there's asset stores you can sell and people are not encouraged to release assets for free.

So, I decided to port an existing asset into Bevy. I found a free Unity Store asset called [WarFX](https://assetstore.unity.com/packages/vfx/particles/war-fx-5669) which I thought would fit perfectly. It has billboard-based particle style aesthetic seen in early 2000s RTS games like Empire at War or Company of Heroes 1, which is exactly what I'm going for in terms of game design.
#### YAML conversion and implementation
Unity stores prefabs in a binary format by default, which makes them impossible for AI tools (or humans) to analyze programmatically. Fortunately, Unity can serialize them as YAML instead by enabling the "Force Text" mode on the unity prefab file. This way we can utilize LLMs to go through the details without having to use your eyes to reproduce them from scratch.
1. Edit → Project Settings → Editor → Asset Serialization → Mode
2. Enable Force Text mode
3. Unity re-serializes those assets as YAML when saving

I usually use Claude Code, and my workflow was to have Claude Sonnet 4.5 extract the detailed attributes of particle emitters one by one, and save them into structured markdown files. Then I implemented each emitter type one by one as a custom billboard particle system with another Sonnet 4.5 in my gamedev project. When things were unclear, I had the gamedev agent write a prompt to the analyzer agent and communicate with each other.

For the implementation, I used bevy_hanabi for sparks and debris, but others were implemented as a group of dynamically spawned quad meshes with custom Material types using custom blend modes and WGSL shaders.
#### Challenge 1: Missing Initial Colors
Initially I had trouble with invisible billboards for the core flame particles, but it turns out that the initial extracted attributes were not complete. The prefab yaml file has 25,000 lines, so it's easy to miss the details. In my case, the initial extraction python script only focused on ColorModule  (Color Over Lifetime) but missed the InitialModule.startColor  field, which was buried deep in the prefab YAML and used a non-obvious minMaxState  enum.
#### Challenge 2: UV Scrolling
I disabled UV scrolling completely as the texture content would get cut off at the top edge of the quad mesh. I might try to reintroduce this with a proper wrap sampler mode in the future.
#### Challenge 3: Dark Cores, Bright Rims
The most subtle but critical bug was that flame billboards had dark cores and bright rims, which is the opposite of what they should be. The explosion flame particle uses this lerp operation that works as a smooth gradient between bright / dark areas, and the bright part makes it look like particles have flames at the core. Here's some visualization in ascii:
```
Without lerp:                 With lerp:
┌─────────────────┐           ┌─────────────────┐
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│           │                 │
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│           │   ░░░░░░░░░     │
│▓▓▓▓▓SMOKE▓▓▓▓▓▓▓│           │  ░▒▒▒▒▒▒▒▒▒░    │
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│           │  ░▒▓SMOKE▓▒░    │
│▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓│           │  ░▒▒▒▒▒▒▒▒▒░    │
└─────────────────┘           │   ░░░░░░░░░     │
  visible quad edge           │                 │
                              └─────────────────┘
                                soft falloff, no visible edge
```
The `lerp(0.5, color, mask)` formula I used was correct for Unity, but Unity and Bevy implement the multiply blend differently:
- Unity : `dst * (src.rgb + src.a)`
- Bevy AlphaMode::Multiply : `dst * (src.rgb + 1 - src.a)`

They apparently use different blend equations. This difference was breaking the math, and I had to override Bevy's blend state via `Material::specialize()` to match Unity's equation. I learned that common operations like "multiply blend" can have different implementations between engines.
Here's the resulting explosion effect I implemented. It's not perfect, but this is so much better than a single-billboard explosion effect I had before:

<div style="position:relative;padding-top:56.25%;"><iframe src="https://iframe.mediadelivery.net/embed/399279/211f6468-6466-4490-97d5-fab1db52745d?autoplay=false&loop=false&muted=false&preload=false&responsive=true" loading="lazy" style="border:0;position:absolute;top:0;height:100%;width:100%;" allow="accelerometer;gyroscope;autoplay;encrypted-media;picture-in-picture;" allowfullscreen="true"></iframe></div>

Then, I incorporated this into this tower explosion effect with more bevy_hanabi particles. Here, I spawned 500 spherical billboard particles that fill a 80-unit sphere, transitioning from bright yellow-orange to dark red over their lifetime. They have a nice drag down arc due to the gravity.
<div style="position:relative;padding-top:56.25%;"><iframe src="https://iframe.mediadelivery.net/embed/399279/f7730d99-6e49-4019-8959-46bb10d54b20?autoplay=false&loop=false&muted=false&preload=false&responsive=true" loading="lazy" style="border:0;position:absolute;top:0;height:100%;width:100%;" allow="accelerometer;gyroscope;autoplay;encrypted-media;picture-in-picture;" allowfullscreen="true"></iframe></div>

Code available at [this repo](https://github.com/ggand0/bevy-rts-sim/blob/main/src/wfx_spawn.rs).

<br/>