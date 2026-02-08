+++
title = "Teaching a Robot to Grasp from Pixels in MuJoCo"
slug = "image-rl-grasp"
date = 2026-01-12
draft = false
[extra]
thumb = "https://ggando.b-cdn.net/so101_image-rl_lift_640.jpg"
[taxonomies]
categories = ["blog"]
tags = ["rl", "robotics", "mujoco", "so101"]
+++

<img src="https://ggando.b-cdn.net/so101_image-rl_lift_1280.jpg" alt="img0" width="640" style="display: block; margin: auto;"/>

## Context
After achieving 100% success on state-based RL for my SO-101 robot arm's grasp-and-lift task, I wanted to move to image-based RL. My IRL SO-101 setup has a wrist camera on a custom mount and I want to do sim2real. State-based RL relies on privileged information: exact cube position that doesn't exist on a real robot. Image-based RL learns directly from camera pixels which makes the policy transferable to real hardware.

## The Setup
#### Stack
- Algorithm: DrQ-v2 (Data-regularized Q-learning with random shift augmentation)
- Framework: RoboBase (fork with custom SB3-style logging)
- Simulation: MuJoCo with wrist-mounted camera
- Hardware: AMD RX 7900 XTX, training at ~20 it/s

#### Task
The agent needs to:
1. Observe the scene through an 84×84 wrist camera
2. Grasp a 3cm cube with a two-finger gripper
3. Lift it to 8cm height
4. Hold for 150 steps (~3 seconds)

## 1. Initial Attempts
#### The Initial Run
I started with the v11 reward that worked well for state-based RL:
```python
# v11 reward structure
reward = reach_reward + grasp_bonus + lift_rewards + success_bonus
```
The components:
- Reach reward: 1.0 - tanh(10 * distance) — guides gripper toward cube
- Grasp bonus: +0.25 when both fingers contact cube
- Binary lift bonus: +1.0 when cube_z > 0.02
- Continuous lift: proportional to height progress
- Success bonus: +10.0 for completing the task

#### Results: 0% Success at 2M Steps
| Steps | Eval Reward | Success Rate |
|-------|-------------|--------------|
| 400k  | ~320        | 0%           |
| 1M    | 301 ± 76    | 0%           |
| 2M    | 326 ± 15    | 0%           |

The agent got around 326 ± 15 rewards after 2M steps, and when I checked the video I just saw the agent:
1. Nudges cube with the static finger toward the arm base
2. Supports cube against static finger at the arm base
3. Never attempts a proper two-finger grasp

But at this point, I realized that the wrist camera view was mounted backwards in simulation, and decided to correct this first:
```xml
<!-- v1 camera: WRONG - Camera on back side, facing arm base! -->
<camera name="wrist_cam" pos="0.0 0.055 0.02" euler="0 0 0" fovy="75"/>
```
The Y position +0.055 placed the camera on the back side of the gripper, so I just flipped the Y position and added 180° rotation:
```xml
<!-- v2 camera: Correct - Camera on front side, facing cube -->
<camera name="wrist_cam" pos="0.0 -0.055 0.02" euler="0 0 3.14159" fovy="75"/>
```

After the fix, I trained again with the same v11 reward:
| Steps  | Eval Reward | Success Rate |
|--------|-------------|--------------|
| 160k   | 209         | 0%           |
| 480k   | 314         | 0%           |
| 960k   | 316         | 0%           |
| 1.92M  | 322         | 0%           |

Still stuck at the same 320-ish reward.

#### A New Exploit
This time, a different exploit emerged around 1.76M steps:
1. Press cube edge with static finger
2. Tilt cube at 45° angle
3. Cube center rises from z=0.015 to z=0.021

This triggered the binary lift bonus (+1.0 for cube_z > 0.02) without actually grasping. The cube resting height is ~0.015m, so tilting it was enough to cross the threshold.

Exploit reward: ~1.9/step (reach + binary lift)
Proper grasp reward: ~2.33/step

The 0.43/step difference wasn't enough incentive to learn the harder two-finger grasp.

## 2. v13 Breakthrough
#### The Fix
The tilt exploit revealed the issue where the agent was receiving lift rewards without actually grasping the cube. I'm still new to RL, so it's interesting to see how it learned to support the cube diagonally though.

Since I was already tracking the grasp status by a flag `is_grasping`, I just gated the lift bonus with this flag:
```python
# v11 (exploitable):
if cube_z > 0.02:
    reward += 1.0  # Tilt exploit gets this for free

# v13 (fixed):
if is_grasping:
    if cube_z > 0.02:
        reward += 1.0  # Only with proper two-finger grasp
```

I called it the v13 reward. After the fix, training with v13 reward on the same v2 camera (simple flip, no angle tweaks):
```
800k steps | 3:08:40 elapsed
ep_rew_mean: 650.17
success_rate: 0.10 (10%)
New best model saved!
```
For the first time, the agent was actually grasping the cube with both fingers and lifting it. The video showed proper two-finger contact, closing, and lifting behavior. Just fixing the camera direction and gating the lift bonus on grasping was enough!

#### Shaking Behavior
However, I noticed that the agent peaked at 800k and then regressed:
| Steps | Reward  | Success Rate |
|-------|---------|--------------|
| 800k  | 650.17  | 10%          |
| 1M    | ~400    | ~5%          |
| 1.5M  | ~350    | 0%           |
| 2M    | ~315    | 0%           |

Fortunately, I had implemented best-model saving that captured the 800k checkpoint automatically. Evaluating the saved best checkpoint:
- Mean Reward: 632.27 ± 43.00
- Success Rate: 0%

The agent was grasping and lifting, but not succeeding. I set the success condition of this task to be lifting at z > 8cm for more than 10 steps. I watched the evaluation videos, and I saw it shaking after lifting. The agent lifted to ~4-5cm, then oscillated instead of continuing to 8cm. Possible reward hacking or policy instability at elevated positions.

### Camera Calibration
The shaking issue was still not fixed, but I noticed that the camera view was still very different from my IRL wrist cam, so I wanted to calibrate it again to be closer to the real innoMaker camera specs. Changes:
| Parameter   | v2 (simple flip) | v3 (calibrated) |
|-------------|------------------|-----------------|
| Position X  | 0.0              | 0.02            |
| Position Y  | -0.055           | -0.08           |
| Position Z  | 0.02             | -0.06           |
| Pitch       | 0°               | +40°            |
| FOV         | 75°              | 103°            |

It took some time since this process is manual and Claude is usually bad at spatial understanding. Always trust your own eyes. I ended up adjusting the camera again, but after this adjustment it improved in the sense that I no longer saw the gripper body in the view.

## 3. Single-Finger Behavior Problem
I had to go through a series of failed attempts to get the agent to actually grasp the cube with image-based setup. I'm documenting these here for the record, but if you're interested in the reward function that succeeded, skip to section 4.

#### v14 Reward: Single-Finger Behavior Returns
I defined a minor action penalty timing change to the v13 reward to fix the shaking behavior as the v14 reward and trained it with the new v3 camera. Interestingly, it showed the agent just nudging the cube with the static finger at 1.12M steps. I thought this was just a bug in the action penalty I just added, so I went through a systematic iteration process to fix this. I trained it with v15 and v16 rewards:

#### v15: Gripper-Open Penalty
The agent was stuck in a local optimum, positioning near the cube but keeping the gripper wide open. My hypothesis: penalize keeping the gripper open too long.
```python
# v15: Penalty for keeping gripper open after grace period
grace_period = 40  # ~20 agent decisions
if gripper_state > 0.3 for grace_period steps:
    penalty = min(0.05 * excess_steps / 50, 0.3)  # Caps at 0.3
    reward -= penalty
```
Result: The agent learned to briefly close/open the gripper every ~39 steps to game the penalty (cheating). Still no grasping.

#### v16: Increased Grasp Bonus (Devlog 046)
The grasp bonus (+0.25) was too weak compared to reach reward (~0.9). I increased it 6x:
| Behavior          | v14/v15 | v16  |
|-------------------|---------|------|
| Hovering near cube| ~0.9    | ~0.9 |
| Grasping          | ~1.15   | ~2.4 |

Result: Still failed. The agent never discovered the grasp bonus, probably because discovering it via random exploration is hard. At this point I realized that I was just lucky with the v13 reward.

#### Camera v4 Recalibration
While debugging the single-finger behavior, I discovered the v3 camera was still different from the real camera:
- Pitch sign was wrong: +40° instead of -25° (tilted backward, showing skybox)
- FOV was wrong: Used 103° (horizontal) instead of 86° (vertical, what MuJoCo expects)
```xml
<!-- v3 (wrong): -->
<camera pos="0.02 -0.08 -0.06" euler="0.698 0 3.14159" fovy="103"/>

<!-- v4 (correct): -->
<camera pos="0.02 -0.08 -0.02" euler="-0.436 0 3.14159" fovy="86"/>
```

#### Bootstrap Attempt
I was still struggling to make it grasp the cube, so I had Claude research online to search for good methods to fix this and found bootstrapping (QT-Opt's approach), where you seed the replay buffer with scripted grasp demonstrations. So I did:
1. Created scripted policy (~80% success rate)
2. Collected 1000 trajectories
3. Seeded replay buffer with ~60k successful grasp transitions
4. Trained with v13 reward

Result at 600k steps: Same single-finger, open-gripper behavior. The agent ignored the demonstrations entirely.

Why bootstrap failed: I'm still not sure, but QT-Opt used sparse rewards (+1 success only). Our dense reach reward (~0.9/step) might create a local optimum that bootstrap seeding can't escape. The agent can achieve high reward by hovering without ever sampling from the successful grasp demonstrations.

## 4. v17 Breakthrough
#### The Core Problem
After all these failures, I finally identified the root cause: the SO-101's gripper is asymmetric and it breaks standard reward assumptions.

Standard reach reward: 1 - tanh(10 * gripper_to_cube)

This works for symmetric parallel-jaw grippers where both fingers move equally toward the object. But SO-101 has:
- A static finger fixed to the gripper frame (same position as TCP)
- A moving finger that opens/closes: this one can be pretty far away from the cube when fully opened

When you measure "gripper-to-cube distance," you're measuring the static finger position. The moving finger gets no gradient! The agent can maximize reach reward by positioning the static finger close to the cube while keeping the gripper wide open.

#### v17: Per-Finger Reach Reward
The solution: give the moving finger its own reach reward that caps when the gripper closes.
```python
# v17: Moving finger reach with proximity gate
gripper_reach = 1.0 - tanh(10.0 * gripper_to_cube)  # Static finger

if gripper_reach < 0.7:  # Far from cube
    reach_reward = gripper_reach  # Standard only
else:  # Close to cube
    if gripper_state < 0.25:  # Closed
        moving_reach = 1.0  # Capped
    else:
        moving_reach = 1.0 - tanh(10.0 * moving_finger_to_cube)

    reach_reward = (gripper_reach + moving_reach) * 0.5
```
Key insight: When near the cube (`gripper_reach >= 0.7`), the agent gets ~0.4 more reward per step for closing the gripper. This gives explicit gradient toward closing that was missing in v11-v16.

#### v17 Results: Breakthrough
| Steps | Grasping % | Success Rate |
|-------|------------|--------------|
| 200k  | 89-97%     | 0%           |
| 2M    | 97.5%      | 10%          |

For the first time since the camera recalibration, the agent was actually grasping. At 200k steps, 5/10 evaluation episodes already showed >89% grasping throughout the episode.

By 2M steps:
- 9/10 episodes: 97.5% grasping
- Episode 6: Lifted to 0.15m and held (success!)
- Remaining episodes: Grasped but plateaued at 0.03-0.06m lift

#### v19: 100% Success Rate
v17 solved grasping but most episodes plateaued at z=0.03-0.04m. The problem: weak lift gradient.

At z=0.04m with v17, pushing 1cm higher only gave +0.31 reward. Meanwhile, dropping the cube costs ~227 reward (drop penalty + lost grasp bonus for remaining steps). The agent learned to play it safe.

v18 changes:
- Doubled lift coefficient: 2.0 → 4.0
- Added linear ramp from 0.04m to 0.08m (+0.5/cm bonus)

| Height | v17 | v18 |
|--------|-----|-----|
| 0.04m  | 4.2 | 5.0 |
| 0.06m  | 4.9 | 6.8 |
| 0.08m  | 6.0 | 9.0 |

Result at 2M steps: Agent now lifts to 0.06-0.10m (vs 0.03-0.04m), but success rate dropped to 0%. The agent oscillates above/below the 0.08m threshold, never holding long enough.

Success requires 10 consecutive steps above 0.08m. v18's agent would go up, dip down, go up again - resetting the counter each time. Episode 7 had 63 total steps above 0.08m but they weren't consecutive.

v19 adds escalating reward for holding at target height:
```python
if cube_z > 0.08:
    reward += 1.0  # existing target bonus
    reward += 0.5 * hold_count  # 0.5, 1.0, 1.5, ... up to 5.0
```
At step 9 of holding, dipping would forfeit the +4.5 bonus AND reset progress. This creates strong incentive to stabilize.

Result: 100% success rate at 2M steps. Every episode completes in ~20 steps (vs 200 step timeouts before).
| Version | Success Rate | Typical Height | Episode Length     |
|---------|--------------|----------------|--------------------|
| v17     | 10%          | 0.03-0.04m     | 200 (timeout)      |
| v18     | 0%           | 0.06-0.10m     | 200 (timeout)      |
| v19     | 100%         | 0.10-0.12m     | 19-22 steps        |

## 5. The Cube Position Leak Bug
So after achieving 100% success rate, obviously I tried deploying to my real SO-101, but it failed completely and the gripper moved vaguely toward the cube area. Debugging the checkpoint, I realized that the cube position in the simulator was leaked to the input state: the DrQ-v2 concatenates the image with robot joint positions (because they're known even when using image as input)
```python
# BUG: passes all 21 dims including cube_pos
return {"rgb": img, "low_dim_state": obs.astype(np.float32)}
```
The agent had been cheating. This is a very basic bug and I should have checked this way earlier.

But the good news is that it still achieved 100% success rate at 800k steps after retraining. I was watching the rollout rewards during that and the reward progression pattern looked identical to before (needs to double check though). It seems that the cube position was redundant and the agent mostly relied on the input images despite this privileged leak. Here's the eval video after the retraining:

<div style="position:relative;padding-top:56.25%;"><iframe src="https://iframe.mediadelivery.net/embed/399279/582c11d1-3c77-4cd5-aed6-a9994b546c42?autoplay=false&loop=false&muted=false&preload=false&responsive=true" loading="lazy" style="border:0;position:absolute;top:0;height:100%;width:100%;" allow="accelerometer;gyroscope;autoplay;encrypted-media;picture-in-picture;" allowfullscreen="true"></iframe></div>

## 6. Next Steps
I'd like to make it work on my real SO-101 to perform a pick-and-lift task but I need to bridge the domain gap somehow. I was thinking of doing HIL-SERL to fine-tune it IRL initially, but then I found this repo demonstrating zero-shot sim2real pick-and-lift. Their approach is to make the simulation environment much closer to the IRL setup and perform heavy domain randomization. I'm lazy so if I can avoid doing manual robot manipulation at all I prefer that. Since the framework they use (ManiSkills) doesn't support GPU physics calculation on AMD GPUs, I'm planning on porting the code to Genesis and trying to train a robust agent that can perform decently on real inference.

<br />
<br />
<br />