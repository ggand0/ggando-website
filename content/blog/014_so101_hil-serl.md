+++
title = "HIL-SERL for SO-101: Real-World Grasping from Scratch"
slug = "so101-hil-serl"
date = 2026-02-08
draft = false

[extra]
thumb = "https://ggando.b-cdn.net/014_thumb_640.jpg"

[taxonomies]
categories = ["blog"]
tags = ["rl", "robotics", "so101", "hil-serl"]
+++

### Background: Why HIL-SERL?
Before this, I'd already achieved 100% success in MuJoCo simulation for grasp-and-lift using state-based SAC, and had a working image-based DrQ-v2 policy that could grasp and lift in sim. However, the RGB sim2real gap was too strong and didn't work at all (just hitting the ground, etc.). I also tried another setup with segmentation + depth that actually tried to grasp the cube, but even that was still unable to grasp in zero-shot setting. So, I realized that RL training in a real environment is necessary and I decided to pivot to HIL-SERL training to explore if it's even possible.

The problem is that nobody seems to have done this on a grasp-related task for SO-101 before. The LeRobot codebase had HIL-SERL support, but it was built and tested around SO-100 and Koch arms. SO-101 is different enough that basically nothing worked out of the box. It took about three weeks to make it work, but I was able to achieve ~70% success rate on a grasp-only task with HIL-SERL from scratch. In this blog, I'd like to document my setup and what worked for this training.

### Hardware Setup
Here's what you need:
Robot Arms
- **SO-101 leader + follower arm pair**
- **Table clamps x 4:** You need these to fix the arm bases to the table. The arm moves with enough force that it will knock itself over without them.
Workspace
- **A dedicated desk:** Strongly recommended. The arm can move randomly during training and will hit anything on the table. I've knocked over cups, sent objects flying, and scratched my desk. Dedicate a workspace you don't care about.
- **Red wooden cube:** Or whatever object you're training on. Start with something easy to see and grasp.
Camera
- **InnoMaker 1080P USB camera x 2:** I recommend buying two of them because my first one died in January after using it for about six months. During RL training, the arm sometimes impacts the table with enough force that it damages the camera over time. My second one arrived tilted to one side (manufacturing defect), so I needed a third one. Budget for camera mortality. Alternatively, just buy a realsense D405 which should be more durable.
- **3D-printed camera mount:** The camera needs to mount to the gripper. You'll need to print this yourself or use a service like JLC3DP. The SO-ARM100 repo has mount STLs.
Lighting
- **Desk lamp:** This turned out to be critical. RGB-based RL is extremely sensitive to lighting conditions. Without a dominant, consistent light source, the reward classifier gets confused by shadows and ambient light changes throughout the day. If your room lighting isn't consistent, buy a desk lamp and point it at the workspace. I used a Yamada Z-LIGHT Z-10R since it was cost-effective in Japan ($100), but I heard from Grok that the BenQ e-reading LED desk lamp on amazon.com is pretty good (~$200)

Optional but Useful
- **External USB camera + clamp stand:** For recording training footage from a third-person view. Useful for debugging and making demo videos.
- **Spare USB cables:** Things break.

<img src="https://ggando.b-cdn.net/014_setup_640.jpg" alt="HIL-SERL hardware setup" width="640" style="display: block; margin: auto;"/>

### Code Setup
The current LeRobot main branch doesn't fully support SO-101 for HIL-SERL. I needed to fork and use it from my repo:
LeRobot fork: My fork with SO-101 HIL-SERL fixes
- GitHub: [ggand0/lerobot](https://github.com/ggand0/lerobot) (branch: hilserl-so101)
- Key changes:
	- **MuJoCo-based IK:** SO101FollowerEndEffector class with damped least-squares IK (replaced URDF+placo path that had a state caching bug causing arm drift)
	- **Gym environment rewrite:** Rewrote upstream's processor/pipeline architecture to gym wrappers (FullProprioceptionWrapper, ImageCropResizeWrapper, leader-follower teleop wrappers)
	- **Full proprioception:** State expansion from 6-dim joints to 18-dim (joints + velocities + EE pose via MuJoCo FK)
	- **Offline buffer conversion:** MuJoCo FK for joint-to-EE action conversion
	- **IK-based reset:** Positioning with configurable locked joints
	- **Human intervention:** Leader arm joint mirroring
	- **DrQ-v2 policy:** Implementation for sim-to-real transfer
	- **Hardware robustness:** Camera auto-reconnect, motor bus retry logic, torque disable on exit

The upstream HIL-SERL code uses URDF-based kinematics via placo for end-effector control. The reason why I used mujoco as a FK solver here was that there was a state caching bug where the IK code cached its own computed targets as the 'current' position instead of re-reading where the motors actually moved to and the internal state drifted further from reality each step. I was working on sim2real RL inference at that time and the inference script was already working, so I rewrote the robot class to use MuJoCo as a pure kinematics solver instead in a similar way. This fix worked but definitely not clean, and I plan to fix it with the original approach next time I have a chance to work on HIL-SERL.

hil-serl-101: Config files and training scripts
- GitHub: [ggand0/hil-serl-so101](https://github.com/ggand0/hil-serl-so101)
- Contains:
	- Environment configs for SO-101
	- Training configs (hyperparameters that worked)
	- Reward classifier training scripts
	- Evaluation scripts

#### Why a Fork?
SO-101 was missing several things the HIL-SERL codebase assumed:
1. **No URDF-based kinematics:** SO-100 has so100_follower_end_effector with URDF support. SO-101 didn't. I implemented MuJoCo-based FK/IK instead.
2. **State dimension mismatch:** The SAC policy expected 18-dim state (6 joint positions + 6 joint velocities + 3 EE position + 3 EE orientation), but SO-101 only provided raw 6-dim joint positions. Added FullProprioceptionWrapper that computes velocities via finite differences and EE pose via MuJoCo FK.
3. **Offline buffer didn't handle action conversion:** Recorded demonstrations had 6-dim joint actions, but the policy expects 4-dim EE delta actions. The upstream buffer had no FK-based conversion path. Added MuJoCo FK to compute EE deltas from consecutive joint states.
4. **IK-based reset:** The upstream reset assumed manual repositioning or simple joint homing. SO-101 with EE control needs IK to move to a specific Cartesian start position.
5. **Hardware reliability:** STS3215 servos over USB had intermittent read/write failures. Added retry logic to the motor bus and camera auto-reconnect on timeout, plus atexit torque disable so the arm doesn't hold position if the script crashes.

### Reward Classifier
HIL-SERL uses a learned reward classifier to detect task success from camera images. This replaces manual labeling during training.

#### Architecture
- Encoder: ResNet10 (frozen, from helper2424/resnet10)
- Spatial embedding: 4x4 spatial features → learned embeddings
- Classifier head: Linear → Dropout → LayerNorm → ReLU → Linear(1)
- Output: Binary (success/failure)

#### Data Collection
The HIL-SERL paper recommends ~200 positive frames, ~1000 negative frames from ~10 teleoperated trajectories, taking about 5 minutes. I collected significantly more data than this to improve robustness.

First, I recorded 23 episodes for the offline dataset with clean trajectories at 8 seconds per episode. Then, I recorded more positive and negative samples simulating how the robot would grasp or fail at 10–20 seconds per episode. For example, grasp frames with different gripper angles (positive) and scenes of different backgrounds without the cube (negative).
I recorded episodes with terminate_on_success: false to capture both successful grasp frames and the approach/failure frames in the same trajectories. Then I labeled frame ranges in each episode (frames >= cutoff are success, frames < cutoff are failure).

#### Dataset Stats

<div style="overflow-x:auto;"><table style="table-layout:fixed;width:100%;">
<thead><tr><th>Metric</th><th>V5 Lamp Total</th></tr></thead>
<tbody>
<tr><td>Episodes</td><td>42</td></tr>
<tr><td>Frames</td><td>4,731</td></tr>
<tr><td>Success</td><td>1,034 (21.9%)</td></tr>
<tr><td>Failure</td><td>3,697 (78.1%)</td></tr>
</tbody></table></div>
Since I didn't have many frames, I split the data into train/val with 0.15 val ratio rather than train/val/test. Note that I used frame-based split not episode-based. After training it for 43 epochs (2,666 steps), it achieved the best val accuracy of 97.3%. 
I also implemented an inference script using the live camera feed and confirmed that the trained model works fine.

### Training HIL-SERL
#### Architecture
HIL-SERL uses an actor-learner architecture:
```
┌─────────────────┐     gRPC      ┌─────────────────┐
│     Actor       │◄────────────►│     Learner     │
│  (Real Robot)   │   weights    │     (GPU)       │
│    10 Hz        │   data       │    SAC + UTD    │
└────────┬────────┘              └────────┬────────┘
         │                                │
         ▼                                ▼
┌─────────────────┐              ┌─────────────────┐
│  Leader Arm     │              │ Reward          │
│  (Human)        │              │ Classifier      │
└─────────────────┘              └─────────────────┘
```
- Actor: Controls the real robot, runs policy at 10 Hz, sends transitions to learner
- Learner: Trains SAC on GPU with high UTD (update-to-data) ratio
- Leader arm: Human can grab the leader to intervene and guide the robot
- Reward classifier: Predicts success from camera images in real-time

#### Hyperparameters That Worked
I mostly used the same values from the original paper instead of LeRobot defaults. Initially I was using wrong utd_ratio, temperature_init, and target_entropy and it didn't work — these are pretty important for determining how the agent explores during training.
<div style="overflow-x:auto;"><table style="table-layout:fixed;width:100%;">
<thead><tr><th>Parameter</th><th>Value</th></tr></thead>
<tbody>
<tr><td>batch_size</td><td>256</td></tr>
<tr><td>utd_ratio</td><td>20</td></tr>
<tr><td>discount</td><td>0.97</td></tr>
<tr><td>actor_lr</td><td>0.0003</td></tr>
<tr><td>critic_lr</td><td>0.0003</td></tr>
<tr><td>temperature_init</td><td>0.01</td></tr>
<tr><td>target_entropy</td><td>-2.0</td></tr>
<tr><td>num_critics</td><td>2</td></tr>
<tr><td>critic_target_update_weight</td><td>0.005</td></tr>
<tr><td>latent_dim</td><td>256</td></tr>
<tr><td>hidden_dims</td><td>[256, 256]</td></tr>
<tr><td>vision_encoder</td><td>helper2424/resnet10 (frozen)</td></tr>
<tr><td>image_encoder_hidden_dim</td><td>32</td></tr>
<tr><td>action_scale</td><td>0.02</td></tr>
<tr><td>fps</td><td>10</td></tr>
<tr><td>control_time_s</td><td>10.0</td></tr>
</tbody></table></div>

#### Environment Config
```json
{
  "ik_reset_ee_pos": [0.25, 0.0, 0.07],
  "random_ee_range_xy": 0.01,
  "random_ee_range_z": 0.01,
  "reset_delay_s": 3.0
}
```
Critical: Match reset height / position to your demonstration data. I wasted hours debugging because my reset height was z=0.03 but my demos were recorded at z=0.07. The policy was starting from states it had never seen.

#### Human Intervention Protocol
From the HIL-SERL paper:
> "This intervention is crucial in scenarios where the policy leads the robot to an unrecoverable or undesirable state, or when it becomes stuck in a local optimum that would otherwise require a significant amount of time to overcome without human assistance."
The paper shows that without interventions, even with 10x more demonstrations (200 vs 20), the policy fails on complex tasks like dashboard assembly (0% success). So interventions are essential.

#### Avoid Long Sparse Interventions
Direct quote from the paper:
> "the policy improves faster when the human operator issues specific corrections while letting the robot explore on its own otherwise."

> "we should avoid persistently providing long sparse interventions that lead to task successes. Such an intervention strategy will cause the overestimation of the value function, particularly in the early stages of the training process; which can result in unstable training dynamics."
At first, I was making a critical mistake of intervening all the way to a success, but doing this every time seems to weaken the policy's ability to learn autonomous success and recovery. The Q-function would learn that "human intervention = guaranteed success" and overestimates values for states where the human typically takes over. This destabilizes learning. Instead, we need to intervene frequently with short corrections. Many small nudges > few complete takeovers. For example you could bring the arm near cube when it started drifting away from it.

#### The Training Experience
It's exhausting. The paper makes this sound straightforward, but you're standing at the robot for hours, watching it attempt grasps, intervening when it fails, repositioning the cube between episodes. You can't walk away because the policy might do something that needs correction.
I did ~3 hours of active babysitting across multiple sessions. The paper says 1–2.5 hours for Franka tasks, but those are ~$40k industrial arms with Berkeley's robotics lab behind them. For a first-time SO-101 setup with all the debugging, expect longer.

### Results

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Sim2real with RGB didn&#39;t work, so I trained a grasp-only model from scratch using HIL-SERL on the real SO-101. It took ~750 episodes and 3 hours, but wow manual training is so exhausting <a href="https://t.co/rl3KJwDGSy">pic.twitter.com/rl3KJwDGSy</a></p>&mdash; Gota (@gtgando) <a href="https://twitter.com/gtgando/status/2019696686084571535?ref_src=twsrc%5Etfw">February 6, 2026</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>


#### Training Stats

<div style="overflow-x:auto;"><table style="table-layout:fixed;width:100%;">
<thead><tr><th>Metric</th><th>Value</th></tr></thead>
<tbody>
<tr><td>Total episodes</td><td>757</td></tr>
<tr><td>Total steps</td><td>~48,300</td></tr>
<tr><td>Optimization steps</td><td>9,500</td></tr>
<tr><td>Final intervention rate</td><td>5.9%</td></tr>
<tr><td>Episodes with 0% intervention (last 100)</td><td>61/100</td></tr>
</tbody></table></div>
The intervention rate dropped significantly after ~400 episodes. By the end, the policy was mostly autonomous.

#### Evaluation
20 evaluation episodes with cube in varying positions:

<div style="overflow-x:auto;"><table style="table-layout:fixed;width:100%;">
<thead><tr><th>Position Type</th><th>Success Rate</th></tr></thead>
<tbody>
<tr><td>Center (left-biased)</td><td>80% (8/10)</td></tr>
<tr><td>Edges (distributed)</td><td>60% (6/10)</td></tr>
<tr><td>Combined</td><td>70% (14/20)</td></tr>
</tbody></table></div>
The policy is stronger in the center where training data concentrated, weaker at workspace edges. The ±1cm randomization during training limited generalization to boundary positions.


#### Training Analysis

<img src="https://ggando.b-cdn.net/014_training_curves_1280.png" alt="HIL-SERL training curves" width="640" style="display: block; margin: auto;"/>
<p style="text-align:center; color:gray; font-size:0.9em;">Episode reward (top) and intervention rate (bottom) over 757 episodes. Dashed lines indicate session breaks.</p>

757 total episodes across 2 sessions (~3 hours of real-world training).

| Phase | Episodes | Avg Reward | Success% | Avg Intervention% | Max Reward |
|-------|----------|-----------|----------|-------------------|------------|
| Early (1-100) | 100 | 17.6 | 32.0% | 20.8% | 226.2 |
| Mid (101-300) | 200 | 16.3 | 27.0% | 17.8% | 186.3 |
| Late (301-500) | 200 | 59.1 | 69.0% | 22.0% | 219.6 |
| Final (501+) | 257 | 95.5 | 79.4% | 9.2% | 309.0 |

Overall episode rewards increase monotonically. Episode 300 seems to be a breakthrough point where the policy started behaving better. The intervention rate rose around this point because the policy was overfitting to a specific motion that could only grasp cubes on the right side of the camera view, so I started placing cubes more toward the left side and positions where it struggled. Toward the final phase of training (ep 500+), MA20 stabilized around 95-107, indicating convergence.


#### What Worked vs What Didn't
**What worked:**
- Consistent desk lamp lighting
- Reset height matching demonstration data (z=0.07)
- Small position randomization (±1cm)
- High UTD ratio (20)
- Patient early intervention

**What didn't:**
- Training without consistent lighting (classifier failed)
- Wrong reset height (z=0.03 vs demo z=0.07)
- Large randomization (policy couldn't generalize)
- Rushing through early training (not enough intervention data)

### Things to make HIL-SERL work
Here's the TL;DR of critical points I think are very important to train HIL-SERL successfully:
1. **Lighting:** I believe this is very important for RGB-based RL. Desk lamp for consistent RGB observations
2. **Reward classifier extra samples:** positive/negative for edge cases that occur during training. The agent might reward-hack without covering these.
3. **Human intervention techniques:** Short corrections, not long takeovers; let policy explore early
4. **Hyperparams different from paper:** Especially exploration-related ones like temperature_init
5. **USB reconnection logic:** USB keeps dying and interrupts training without this. Handling servo disconnects mid-training
6. **750 episodes not 500:** keep training if improving, don't stop at arbitrary cutoff. Ideally finish training within the same time segment like morning, afternoon, night etc.
7. **Accurate calibration:** Actually positioning joints in the middle of their range during calibration startup
8. **Classifier preprocessing:** Use 128x128px as in the paper, consistent logic; in my case I center-cropped 480p frame to 480x480px square image then resize to 128x128px while maintaining the aspect ratio
9. **Classifier: frame-based train/val split:** Not episode-based
10. **Same reset pose:** in my case resetting the arm to z=0.07 rather than something else
11. **Small position randomization:** ±1cm works, larger randomization may cause failures and instability

If you're interested, the code is here: [https://github.com/ggand0/hil-serl-so101](https://github.com/ggand0/hil-serl-so101)

### Lessons Learned
#### The Real Cost
**Runtime errors:** I fixed dozens of bugs across the LeRobot codebase before training even worked. Missing imports, path checks, state dimensions, keyboard handling, intervention logic, reset positioning. This took weeks.
**Hardware failures:** Cameras die. Servos drift. Cables break. Budget time and money for replacements.
**Human time:** 3+ hours of active robot babysitting, plus all the setup time. This is not a "run overnight" method.

#### Is HIL-SERL Worth It?
For learning the full sim-to-real RL pipeline: Yes. I understand how these systems work at a level I never would have from just reading papers.
For getting a working grasp policy: Maybe not. ACT trained on 50 demonstrations would probably achieve similar results with less total effort. VLAs like π₀ or OpenVLA might work with even less data.
The 70% success rate is pretty good where the policy discovered its own grasping strategy through exploration and corrections, not just copying demos. But the marginal improvement per hour of human time gets worse as the policy improves. I'm not sure I want to grind another few hundred episodes to push to 80%, let alone attempt a more complex task.

#### What's Next
1. VLAs: Try π₀ or OpenVLA with minimal fine-tuning. These are pretrained on internet-scale robot data and might work faster.
2. RGBD: I just bought a realsense D405 depth camera. Adding depth might reduce the visual domain gap enough for better sim-to-real transfer.
3. Full pick-and-place: The current 70% is grasp-only. Extending to lift-and-place is the actual goal.
