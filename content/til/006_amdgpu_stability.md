+++
title = "AMD GPU Stability"
slug = "amdgpu_stability"
date = 2025-12-14
draft = false

[taxonomies]
categories = ["til", "amd", "linux"]
tags = ["blog"]
+++

I've been encountering more freezes and crashes with my AMD GPU lately. This has been the case since I started using it on Ubuntu 22.04, but it's happening more often now as I run longer RL training sessions.

I see logs like this with `sudo dmesg -w | grep -i amdgpu`:
<details>
<summary>log</summary>

```bash
[45766.649450] amdgpu 0000:2f:00.0: amdgpu: GCVM_L2_PROTECTION_FAULT_STATUS:0x00000000
[45766.649454] amdgpu 0000:2f:00.0: amdgpu:      Faulty UTCL2 client ID: CB/DB (0x0)
[45766.649458] amdgpu 0000:2f:00.0: amdgpu:      MORE_FAULTS: 0x0
[45766.649462] amdgpu 0000:2f:00.0: amdgpu:      WALKER_ERROR: 0x0
[45766.649465] amdgpu 0000:2f:00.0: amdgpu:      PERMISSION_FAULTS: 0x0
[45766.649469] amdgpu 0000:2f:00.0: amdgpu:      MAPPING_ERROR: 0x0
[45766.649473] amdgpu 0000:2f:00.0: amdgpu:      RW: 0x0
[45766.649480] amdgpu 0000:2f:00.0: amdgpu: [gfxhub] page fault (src_id:0 ring:169 vmid:0 pasid:0, for process  pid 0 thread  pid 0)
[45766.649486] amdgpu 0000:2f:00.0: amdgpu:   in page starting at address 0x0000000000000000 from client 10
[45766.649491] amdgpu 0000:2f:00.0: amdgpu: GCVM_L2_PROTECTION_FAULT_STATUS:0x00000000
[45766.649494] amdgpu 0000:2f:00.0: amdgpu:      Faulty UTCL2 client ID: CB/DB (0x0)
[45766.649499] amdgpu 0000:2f:00.0: amdgpu:      MORE_FAULTS: 0x0
[45766.649502] amdgpu 0000:2f:00.0: amdgpu:      WALKER_ERROR: 0x0
[45766.649506] amdgpu 0000:2f:00.0: amdgpu:      PERMISSION_FAULTS: 0x0
[45766.649510] amdgpu 0000:2f:00.0: amdgpu:      MAPPING_ERROR: 0x0
[45766.649513] amdgpu 0000:2f:00.0: amdgpu:      RW: 0x0
[45767.021585] amdgpu 0000:2f:00.0: amdgpu: soft reset failed, will fallback to full reset!
[45767.270210] [drm:mes_v11_0_submit_pkt_and_poll_completion.constprop.0 [amdgpu]] *ERROR* MES failed to response msg=3
[45767.270475] [drm:amdgpu_mes_unmap_legacy_queue [amdgpu]] *ERROR* failed to unmap legacy queue
[45767.393294] [drm:mes_v11_0_submit_pkt_and_poll_completion.constprop.0 [amdgpu]] *ERROR* MES failed to response msg=3
[45767.393507] [drm:amdgpu_mes_unmap_legacy_queue [amdgpu]] *ERROR* failed to unmap legacy queue
[45767.516446] [drm:mes_v11_0_submit_pkt_and_poll_completion.constprop.0 [amdgpu]] *ERROR* MES failed to response msg=3
[45767.516671] [drm:amdgpu_mes_unmap_legacy_queue [amdgpu]] *ERROR* failed to unmap legacy queue
[45767.639817] [drm:mes_v11_0_submit_pkt_and_poll_completion.constprop.0 [amdgpu]] *ERROR* MES failed to response msg=3
[45767.640034] [drm:amdgpu_mes_unmap_legacy_queue [amdgpu]] *ERROR* failed to unmap legacy queue
[45767.762951] [drm:mes_v11_0_submit_pkt_and_poll_completion.constprop.0 [amdgpu]] *ERROR* MES failed to response msg=3
[45767.763170] [drm:amdgpu_mes_unmap_legacy_queue [amdgpu]] *ERROR* failed to unmap legacy queue
[45767.886107] [drm:mes_v11_0_submit_pkt_and_poll_completion.constprop.0 [amdgpu]] *ERROR* MES failed to response msg=3
[45767.886325] [drm:amdgpu_mes_unmap_legacy_queue [amdgpu]] *ERROR* failed to unmap legacy queue
[45768.009310] [drm:mes_v11_0_submit_pkt_and_poll_completion.constprop.0 [amdgpu]] *ERROR* MES failed to response msg=3
[45768.009532] [drm:amdgpu_mes_unmap_legacy_queue [amdgpu]] *ERROR* failed to unmap legacy queue
[45768.132480] [drm:mes_v11_0_submit_pkt_and_poll_completion.constprop.0 [amdgpu]] *ERROR* MES failed to response msg=3
[45768.132719] [drm:amdgpu_mes_unmap_legacy_queue [amdgpu]] *ERROR* failed to unmap legacy queue
[45768.255533] [drm:mes_v11_0_submit_pkt_and_poll_completion.constprop.0 [amdgpu]] *ERROR* MES failed to response msg=3
[45768.255760] [drm:amdgpu_mes_unmap_legacy_queue [amdgpu]] *ERROR* failed to unmap legacy queue
[45768.522784] [drm:gfx_v11_0_cp_gfx_enable.isra.0 [amdgpu]] *ERROR* failed to halt cp gfx
[45768.561065] amdgpu 0000:2f:00.0: amdgpu: MODE1 reset
[45768.561070] amdgpu 0000:2f:00.0: amdgpu: GPU mode1 reset
[45768.561151] amdgpu 0000:2f:00.0: amdgpu: GPU smu mode1 reset
[45769.077273] amdgpu 0000:2f:00.0: amdgpu: GPU reset succeeded, trying to resume
[45769.289571] amdgpu 0000:2f:00.0: amdgpu: RAP: optional rap ta ucode is not available
[45769.289576] amdgpu 0000:2f:00.0: amdgpu: SECUREDISPLAY: securedisplay ta ucode is not available
[45769.289581] amdgpu 0000:2f:00.0: amdgpu: SMU is resuming...
[45769.289586] amdgpu 0000:2f:00.0: amdgpu: smu driver if version = 0x0000003d, smu fw if version = 0x0000003f, smu fw program = 0, smu fw version = 0x004e7300 (78.115.0)
[45769.289590] amdgpu 0000:2f:00.0: amdgpu: SMU driver if version not matched
[45769.428583] amdgpu 0000:2f:00.0: amdgpu: SMU is resumed successfully!
[45769.513522] amdgpu 0000:2f:00.0: [drm:jpeg_v4_0_hw_init [amdgpu]] JPEG decode initialized successfully.
[45769.513951] amdgpu 0000:2f:00.0: amdgpu: ring gfx_0.0.0 uses VM inv eng 0 on hub 0
[45769.513953] amdgpu 0000:2f:00.0: amdgpu: ring comp_1.0.0 uses VM inv eng 1 on hub 0
[45769.513955] amdgpu 0000:2f:00.0: amdgpu: ring comp_1.1.0 uses VM inv eng 4 on hub 0
[45769.513957] amdgpu 0000:2f:00.0: amdgpu: ring comp_1.2.0 uses VM inv eng 6 on hub 0
[45769.513959] amdgpu 0000:2f:00.0: amdgpu: ring comp_1.3.0 uses VM inv eng 7 on hub 0
[45769.513961] amdgpu 0000:2f:00.0: amdgpu: ring comp_1.0.1 uses VM inv eng 8 on hub 0
[45769.513963] amdgpu 0000:2f:00.0: amdgpu: ring comp_1.1.1 uses VM inv eng 9 on hub 0
[45769.513964] amdgpu 0000:2f:00.0: amdgpu: ring comp_1.2.1 uses VM inv eng 10 on hub 0
[45769.513966] amdgpu 0000:2f:00.0: amdgpu: ring comp_1.3.1 uses VM inv eng 11 on hub 0
[45769.513968] amdgpu 0000:2f:00.0: amdgpu: ring sdma0 uses VM inv eng 12 on hub 0
[45769.513970] amdgpu 0000:2f:00.0: amdgpu: ring sdma1 uses VM inv eng 13 on hub 0
[45769.513972] amdgpu 0000:2f:00.0: amdgpu: ring vcn_unified_0 uses VM inv eng 0 on hub 8
[45769.513974] amdgpu 0000:2f:00.0: amdgpu: ring vcn_unified_1 uses VM inv eng 1 on hub 8
[45769.513975] amdgpu 0000:2f:00.0: amdgpu: ring jpeg_dec uses VM inv eng 4 on hub 8
[45769.513977] amdgpu 0000:2f:00.0: amdgpu: ring mes_kiq_3.1.0 uses VM inv eng 14 on hub 0
[45769.516831] amdgpu 0000:2f:00.0: amdgpu: recover vram bo from shadow start
[45769.533125] amdgpu 0000:2f:00.0: amdgpu: recover vram bo from shadow done
[45769.536136] amdgpu 0000:2f:00.0: amdgpu: GPU reset(2) succeeded!
[45769.572609] [drm:amdgpu_cs_ioctl [amdgpu]] *ERROR* Failed to initialize parser -125!
```
</details>

When this happens, the GUI session becomes completely unresponsive and training processes die. The GPU resets and I can still SSH into the machine from my laptop, but I need to reboot every time since GNOME Mutter is bad at handling it.

To alleviate this, I added two options `iommu=pt` and `amdgpu.gfxoff=0` to `GRUB_CMDLINE_LINUX_DEFAULT`:
```
GRUB_DEFAULT=0
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=10
GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash acpi_enforce_resources=lax iommu=pt amdgpu.gfxoff=0"
GRUB_CMDLINE_LINUX=""
```

- `iommu=pt`: IOMMU (a translation layer between devices and RAM) passthrough mode
- `amdgpu.gfxoff=0`: Disable GFXOFF (aggressive power saving that's buggy on RDNA3)

I set the passthrough mode because I was getting IOMMU translation failures. After editing, run `update-grub`:

```bash
sudo vim /etc/default/grub
sudo update-grub
sudo reboot
```

I also upgraded the kernel to a newer, possibly more stable version.

Original:
```bash
$ uname -r
6.2.0-39-generic
```

Update
```bash
# Install the HWE kernel (should give you 6.8.x)
sudo apt update
sudo apt install linux-generic-hwe-22.04

# Then reboot
sudo reboot
```

Post-update
```bash
$ uname -r
6.8.0-90-generic
```

After enabling `amdgpu.gfxoff=0`, I'm not getting freezes when I'm afk during training, but I still sometimes get random crashes when I actively use the desktop GUI. It seems that the multi-context contention between processes trying to access GPU like the browser doing hardware acceleration for video decoding is the source of issues. I plan to dig deeper when I have more time, but this is the reality of using AMD GPUs at the moment.

---

For the record, here's the summary created with Claude:

# AMD Radeon RX 7900 XTX Linux/ROCm/PyTorch Crash Troubleshooting Guide

## Executive Summary

This document chronicles an extensive troubleshooting session for recurring GPU crashes during PyTorch deep learning training on an AMD Radeon RX 7900 XTX under Linux. The issue is a **known, widely-reported problem** affecting RDNA3 GPUs running compute workloads alongside desktop usage. AMD has labeled it "Under Investigation" with no fix timeline.

---

## Table of Contents

1. [System Configuration](#system-configuration)
2. [Problem Description](#problem-description)
3. [Diagnostic Analysis](#diagnostic-analysis)
4. [Troubleshooting Steps Attempted](#troubleshooting-steps-attempted)
5. [Root Cause Analysis](#root-cause-analysis)
6. [Research Findings](#research-findings)
7. [Final Recommended Solution](#final-recommended-solution)
8. [Command Reference](#command-reference)
9. [Resources](#resources)

---

## System Configuration

| Component | Details |
|-----------|---------|
| **GPU** | AMD Radeon RX 7900 XTX (24GB VRAM) - Navi 31, gfx1100 |
| **PCI ID** | 0000:2f:00.0 |
| **OS** | Ubuntu 22.04 LTS |
| **ROCm Version** | 6.4.3 |
| **Original Kernel** | 6.2.0-39-generic |
| **DKMS Driver** | amdgpu/6.3.6-1697589.22.04 |
| **CPU** | AMD Ryzen (with Raphael integrated graphics) |
| **Use Case** | Long-running PyTorch training sessions (3+ hours) |

---

## Problem Description

### Symptoms

The GPU experiences frequent crashes during extended PyTorch deep learning training sessions with the following symptoms:

- **Complete GUI freeze** - System becomes visually unresponsive
- **Training processes die** - PyTorch jobs terminate without error messages
- **Cannot access TTY terminals** - Ctrl+Alt+F2/F3 non-responsive
- **No recovery possible** - Requires hard power cycle to reboot
- **Colored static/artifacts** - Sometimes screen fills with tiled patterns before freeze

### Crash Timing

- Crashes occur after **1-2 hours** of compute workload (sometimes up to 26 hours)
- More likely when running **multiple GPU contexts simultaneously**:
  - Desktop compositor (GNOME/Xorg)
  - Browser with hardware acceleration (Brave, Chrome, Firefox)
  - Video encoding (OBS)
  - PyTorch/ROCm compute workloads
- **Gaming workloads typically unaffected** - Issue specific to compute + display combination

### User Impact

From the user's perspective, this is equivalent to a full OS crash since:
- All work in progress is lost
- Training must restart from last checkpoint (if any)
- 5-10 minute recovery time per crash
- Unpredictable occurrence makes long training runs unreliable

---

## Diagnostic Analysis

### Kernel Log Analysis (dmesg)

The crash follows a consistent pattern visible in kernel logs:

#### Stage 1: Page Fault

```
amdgpu 0000:2f:00.0: amdgpu: [gfxhub] page fault (src_id:0 ring:xxx vmid:x pasid:xxxxx)
amdgpu 0000:2f:00.0: amdgpu: in page starting at address 0x0000000000000000 from client 10
amdgpu 0000:2f:00.0: amdgpu: GCVM_L2_PROTECTION_FAULT_STATUS:0x00000B3A
amdgpu 0000:2f:00.0: amdgpu: Faulty UTCL2 client ID: CPC (0x5)
amdgpu 0000:2f:00.0: amdgpu: MORE_FAULTS: 0x0
amdgpu 0000:2f:00.0: amdgpu: WALKER_ERROR: 0x5
amdgpu 0000:2f:00.0: amdgpu: PERMISSION_FAULTS: 0x3
amdgpu 0000:2f:00.0: amdgpu: MAPPING_ERROR: 0x1
```

**Interpretation:**
- **CPC (Command Processor Compute)** is the faulty client - indicates compute workload trigger
- **Address 0x0000000000000000** suggests null pointer dereference or page table corruption
- **WALKER_ERROR + MAPPING_ERROR** = Page table walk failure during address translation

#### Stage 2: MES Timeout

```
[drm:mes_v11_0_submit_pkt_and_poll_completion.constprop.0 [amdgpu]] *ERROR* MES failed to response msg=3
```

**Interpretation:**
- **MES (Micro Engine Scheduler)** is the GPU's internal job scheduler
- MES fails to respond to driver commands within timeout period
- This is the core bug - MES firmware cannot handle the error condition

#### Stage 3: Soft Reset Fails

```
[drm:amdgpu_mes_unmap_legacy_queue [amdgpu]] *ERROR* failed to unmap legacy queue
amdgpu 0000:2f:00.0: [drm:amdgpu_job_timedout [amdgpu]] *ERROR* ring gfx_0.0.0 timeout
```

**Interpretation:**
- GPU scheduler tries to recover by unmapping queues
- Timeout occurs waiting for GPU to respond
- Soft recovery path fails

#### Stage 4: MODE1 Reset

```
amdgpu 0000:2f:00.0: amdgpu: GPU reset begin!
amdgpu 0000:2f:00.0: amdgpu: GPU reset succeeded
```

**Interpretation:**
- Driver falls back to full hardware reset
- GPU recovers at hardware level
- **BUT** - Desktop session and applications are already dead

### SMU Firmware Mismatch

Additional warning observed:
```
amdgpu: SMU driver if version not matched
```

The driver expects SMU firmware version 0x3d but GPU reports 0x3f - indicates potential driver/firmware compatibility issue.

### Crash Triggers Observed

Different processes triggered crashes in different sessions:
- Xorg (display server)
- OBS (video encoding)
- Brave browser (hardware-accelerated compositing)
- Python/PyTorch processes

All crashes followed the identical MES failure pattern, suggesting the trigger is multi-context GPU scheduling, not any specific application.

---

## Troubleshooting Steps Attempted

### Step 1: IOMMU Configuration (Partial Success)

**Problem:** Default IOMMU settings can cause DMA conflicts with AMD GPUs.

**Action:**
```bash
# Added to GRUB_CMDLINE_LINUX_DEFAULT
iommu=pt
```

**Result:** Did not resolve crashes but is a recommended baseline setting.

---

### Step 2: Kernel Upgrade (Partial Success)

**Problem:** Kernel 6.2.0-39-generic was too old for RDNA3:
- Missing critical MES firmware fixes
- Missing GFXOFF power state bug patches
- Incomplete gfx1100 support

**Action:**
```bash
sudo apt install linux-generic-hwe-22.04
sudo reboot
# Verified: uname -r shows 6.8.x kernel
```

**Result:** 
- Page fault addresses changed from null pointer (0x0000000000000000) to actual memory addresses
- Suggests improved memory management
- Crashes still occur but pattern changed - now triggered after longer uptime during idle-to-active transitions
- Indicates power state management issues (GFXOFF wake-up failures)

---

### Step 3: Disable GFXOFF (Partial Success)

**Problem:** GFXOFF is an aggressive power-saving feature where the GPU compute engine powers down between tasks. RDNA3 has a buggy wake-up path that can cause page table corruption.

**Action:**
```bash
# Modified /etc/default/grub
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash acpi_enforce_resources=lax iommu=pt amdgpu.gfxoff=0"

# Applied changes
sudo update-grub
sudo reboot
```

**Result:**
- Did NOT fully resolve the issue
- Crash still occurred after **26 hours uptime**
- Triggered by Brave browser (hardware acceleration) while PyTorch training was running
- Indicates the problem is **multi-context MES scheduling conflicts**, not purely sleep/wake related

---

### Step 4: Extended Online Research

Extensive research was conducted across multiple sources to find additional solutions.

---

## Root Cause Analysis

### Primary Issue: Multi-GPU-Context MES Scheduling Conflicts

The crashes occur when multiple GPU contexts compete for resources:

1. **Desktop compositor** (GNOME Shell / Xorg)
2. **Browser hardware acceleration** (Brave, Chrome, Firefox, Electron apps)
3. **Video encoding** (OBS, screen recording)
4. **ROCm compute workloads** (PyTorch, TensorFlow, Stable Diffusion)

The **MES (Micro Engine Scheduler)** firmware on RDNA3 has bugs when handling simultaneous graphics and compute contexts, leading to:

- Page table corruption
- Fence timeouts
- Scheduler deadlocks
- Complete system freeze

### Contributing Factors

| Factor | Description |
|--------|-------------|
| **SMU Firmware Mismatch** | Driver/firmware version incompatibility warnings |
| **TMZ (Trusted Memory Zone) Bugs** | Known issues on RDNA3 causing memory access failures |
| **Scatter-Gather Display** | DMA fence timeout trigger during display buffer operations |
| **Power State Transitions** | GFXOFF, runtime PM causing wake-up failures |
| **iGPU Conflicts** | Ryzen's integrated graphics can interfere with dedicated GPU scheduling |
| **Kernel Version** | Pre-6.8 kernels lack critical RDNA3 stability fixes |

### Why Gaming Works But Compute Doesn't

Gaming workloads typically:
- Use a single GPU context (the game)
- Don't share GPU with other applications during gameplay
- Use graphics pipelines that are better tested

Compute workloads:
- Run alongside desktop compositor
- Share GPU with browser, video calls, etc.
- Exercise the MES scheduler's multi-context handling
- Use compute queues that have different firmware paths

---

## Research Findings

### Known Issue Status

This is a **widely reported, ongoing issue** with extensive documentation:

| Source | Issue Numbers |
|--------|---------------|
| ROCm GitHub | #3265, #3166, #3452, #2689, #1977 |
| freedesktop.org GitLab | #2378, multiple others |
| Arch Linux Forums | Multiple threads |
| Phoronix Forums | Multiple discussions |
| Tom's Hardware | Multiple threads |
| PyTorch Forums | Multiple reports |

### Affected Configurations

- **GPUs:** RX 7900 XTX, RX 7900 XT, RX 7800 XT (all RDNA3)
- **Distros:** Ubuntu, Fedora, Arch, OpenSUSE Tumbleweed, Gentoo
- **ROCm Versions:** 5.7.x, 6.0.x, 6.1.x, 6.2.x (all affected)
- **Kernels:** 6.0 through 6.14+ (some versions better than others)

### AMD's Response

- Issue labeled "Under Investigation"
- No fix timeline provided
- Official ROCm support for 7900 XTX only since August 2023 (ROCm 5.7)
- RDNA3 MES firmware bugs still being actively patched upstream

### Community Workarounds

#### Option A: Use iGPU for Display (Most Stable)

The most effective workaround reported by multiple users:

> "Connecting all monitors to the motherboard video output so that nothing else gets rendered on the dedicated GPU (7900 XTX). This prevents PC from getting frozen down, but it will still hang GPU from time to time. This only requires restarting stable diffusion from the terminal."

**Implementation:**
1. Connect monitors to motherboard HDMI/DisplayPort (uses Ryzen iGPU)
2. Keep 7900 XTX purely for compute (no display output)
3. When GPU hangs, desktop remains responsive
4. Restart training script instead of rebooting entire system

**Limitation:** User requires full desktop environment on the dedicated GPU, making this option unacceptable for their use case.

#### Option B: Comprehensive Mitigation Stack

Combine all available mitigations:
- Aggressive kernel parameters
- Disable browser hardware acceleration
- Environment variables for PyTorch isolation
- Updated firmware

---

## Final Recommended Solution

### 1. Aggressive Kernel Parameters

Edit `/etc/default/grub`:

```bash
sudo nano /etc/default/grub
```

Set `GRUB_CMDLINE_LINUX_DEFAULT` to:

```
quiet splash iommu=pt amdgpu.tmz=0 amdgpu.sg_display=0 amdgpu.dcdebugmask=0x10 amdgpu.gpu_recovery=1 amdgpu.gfxoff=0 amdgpu.runpm=0 pcie_aspm=off
```

#### Parameter Explanations

| Parameter | Purpose | Why It Helps |
|-----------|---------|--------------|
| `iommu=pt` | IOMMU pass-through mode | Reduces DMA conflicts between GPU and system |
| `amdgpu.tmz=0` | Disable Trusted Memory Zone | TMZ has bugs on RDNA3 causing freezes |
| `amdgpu.sg_display=0` | Disable scatter-gather for display | Reduces DMA fence timeouts |
| `amdgpu.dcdebugmask=0x10` | Disable Display Core debug features | DC debugging can cause hangs |
| `amdgpu.gpu_recovery=1` | Enable automatic GPU recovery | GPU can attempt self-reset instead of system crash |
| `amdgpu.gfxoff=0` | Disable GFX power gating | Prevents wake-from-idle crashes |
| `amdgpu.runpm=0` | Disable runtime power management | Prevents suspend/resume related crashes |
| `pcie_aspm=off` | Disable PCIe Active State PM | Prevents PCIe link power state issues |

Apply changes:

```bash
sudo update-grub
sudo reboot
```

### 2. Disable Browser Hardware Acceleration

**Critical step** - Browser hardware acceleration creates additional GPU contexts that trigger MES scheduling conflicts.

| Application | Settings Path |
|-------------|---------------|
| **Brave** | Settings → System → Disable "Use hardware acceleration when available" |
| **Chrome** | Settings → System → Disable "Use hardware acceleration when available" |
| **Firefox** | Settings → Performance → Uncheck "Use recommended performance settings" → Uncheck "Use hardware acceleration when available" |
| **Discord** | Settings → Advanced → Disable "Hardware Acceleration" |
| **VS Code** | Settings → Search "gpu" → Disable hardware acceleration |
| **Slack** | Preferences → Advanced → Disable hardware acceleration |
| **Any Electron app** | Usually in Settings/Preferences → Advanced |

### 3. PyTorch/ROCm Environment Variables

Add to `~/.bashrc` or your training script:

```bash
# Force PyTorch to use only the discrete GPU (device 0)
# Avoids iGPU/dGPU scheduling conflicts
export HIP_VISIBLE_DEVICES=0

# Explicitly set GFX version for gfx1100 (7900 XTX)
export HSA_OVERRIDE_GFX_VERSION=11.0.0

# Memory allocation tuning to reduce fragmentation
# Helps prevent OOM situations that can trigger crashes
export PYTORCH_HIP_ALLOC_CONF=garbage_collection_threshold:0.8,max_split_size_mb:512

# Optional: Explicitly set ROCm architecture
export PYTORCH_ROCM_ARCH="gfx1100"
```

### 4. Update Firmware

```bash
sudo apt update
sudo apt install --reinstall linux-firmware
sudo reboot
```

### 5. Alternative: Modprobe Configuration

Instead of kernel command line parameters, you can use modprobe configuration:

```bash
sudo nano /etc/modprobe.d/amdgpu.conf
```

Add:

```
options amdgpu gpu_recovery=1
options amdgpu gfxoff=0
options amdgpu tmz=0
options amdgpu sg_display=0
options amdgpu dcdebugmask=16
options amdgpu runpm=0
```

Apply:

```bash
sudo update-initramfs -u
sudo reboot
```

### 6. Training Checkpoint Strategy

Given that occasional crashes may still occur, implement checkpoint/resume in your training code:

```python
import torch
import os

def save_checkpoint(epoch, model, optimizer, loss, path='checkpoint.pt'):
    torch.save({
        'epoch': epoch,
        'model_state_dict': model.state_dict(),
        'optimizer_state_dict': optimizer.state_dict(),
        'loss': loss,
    }, path)

def load_checkpoint(model, optimizer, path='checkpoint.pt'):
    if os.path.exists(path):
        checkpoint = torch.load(path)
        model.load_state_dict(checkpoint['model_state_dict'])
        optimizer.load_state_dict(checkpoint['optimizer_state_dict'])
        start_epoch = checkpoint['epoch'] + 1
        loss = checkpoint['loss']
        print(f"Resumed from epoch {start_epoch}")
        return start_epoch, loss
    return 0, None

# In training loop:
for epoch in range(start_epoch, num_epochs):
    # ... training code ...
    
    # Save checkpoint every N epochs
    if epoch % checkpoint_interval == 0:
        save_checkpoint(epoch, model, optimizer, loss)
```

---

## Additional Considerations

### Kernel Version Recommendations

| Kernel | Status |
|--------|--------|
| 6.2.x | Too old, missing critical RDNA3 fixes |
| 6.8.x HWE | Reasonable baseline for Ubuntu 22.04 |
| 6.11.x | Often reported as more stable for RDNA3 |
| 6.14-6.17 | May have TLB fence issues, avoid if problems occur |

### If Above Fixes Are Insufficient

1. **Nuclear ppfeaturemask option:**
   ```
   amdgpu.ppfeaturemask=0xfffd3fff
   ```
   Disables additional power features including GFXOFF, stutter mode, and overdrive.

2. **Try mainline kernel:** Install kernel 6.11+ for latest RDNA3 fixes

3. **Docker isolation:** Run PyTorch in Docker container with GPU passthrough for cleaner isolation from desktop

4. **Dual-GPU setup:** Use iGPU for display, 7900 XTX for compute only (requires BIOS configuration)

5. **Wait for AMD fix:** Issue is under active investigation - firmware/driver updates may resolve

---

## Command Reference

### System Information

```bash
# Kernel version
uname -r

# GPU info
lspci | grep -i vga

# ROCm installation verification
rocm-smi --showproductname
rocminfo | head -50

# amdgpu driver version
modinfo amdgpu | grep version
```

### Parameter Verification

```bash
# Check active kernel parameters
cat /proc/cmdline

# Check specific amdgpu parameters
cat /sys/module/amdgpu/parameters/gfxoff
cat /sys/module/amdgpu/parameters/gpu_recovery
cat /sys/module/amdgpu/parameters/tmz
cat /sys/module/amdgpu/parameters/runpm
```

### Log Analysis

```bash
# Check for GPU errors in kernel messages
sudo dmesg | grep -i "amdgpu\|gpu\|fence\|timeout" | tail -50

# Check system journal
sudo journalctl -b -0 --no-pager | grep -i "amdgpu\|gpu hung\|fence" | tail -50

# Watch kernel messages in real-time
sudo dmesg -w | grep -i amdgpu

# Check firmware version
sudo dmesg | grep "smu fw version"
```

### GPU Monitoring

```bash
# Real-time GPU monitoring (ROCm)
watch -n 1 rocm-smi

# Check power management state
cat /sys/class/drm/card0/device/power_dpm_force_performance_level

# Check current GPU clocks
cat /sys/class/drm/card0/device/pp_dpm_sclk
cat /sys/class/drm/card0/device/pp_dpm_mclk

# GPU temperature and power
rocm-smi --showtemp --showpower
```

### Testing

```bash
# Quick PyTorch GPU test
python3 -c "import torch; print(torch.cuda.is_available()); print(torch.cuda.get_device_name(0))"

# Stress test (be prepared for potential crash)
python3 -c "import torch; x = torch.randn(10000, 10000, device='cuda'); print(x.sum())"
```

---

## Resources

### Official Documentation

- [AMD ROCm Documentation](https://rocm.docs.amd.com/)
- [Linux Kernel AMDGPU Module Parameters](https://docs.kernel.org/gpu/amdgpu/module-parameters.html)
- [PyTorch ROCm Installation](https://pytorch.org/get-started/locally/)

### Issue Trackers

- [ROCm GitHub Issues](https://github.com/ROCm/ROCm/issues) - Search for "7900 XTX"
- [AMD DRM GitLab Issues](https://gitlab.freedesktop.org/drm/amd/-/issues)

### Community Resources

- [Arch Wiki AMDGPU](https://wiki.archlinux.org/title/AMDGPU) - Excellent technical reference
- [LLM Tracker AMD GPU Guide](https://llm-tracker.info/howto/AMD-GPUs)
- [Phoronix Forums](https://www.phoronix.com/forums/) - Linux GPU discussions

### Troubleshooting Guides

- [A Dummy's Guide to AMD GPU Issues on Linux](https://gist.github.com/danielrosehill/6a531b079906f160911a87dea50e1507) - Comprehensive kernel parameter guide

---

## Timeline of Troubleshooting Session

| Step | Action | Outcome |
|------|--------|---------|
| 1 | Initial dmesg analysis | Identified page fault → MES timeout → MODE1 reset pattern |
| 2 | Added `iommu=pt` | No significant change |
| 3 | Upgraded to kernel 6.8 HWE | Partial improvement - different crash pattern |
| 4 | Added `amdgpu.gfxoff=0` | Still crashed after 26 hours |
| 5 | Extensive online research | Confirmed widespread issue, found additional parameters |
| 6 | Compiled comprehensive fix | Combined all mitigations into final solution |

---

## Summary

The 7900 XTX crashes during PyTorch training are caused by **MES firmware bugs** in RDNA3 when handling simultaneous graphics and compute contexts. This is a **known issue under investigation by AMD** with no current fix.

The mitigation strategy combines:

1. **Kernel parameters** to disable problematic power features (TMZ, GFXOFF, runtime PM, scatter-gather display)
2. **Enable GPU recovery** for automatic reset capability
3. **Disable browser hardware acceleration** to reduce GPU context contention
4. **Environment variables** to isolate PyTorch to the discrete GPU
5. **Training checkpoints** to minimize data loss from crashes

This should significantly improve stability while maintaining full desktop functionality on the 7900 XTX, though occasional crashes may still occur until AMD releases a proper fix.

---

## Document Information

- **Created:** December 2025
- **System:** Ubuntu 22.04 LTS + AMD RX 7900 XTX + ROCm 6.4.3
- **Purpose:** Reference guide for troubleshooting RDNA3 compute stability issues on Linux