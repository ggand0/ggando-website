+++
title = "Training an SO-101 RL Agent to Grasp and Lift in MuJoCo"
slug = "so101-rl-lift"
date = 2026-01-02
draft = false

[extra]
thumb = "https://ggando.b-cdn.net/so101_lift_640.jpg"

[taxonomies]
categories = ["blog"]
tags = ["rl", "mujoco", "robotics", "python"]
+++

<img src="https://ggando.b-cdn.net/so101_lift_852.jpg" alt="img0" width="640" style="display: block; margin: auto;"/>

### Context
When I attended a robotics meetup in SF this summer, I realized that the era of robotics is on the rise, and now is a good time to start building robots. I've been working on imitation learning for my SO-101 robot arm setup, successfully training two ACT policies via LeRobot: green cube → white paper, and red cube → green bowl. Both worked… sometimes. Maybe 50% success rate on a good day.

This is the same problem as supervised deep learning, where every improvement requires more data in the form of manual demonstrations. I obviously need more demos to go from 50% to 80% success; it could improve with 50+ more episodes. But I'd need to keep collecting data every time I change the situation or object. Big corporations like Google and OpenAI have teams collecting millions of demonstrations, and I'm seeing the same situation happening in Tokyo. As a solo developer, I can't really compete with IL-based methods.

So I decided to go the RL route. Ideally, I train a good model in simulation first and then fine-tune with HIL-SERL without much human intervention. Would the fine-tuning really bridge the sim2real gap? I don't know yet. But I'll give it a shot. I do believe that RL is the future over the long run.

### Initial Setup
I set up a MuJoCo simulation with the SO-101 arm, a 3cm cube, and a goal position on the ground for a pick-and-place task. I used SAC from Stable-Baselines3, following my recent experience training agents for a Bevy 3D dodge game where SAC outperformed PPO on continuous control.

My first attempt with naive reward shaping resulted in the arm pushing the cube toward the goal after 500k steps. I did a bit of research on the best practices for letting the agent actually grasp the target and found the robosuite repo (link) that has staged rewards such as giving rewards for grasping the object.

I adopted this and trained a few setups with reach reward + grasp bonus + lift bonus + place reward, and also implemented an IK-based controller instead of the default velocity-based one. However, it learned to keep holding the cube on the ground without actually lifting, even after 1M steps. I added debug logging for the cube's position and it turns out that it was pushing the cube down (z coordinate was going negative). I also visualized the scene from different angles, and realized that the gripper's fingers were clipping into the cube. I tried fixing this by adding collision boxes to the fingers, but the cube's size was too big and prevented the gripper from grasping anything, so I removed them at that point.

I tried tweaking reward weights, adding penalties, and different reward structures, but nothing worked and I decided to try training a simpler lifting task, starting from the state where the arm already grasps the cube. In order to do this, I needed to implement a reset motion with inverse kinematics to grasp the cube at the beginning of each episode.

### The IK Struggle
The SO-101 has 5 arm joints plus a gripper. To do top-down grasping, I needed the gripper pointing down with fingers horizontal, then move to an XYZ target. I implemented a damped least-squares IK controller using MuJoCo's Jacobian.

Then, I attempted to grasp the cube with the IK controller for environment reset, but it wasn't working at all; it took a fair amount of time to debug this. I added visualization spheres at grasp points and realized there were two issues.

The first problem was that I mixed up `graspframe` and `gripperframe`. The MJCF model had two sites:
1. `gripperframe` at the fingertips (the TCP)
2. `graspframe` further back between the fingers

I was targeting the wrong one, wondering why the gripper kept overshooting the cube. It took time to realize this because I was letting Claude Opus 4.5 debug this at first, but it's sometimes bad at debugging visual issues like this because it only sees coordinates and grasp state in the console log. I highly recommend visualizing the grasp point and seeing it for yourself if you encounter similar issues.

The second problem: even after fixing that, the gripper kept hitting the cube with the static finger before properly centering on it. The SO-101's gripper isn't symmetric: one finger is fixed, one moves. I needed to offset the target position to account for this asymmetry.

The third problem: the motion worked but looked janky. I found this excellent [ECE4560 course material](https://maegantucker.com/ECE4560/assignment8-so101/) that had a clean 4-step pick sequence for the SO-101. I adapted their logic: move above block → descend → close gripper → lift. Now the motion was much cleaner. The cube still wobbled, though.

### The Wobbling Cube
The IK motion was fixed, but there was another big issue where the cube kept wobbling all the time. I was using the default material settings (friction, etc.) similar to rubber in real life, but my goal is to transfer this RL agent to my real SO-101. So I changed the cube material to the wood equivalent, but then it slipped away from the fingers when I tried to grasp it with the IK controller.

I initially thought it was a friction problem and tried wooden cube parameters, cranked up friction coefficients, enabled elliptic friction cones, and added noslip iterations. This helped a bit with slipping, but the wobble persisted.

After more research, I found [MuJoCo issue #239](https://github.com/google-deepmind/mujoco/issues/239) where someone had the exact same problem with a Franka Panda gripper. The solution from a MuJoCo collaborator:

> If it is the actual mesh I would strongly recommend to disable the collisions for the mesh and add a layer of (possibly invisible) box primitives that overlap with the end effector.

The problem: mesh-to-mesh collisions generate unstable single contact points. The solution: add small box geoms at the fingertips for stable multi-point contact. This was the same approach as the one I tried earlier, so I made the boxes pretty small and carefully adjusted the positions to only protrude slightly inward from the fingers.

I added two 2.5mm box geoms (`static_finger_pad` and `moving_finger_pad`) positioned to protrude slightly inward from the finger meshes:

```xml
<!-- Static finger collision pad -->
<geom name="static_finger_pad" type="box" size="0.00125 0.00125 0.00125"
      pos="-0.008875 0.0 -0.100" rgba="1 0.5 0.5 0.8" friction="1 0.05 0.001"/>

<!-- Moving finger collision pad -->
<geom name="moving_finger_pad" type="box" size="0.00125 0.00125 0.00125"
      pos="-0.01136 -0.076 0.019" rgba="0.5 0.5 1 0.8" friction="1 0.05 0.001"/>
```

After this fix, the wobbling stopped! The cube now gripped cleanly and held steady during lifting.

### Training the Lift Agent
With the physics working, I returned to RL training. First, I trained an agent that just lifts the cube, starting from the state where the cube was already grasped and lifted at z=0.02.

The reward structure looked like this. I call it the V11 reward since I've been versioning different reward functions.

| Component | Condition | Value |
|-----------|-----------|-------|
| Reach | Always | `1.0 - tanh(10 * distance)` |
| Push-down penalty | cube_z < 0.01 | `-(0.01 - z) * 50` |
| Drop penalty | Lost grasp | `-2.0` |
| Grasp bonus | Grasping | `+0.25` |
| Continuous lift | Grasping | `lift_progress * 2.0` |
| Binary lift | cube_z > 0.02 | `+1.0` |
| Target bonus | z > 0.08 | `+1.0` |
| Action penalty | z > 0.06 | `-0.01 * ‖action_delta‖²` |
| Success | Held at target | `+10.0` |

I first trained it without the action penalty. It learned to lift the cube, but had this issue where the agent lifted the cube close to z=0.08 but oscillated rapidly, like twitching. The reward difference between 0.07m and 0.08m is too small (~0.31). The policy learned to oscillate around ~0.07m rather than hold at 0.08m. So I added an action rate penalty `-0.01 * ||a_t - a_{t-1}||²` for smooth movement.

The penalty only applies when z > 0.06, because the agent learned to hold still at z=0.054m when I applied it all the time. Also, I needed to reduce the penalty coefficient from 0.05 to 0.01, as it learned to hold still rather than lift because any action change incurred a penalty.

After introducing it, the agent achieved a 100% success rate after 500k steps of training. Then, I tried curriculum learning, starting with the cube already grasped and mid-air, but the pretrained weights didn't transfer well and it kept moving away from the cube erratically. I fixed a bug with VecNormalize stats, but the transfer still failed.

So I trained from scratch with V11 on the full task: 200k steps, ~4 hours on my AMD GPU with ROCm. Final result: 100% success rate on evaluation. The agent grasps the cube and lifts it above z=0.08 every time.

One interesting emergent behavior: the agent learned to nudge the cube slightly before grasping. I never explicitly rewarded this, but it just emerged from the training dynamics. The nudge seems to adjust the cube into a better orientation for the top-down grasp, and I like it!

<div style="position:relative;padding-top:56.25%;"><iframe src="https://iframe.mediadelivery.net/embed/399279/2e506b66-3f52-4f24-a811-36dadbee6b02?autoplay=false&loop=false&muted=false&preload=false&responsive=true" loading="lazy" style="border:0;position:absolute;top:0;height:100%;width:100%;" allow="accelerometer;gyroscope;autoplay;encrypted-media;picture-in-picture;" allowfullscreen="true"></iframe></div>

### Takeaways
- **Mesh collisions in MuJoCo can be unstable for grasping**: add box primitives at contact points for stable multi-point contact
- **Visualization is essential**: debug spheres showing target vs actual positions saved me hours of print-statement debugging
- **Cartesian action space >> joint space for manipulation RL**: random exploration naturally covers the 3D workspace
- **Reward hacking is inevitable**: budget time for reward iteration (I went through 11 versions)
- **Conditional penalties** can prevent reward hacking without killing task completion

Next up: pixel-based RL with camera observations, transitioning from Stable-Baselines3 to vision-RL frameworks like DrQ-v2. The ultimate goal is a pick-and-place agent that can actually clean up a desk.

The code is available at [github.com/ggand0/explore-mujoco](https://github.com/ggand0/explore-mujoco). If you're working on SO-101 RL in MuJoCo, feel free to reach out. There's not much published work on this specific setup.