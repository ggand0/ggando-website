
+++
title = "Training a 3D Dodge Agent with Reinforcement Learning"
slug = "bevy-3d-dodge"
date = 2026-01-01
draft = false

[extra]
thumb = "https://ggando.b-cdn.net/bevy_rl_game_v2_640.jpg"

[taxonomies]
categories = ["blog"]
tags = ["rust", "bevy", "rl", "python"]
+++

<img src="https://ggando.b-cdn.net/bevy_rl_game_v2_640.jpg" alt="img0" width="640" style="display: block; margin: auto;"/>

## Intro
Inspired by @warehouse YT videos, I built a Bevy-based 3D dodge game designed as a reinforcement learning environment. The player must keep avoiding projectiles (red balls), and I exposed APIs to control the action and receive observations/rewards. The environment exposes a standard Gymnasium interface over HTTP or gRPC, and also supports parallel environments to speed up training.

## Level 1: The Baseline Setup
I started with an easy level (projectiles are slow and predictable) as the baseline. I used discrete actions (move left/right/forward/back) and DQN from stable-baselines3, because this was the only deep reinforcement learning model I knew (my knowledge stops at 2016 lol).
After the initial 300k training run, DQN managed a 30% success rate with high variance (mean reward 641 ± 325), but I felt a limitation here and switched to PPO. PPO achieved a 100% success rate in just 10k steps (about 10 minutes of training), and all 20 evaluation episodes reached the max 1000 steps with perfect consistency.

## Level 2: Ramping Up Difficulty
With Level 1 solved, I added Level 2 to increase the difficulty. Now projectiles travel 50% faster (4.5 units/sec), spawn 4x more frequently (every 0.5 seconds), and come from a wider arc instead of straight ahead. I also switched from discrete to continuous actions, using a simplified 3D action space: [vx, vy, sprint] where sprint multiplies base speed.
I initially tried spawning balls from a ±60° arc, but this turned out to be too hard. The agent only achieved a best eval reward of 38.10 ± 68.65, essentially failing to learn anything useful. After narrowing the spawn arc to ±30°, training started working, hitting 130.59 mean reward at 500k steps with 2x sprint.

## PPO's Limits and SAC Breakthrough
Since the eval reward curve was still monotonically increasing, I extended the ±30° setup to 2M steps with stability tweaks: dropped learning rate to 0.0001 and tightened clip range to 0.15 to match the longer training duration.
However, the best eval reward only improved from 170.61 at 1M steps to 177.03 at 2M, and the agent still struggled to dodge balls consistently. The second million steps showed signs of PPO hitting its limits.
Then I switched to SAC, which is known to perform well on continuous control tasks in RL. At just 550k steps, SAC hit 355.24 mean reward, which is 2x better than PPO's best at 2M steps. Training became stable with consistent improvement, and evaluation episodes looked promising.
I'm still learning this, but SAC's replay buffer and sample efficiency seem to help here. The replay buffer lets it learn from each dodge pattern hundreds of times instead of once, and off-policy learning makes it more sample efficient. But 15% success meant the agent still died early in most episodes, and I needed to figure out why.

<blockquote class="twitter-tweet"><p lang="en" dir="ltr">I&#39;m training RL agents for a 3D dodge game in Bevy. Here&#39;s SAC (left) vs PPO (right) after 2M steps. SAC performs much better, but still dies early sometimes. It tries to dodge one ball and runs into another one <a href="https://twitter.com/hashtag/reinforcementlearning?src=hash&amp;ref_src=twsrc%5Etfw">#reinforcementlearning</a> <a href="https://twitter.com/hashtag/bevyengine?src=hash&amp;ref_src=twsrc%5Etfw">#bevyengine</a> <a href="https://t.co/mlyrEYFV8C">pic.twitter.com/mlyrEYFV8C</a></p>&mdash; Gota (@gtgando) <a href="https://twitter.com/gtgando/status/2002722344041861496?ref_src=twsrc%5Etfw">December 21, 2025</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

## Improving Observations: Thrower Visibility
Watching the SAC agent fail, I initially thought it was struggling with balls spawning from unexpected angles in the ±30° arc. To help the agent anticipate incoming projectiles, I added a thrower indicator: an orange glowing sphere appears at the future spawn location for 1 second before each projectile spawns. I extended the state from 65 to 69 dimensions to include the thrower's position (x, y, z) and time until throw.
I trained SAC with this extended observation space for 2M steps on the ±30° setup. The results improved: the agent achieved a 50% success rate (5/10 episodes hitting 1000 steps), compared to 15% without the thrower indicator.
However, rewatching the eval episodes revealed the actual failure pattern: the agent dies when it tries to avoid one ball while running into another. The thrower indicator helped, but the agent seems to be optimizing for immediate local threats rather than global planning (a greedy, reactive policy). A possible next step is introducing an attention module so the agent can learn to weight multiple projectiles by importance rather than just reacting to the nearest one.

<div style="position:relative;padding-top:56.25%;"><iframe src="https://iframe.mediadelivery.net/embed/399279/5f0a0bb2-11c9-4b34-9d89-5eecfc9a9ca0?autoplay=false&loop=false&muted=false&preload=false&responsive=true" loading="lazy" style="border:0;position:absolute;top:0;height:100%;width:100%;" allow="accelerometer;gyroscope;autoplay;encrypted-media;picture-in-picture;" allowfullscreen="true"></iframe></div>

## Observations and Future Work
The agent trained on the thrower setup learned to shuffle back and forth at the rear of the play area. This makes sense since the projectiles are aimed at the agent's current position, so constant movement left and right is a good strategy.
But I'd like to get agents to learn visually interesting motions, not just optimal ones. I'm thinking about ways to encourage more dynamic dodging, for example introducing rewards for close-call dodges (near misses), or a two-player adversarial setup where the thrower is also an RL agent that learns to predict and counter the dodger's movements.
<br />
<br />