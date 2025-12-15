+++
title = "MuJoCo SO101 clipping issue"
slug = "mujoco-so101-clipping"
date = 2025-12-15
draft = false

[taxonomies]
categories = ["rl", "mujoco", "so101"]
tags = ["blog"]
+++

I'm training an SO-101 arm on a simple cube lift task with MuJoCo and RL, but so far it's stuck at a local optimum where the arm just contacts the cube in some way and doesn't attempt to lift at all.

I noticed that when this happens, the z coord of the cube is slightly below the initial position (on the ground): it's placed at z=0.01 but I was seeing values like z=0.007, which means the arm was pushing the cube down.

I created three camera angles during eval episodes to see what's going on, and it turned out that the tip of the bottom part of the gripper was clipping through the cube:

<div style="position:relative;padding-top:56.25%;"><iframe src="https://iframe.mediadelivery.net/embed/399279/09679cca-d004-42c8-bc59-d61c5a5c7f0a?autoplay=false&loop=false&muted=false&preload=false&responsive=true" loading="lazy" style="border:0;position:absolute;top:0;height:100%;width:100%;" allow="accelerometer;gyroscope;autoplay;encrypted-media;picture-in-picture;" allowfullscreen="true"></iframe></div>

Fixed this by doing the following:
### 1. Added box collision primitives to gripper tips
In `SO-ARM100/Simulation/SO101/so101_new_calib.xml`:
Static gripper tip (line 111): Added inside the gripper body, after the wrist_roll_follower mesh
```xml
<geom name="static_gripper_tip" type="box" class="collision" 
      size="0.008 0.006 0.018" pos="-0.008 0 -0.088"/>
```
Moving jaw tip (line 123): Added inside the moving_jaw_so101_v1 body, after its mesh
```
<geom name="moving_jaw_tip" type="box" class="collision" 
      size="0.006 0.004 0.015" pos="0 -0.055 0.019"/>
```
### 2. Stiffened contact parameters
In `SO-ARM100/Simulation/SO101/lift_cube_scene.xml`:
```xml
<option timestep="0.002" gravity="0 0 -9.81" noslip_iterations="3"/>

<default>
    <geom solref="0.001 1" solimp="0.99 0.99 0.001"/>
</default>
```
This changed contacts from soft rubber (~1-10 MPa) to hard plastic (~1-10 GPa), matching real PLA/wood materials.

### Result
After the fix, the clipping no longer seems to happen:
<div style="position:relative;padding-top:56.25%;"><iframe src="https://iframe.mediadelivery.net/embed/399279/5066e546-43e0-468d-b8a2-860a1b7e627f?autoplay=false&loop=false&muted=false&preload=false&responsive=true" loading="lazy" style="border:0;position:absolute;top:0;height:100%;width:100%;" allow="accelerometer;gyroscope;autoplay;encrypted-media;picture-in-picture;" allowfullscreen="true"></iframe></div>