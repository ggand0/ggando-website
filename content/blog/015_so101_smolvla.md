+++
title = "Fine-tuning SmolVLA for Cube Pick-and-Place on SO-101"
slug = "smolvla-so101"
date = 2026-03-01
draft = false

[extra]
thumb = "https://ggando.b-cdn.net/so101_smolvla_640.jpg"

[taxonomies]
categories = ["blog"]
tags = ["robotics", "vla", "so-101", "lerobot"]
+++

<img src="https://ggando.b-cdn.net/so101_smolvla_960.jpg" alt="SO-101 SmolVLA pick-and-place" width="640" style="display: block; margin: auto;"/>

### Context
For the past few months I've been exploring different algorithms for my SO-101 robot arm to do a pick-and-place task. Last time I trained SAC with HIL-SERL (Human-in-the-Loop Sample Efficient RL) on the real robot with a reward classifier and human interventions via the leader arm. After about 750 episodes of training, HIL-SERL achieved 80% success on reach-and-grasp. That's good, but each episode required me to physically be there watching the robot, ready to intervene, and it's very labor-intensive.

So this time I tried out VLAs (Vision-Language-Action models) to see how quickly I could train a working model. I decided to go with SmolVLA from HuggingFace, as it's a compact VLA built on SmolVLM that you can fine-tune on consumer hardware (in my case, RTX 3090). The idea is simple: collect teleoperation demos, fine-tune the pretrained model, and deploy. No reward engineering, no sim-to-real gap, no sitting next to the robot for hours pressing buttons. Here's what I tried out.

### The Setup
Hardware: SO-101 follower + leader arm (Feetech STS3215 servos), Intel RealSense D405 as wrist camera, Logitech C920 as overhead camera, and my RTX 3090 for training. Software: HuggingFace's [LeRobot](https://github.com/huggingface/lerobot) framework with a custom fork that adds placo-based IK for automated resets between episodes.

The task: pick up a small cube from a randomized position and place it in a bowl. 10-second episodes, 30fps, recorded via teleoperation with the leader arm.

### SmolVLA vs ACT
SmolVLA is a 500M+ parameter model, but you only fine-tune ~50M (the action expert + projections). The vision encoder (SigLIP) and language model (SmolLM2) stay frozen. This means the model already has a strong visual prior from pretraining. It knows what objects look like, it just needs to learn what to do with them.

I also trained an ACT baseline for comparison. ACT is a solid architecture but had practical issues on my setup: no built-in image resize meant 640×480 frames produced 602 encoder tokens per forward pass, OOM'd at batch_size=64 on 24GB VRAM, and required double the training steps to match SmolVLA's sample count. At 1.28M matched samples, SmolVLA's L1 loss converged to 0.006 while ACT was at 0.046 (though the losses aren't directly comparable since ACT includes KL divergence).

### Three Rounds of Data Collection
I had to record three times due to hardware breakage and inconsistent grasp motions:

#### v1: 30cm workspace, 50 episodes
First attempt. Cube placed randomly across a ~30cm area, two cameras (wrist + overhead). Training converged (loss dropped from 0.162 to 0.005 in 20k steps), but at inference the arm moved toward the cube and then grasped at air. 50 demos across 30cm just wasn't enough density. The policy learned the general motion but couldn't pin down precise grasp locations.

#### v1 redux: 10cm workspace, 75 episodes
Narrowed the workspace to ~10cm and collected 75 clean episodes. Also swapped the wrist camera from InnoMaker RGB (which kept dying mid-session) to a RealSense D405. This version hit 80% success on the first eval run. The tighter workspace gave the policy enough demonstration density to learn reliable grasping. I should have recorded the demo video and posted it at this point, but I realized that the flexible finger of the gripper was half-broken. I replaced it with a new one, re-calibrated, and obviously the performance significantly dropped since the model was trained with the old calibration. I decided to redo the entire process again.

#### v2: The nudge trick problem
Collected 81 more episodes with a recalibrated arm. During recording I developed a habit of nudging the cube with the gripper's static finger to rotate it into a better angle before grasping. Seemed clever at the time.

The overhead camera also died partway through recording (likely USB power brownout from sharing the bus with the RealSense and servo controllers), so I bought a new one. Training metrics looked identical to v1: same final loss, same convergence. But eval was pretty bad at 20-80% success rate with wild variance across runs. The policy learned a conditional behavior: sometimes nudge, sometimes grasp directly. It couldn't consistently decide which to do.

This was because I got used to the grasp task and started doing the nudging motion: nudge the cube to correct the rotation without having to rotate the wrist roll joint, then grasp. I also included another way to grasp, which is rotating the wrist roll to align the gripper angle and then grasping. This mix unfortunately turned out to be pretty bad for model training.

Lesson learned: consistency in demonstrations matters more than quantity. One clean strategy beats a mix of tricks.

#### v3: Clean demos with wrist roll alignment
Re-recorded everything with a strict protocol. No nudging. Lower the arm above the cube, rotate the wrist roll to match the cube's angle, descend, grasp. Same strategy every time. Also replaced the dead C920 and moved the RealSense to a proper USB 3.0 port (it had been silently running at 480Mbps on a USB 2.0 port, and I found this with `lsusb -t`).

75 clean episodes after removing 5 bad ones.

### Training
All SmolVLA runs used the same hyperparams: batch_size=64, 20k steps, cosine decay from 1e-4, checkpoints every 5k steps. Images get `resize_with_pad` to 512×512. Each run took about 10 hours on the 3090.

The v3 dual-camera run (wrist + overhead) converged to loss 0.005 at 20k steps. Loss was still dropping, so there's room to push further. Gradient norm went from 0.18 → 0.11, stable convergence throughout.

| Step | Loss | Grad Norm | LR |
|------|------|-----------|-----|
| 5k | 0.011 | 0.18 | ~8.5e-5 |
| 10k | 0.010 | 0.19 | 7.6e-5 |
| 15k | 0.007 | 0.13 | ~4.8e-5 |
| 20k | 0.005 | 0.11 | 2.7e-5 |

### Results
The v3 dual-camera model typically achieves 60-80% success across 5-episode eval runs. The arm approaches the cube, aligns its wrist, grasps, lifts, carries to the bowl, and releases. There's some shaking during execution, but this is a common behavior with IL models. I feel the shaking and slightly lower success rate might also be due to the time I performed inference. I recorded the dataset in late afternoon toward 5pm in late February, but during the time of evaluation it was around 12pm, which can slightly affect the lighting condition even though I have the dominant lighting (desktop lamp).

Failure modes are mostly spatial: occasional off-center grasps where the cube slips, or slight misjudgment of the bowl position on placement. The policy clearly understands the task structure and it's not randomly flailing.

Here's a demo video showing a successful run. One of the episodes had a funny moment where the robot fumbled the cube and then recovered, which was very rare.

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">Yet another VLA inference vid, but I fine-tuned SmolVLA on 75 demos for 20k steps on my RTX 3090. ~10.4 hours of training, usually 60-80% success rate. Way less painful than HIL-SERL from scratch, but now the performance is capped by human demos. Can you fine-tune VLAs with RL? <a href="https://t.co/qBkHjONibx">pic.twitter.com/qBkHjONibx</a></p>&mdash; Gota (@gtgando) <a href="https://twitter.com/gtgando/status/2025427031102722300?ref_src=twsrc%5Etfw">February 22, 2026</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

### Comparison: SmolVLA (dual) vs wrist-only vs ACT
I trained all three variants on the same v3 dataset (75 episodes) for 20k steps each:

| Model | Cameras | Final Loss | Grad Norm | Train Time | Params |
|---|---|---|---|---|---|
| SmolVLA (dual) | wrist + overhead | 0.005 | 0.11 | ~10.4h | ~1.7B |
| SmolVLA (wrist) | wrist only | 0.006 | 0.11 | ~10h | ~1.7B |
| ACT (dual) | wrist + overhead | 0.052 | 3.92 | ~10.5h | 52M |

Loss values aren't directly comparable across architectures (different loss formulations). SmolVLA converges to ~10x lower loss and ~35x lower gradient norms, which is expected given the pretrained VLM backbone vs ACT training from scratch with only ResNet18 features.

On the real robot though, the difference is clearer:

| Model | Cameras | Success Rate |
|---|---|---|
| SmolVLA (dual) | wrist + overhead | **100% (5/5)** |
| SmolVLA (wrist) | wrist only | 80% (4/5) |
| ACT (dual) | wrist + overhead | 80% (4/5) |

SmolVLA dual-cam remains the best at 100%. For this run, I recorded at night, but somehow the performance is more stable compared to the runs I did in the afternoon (mentioned in the Results section).

Dropping the overhead camera or switching to ACT both degrade to 80%. The overhead camera clearly helps SmolVLA. I also felt that the motions are much smoother with the dual-cam model, as if it has more confidence.

ACT matching SmolVLA wrist-only at 80% is notable given it's 52M params trained from scratch vs ~1.7B fine-tuned. For the v3 ACT run I also added an aspect-ratio-preserving resize to 224×224 (which the earlier v1 ACT run was missing), so it could finally run at batch_size=64 without OOM.

<div style="position:relative;padding-top:56.25%;"><iframe src="https://iframe.mediadelivery.net/embed/399279/fde3ee16-e018-4c24-9f4d-79571d87da16?autoplay=false&loop=false&muted=false&preload=false&responsive=true" loading="lazy" style="border:0;position:absolute;top:0;height:100%;width:100%;" allow="accelerometer;gyroscope;autoplay;encrypted-media;picture-in-picture;" allowfullscreen="true"></iframe></div>

### Prompt robustness
So this is a VLA, which runs based on the input prompt. For this training I used the same task prompt: `"Pick up the cube and place it in the bowl"`. Technically it should pick up the cube regardless of its color, for example, and this is kind of the point of using VLAs instead of other IL models: it should generalize based on prompts. I ran a quick color generalization test with the SmolVLA dual-cam model, since it was trained exclusively on a red cube.

| Color | Result |
|---|---|
| Orange | Succeeded but hit the bowl on the way back (rare with the red cube) |
| Blue | Grasped but dropped on the way to the bowl |
| Green | Grasped and moved toward the bowl but hit it with the gripper, failed |

1/3 success vs 5/5 with the training color. Grasping generalizes across colors reasonably well. It did pick up all three, but the place trajectory degrades. The model seems to have learned color-specific visual features for the red cube rather than a general "cube" concept. The placing phase is somehow more sensitive.

I didn't change the prompt to specify the cube color, so this is purely testing whether the vision backbone generalizes. It partially does for grasping but not for the full task. I'd probably need to add cube color variations in the dataset if I wanted to be robust w.r.t. visual appearance of the cube.

<div style="position:relative;padding-top:56.25%;"><iframe src="https://iframe.mediadelivery.net/embed/399279/4fbb873f-479b-4237-9efd-60506b04eb7c?autoplay=false&loop=false&muted=false&preload=false&responsive=true" loading="lazy" style="border:0;position:absolute;top:0;height:100%;width:100%;" allow="accelerometer;gyroscope;autoplay;encrypted-media;picture-in-picture;" allowfullscreen="true"></iframe></div>

### What I Learned
**Data quality matters.** You need to perform consistent motions for effective training. 75 clean episodes with a consistent grasp strategy outperformed 81 episodes with mixed techniques. The policy learns exactly what you show it, including your bad habits.

**Workspace density matters.** 50 episodes across 30cm failed; 75 episodes across 10cm succeeded. For small datasets, constrain the task space and increase coverage density.

**Overhead cam helps.** The trajectory of models trained with both wrist cam and overhead cam seems to be much smoother compared to the wrist-only model. Having another cam at a high angle might help.

**Teleoperation lag degrades demo quality.** LeRobot's `record_loop` couples camera capture, dataset writing, and teleop in one synchronous loop. Camera I/O blocks action forwarding, causing the follower to lag behind the leader. Had to move slowly during recording to keep demonstrations clean.

### What's Next
Obviously I could try to improve the success rate by collecting more data, adding more training steps, or using other tricks, but I'm more interested in these two points:

1. **IL ability is capped by human demos**: IL works, but it can't outperform beyond the demonstrations in the dataset. Can we fine-tune a VLA with RL to push the performance further?
2. **How to make VLAs more robust**: Currently the trained model only works in the same environment at my apartment. If I performed inference at another environment (e.g., some exhibit venue), it probably wouldn't work since it's purely based on RGB and gets affected by different lighting conditions, backgrounds, etc. How do you train a more robust VLA? Domain randomization? Or should I ditch RGB-only and switch to a depth-oriented (RGB-D) RL model?

For now I'm thinking of exploring point 1 and trying to fine-tune a VLA with RL or something like HIL-SERL, though I need to research more first.

All code is built on LeRobot with a custom fork. GitHub repo: [https://github.com/ggand0/vla-so101](https://github.com/ggand0/vla-so101). Datasets are on HuggingFace Hub under `gtgando/so101_pick_place_10cm_*`.