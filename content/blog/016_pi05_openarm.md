+++
title = "Training pi0.5 on OpenArm: from teleop data to a 100% pick-and-place policy"
slug = "pi05-openarm"
date = 2026-09-04
draft = false

[extra]
thumb = "https://ggando.b-cdn.net/pi05_openarm_wrist_640.jpg"

[taxonomies]
categories = ["blog", "tech"]
tags = ["robotics", "vla", "openarm", "lerobot"]
+++

<img src="https://ggando.b-cdn.net/pi05_openarm_wrist_1280.jpg" alt="OpenArm wrist camera view of the gripper placing a nut" width="640" style="display: block; margin: auto;"/>

I've been working on a robotics contract at [APTO](https://apto.co.jp/), a Japanese startup, for a while now. I had a chance to prototype pi0.5 models with [OpenArm](https://openarm.dev/), and it was a very educational experience. pi0.5 is Physical Intelligence's 3.6B-parameter VLA (Vision-Language-Action model), and we fine-tuned it on the open-source bimanual OpenArm robot with LeRobot, going from teleop data collection all the way to a policy that hits 100% success on a pick-and-place task.

I wrote a blog post about the whole process on APTO's tech blog. The post covers the full pipeline: the teleop recording cell, the training recipe, real-time chunking inference, robustness tests under sensor loss, and three silent pitfalls that never raised an error but cost us the most time.

<!-- more -->

Read the full article here:

**[Training pi0.5 on OpenArm: from teleop data to a 100% pick-and-place policy →](https://apto.co.jp/robotics/blog/pi05-openarm/)**
