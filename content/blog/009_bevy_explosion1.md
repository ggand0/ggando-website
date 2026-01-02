+++
title = "Porting UE5 explosion to Bevy"
slug = "bevy-explosion1"
date = 2025-12-13
draft = false

[extra]
thumb = "https://ggando.b-cdn.net/bevy_explosion1_640.jpg"

[taxonomies]
categories = ["blog"]
tags = ["rust", "bevy", "gamedev", "shader"]
+++

<img src="https://ggando.b-cdn.net/bevy_explosion1_1280.jpg" alt="img0" width="640" style="display: block; margin: auto;"/>

## Ground Explosion
The War FX explosion in [the previous post](https://ggando.com/blog/bevy-explosion0/ ) worked well for tower destruction, but I wanted to make the battlefield more alive by implementing the artillery explosions.

I found this paid CC-BY explosion effect on fab.com while looking for an artillery impact explosion looking like the one from CoH1 when you use the 105mm howitzer. I was unable to find ground explosions that don't have much fireballs except this one. I was assuming that it was a Unity prefab, but realized that this is an UE5 asset. I had to install a newer UE 5.4.4 just to access it, because I bought it on fab.com and you'd need a Fab plugin for your UE but they don't support versions < 5.3. I was on 5.1, so I downloaded a pre-built binary from the official website.

I was considering just using my eyes to reproduce the effect, but luckily there's a way: you can convert uassets into a much more LLM-friendly Unreal Text 3D (.T3D) format by right-clicking the asset in the content drawer → Asset Actions → select Export. 
After importing the asset to a temporary UE project via the fab plugin, I exported the Niagara particle asset into .T3D. It's just nested key-value pairs with object hierarchy and LLM-friendly. The one I exported had 33,000+ lines so you'd need to write a script to analyze it.

I also had to do the same export for material assets to extract material graph details.
Then, just like the last time I had the AI agent extract the particle emitter details like particle attributes and alpha curves emitter by emitter. This time I used Claude Opus 4.5, since the last time I ported the Unity asset Sonnet 4.5 was kind of struggling. I thought this one will be easy as it's just a bunch of animated billboards and no weird blending details. But it turns out to be pretty time-consuming as well.
After feeding the gamedev agent with the emitter details and implementing them it somewhat looked decent, but other than the simple spark emitters they looked pretty different from the original effect on UE5 and I had to rework them one by one. Here are some of the issues I solved:

#### Bug 1: textures are wrong
A super obvious point but it happened to me twice since I let Claude do everything at the beginning including the texture copying part. Likely the texture asset name in the extracted details was wrong initially. If you're seeing a fundamentally wrong effect, then you should doubt this first.

#### Bug 2: texture animating when it shouldn't
I had a problem with the dust emitter; initially it was using a wrong texture but even after correcting that it still looked completely wrong: particles were "flashing" and the effect was sparse and jittery. So, I asked the analyzer agent to go through the emitter details again, and it turns out that we shouldn't be animating texture but rather use a random sprite in the spritesheet.
UE5's Niagara has a `SubUV Animation Mode` parameter with multiple options:
- Linear  (default): Sequential frame animation 0→1→2→3…
- Random  (NewEnumerator2): Each particle picks ONE random frame at spawn, stays fixed
The dust emitter uses Random  mode - each particle shows a different static frame for visual variety, NOT an animation. The T3D export showed SubUV Animation Mode = NewEnumerator2  which means Random.

#### Bug 3: wrong plane
There was a smoke emitter where particles spread in a plane, and in the T3D file it was specified as bLocalSpace=True . We first interpreted it as the XY plane, but it turns out that it was the screen plane, not the world ground plane.

#### Bug  4: Alpha > 1.0 as Brightness Multiplier
My implementation of dust and wisp emitters looked too dim and faint compared to the original effect. This was because UE5's Niagara uses alpha values > 1.0 as brightness multipliers. For example, an alpha of 3.0 means "3× brighter RGB, but still fully opaque." Here's the shader fix to handle alpha-as-brightness:
```rust
let alpha_multiplier = color_data.a;
let tinted_color = sprite_sample.rgb * color_data.rgb * alpha_multiplier;
let final_alpha = sprite_sample.a * min(alpha_multiplier, 1.0);
```

#### End result
When it comes to VFX you'd still need to eyeball it to check by yourself as LLMs can sometimes make wrong assumptions. After going through these fixes I'm satisfied with the result, considering we're not using the UE5's sophisticated Niagara particle system. Here's the resulting explosion effect:

<div style="position:relative;padding-top:56.25%;"><iframe src="https://iframe.mediadelivery.net/embed/399279/879b6dca-4393-467f-a8dc-760851b034b3?autoplay=false&loop=false&muted=false&preload=false&responsive=true" loading="lazy" style="border:0;position:absolute;top:0;height:100%;width:100%;" allow="accelerometer;gyroscope;autoplay;encrypted-media;picture-in-picture;" allowfullscreen="true"></iframe></div>


For more details on the GPU particle setup, see [my TIL post on Bevy GPU particles](@/til/007_bevy_gpu_particles.md).


<br/>