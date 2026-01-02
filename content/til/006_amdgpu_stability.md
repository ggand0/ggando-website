+++
title = "AMD GPU Stability"
slug = "amdgpu_stability"
date = 2025-12-14
draft = false

[taxonomies]
categories = ["til", "amd", "linux"]
tags = ["blog"]
+++

I've been encountering more freezes and crashes with my AMD GPU lately. This has been the case since I started using it on Ubuntu 22.04, but it's happening more often now as I run longer RL training sessions. Crashes occur after **1-2 hours** of compute workload (sometimes up to 26 hours)

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

### Crash Pattern (analyzed by Claude)

1. **Page Fault** → CPC (Command Processor Compute) fails at address 0x0, page table corruption
2. **MES Timeout** → GPU's job scheduler stops responding (`MES failed to response msg=3`)
3. **Soft Reset Fails** → Can't unmap queues, recovery path broken
4. **MODE1 Reset** → Full hardware reset succeeds, but desktop session already dead

Also seeing `SMU driver if version not matched` (driver expects 0x3d, GPU reports 0x3f) — firmware/driver compatibility issue.

<details>
<summary>Diagnosis by Claude</summary>

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

</details>


### Fix attempts

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

After enabling `amdgpu.gfxoff=0`, I'm not getting freezes when I'm afk during training, but I still sometimes get random crashes when I actively use the desktop GUI. It seems that the multi-context contention between processes trying to access GPU like the browser doing hardware acceleration for video decoding is the source of issues. 

I'll dig deeper when I have more time, but this is the reality of using AMD GPUs at the moment.


### UPDATE

I disabled the hardware acceleration of browsers (Brave and Chrome) and disabled more power features by adding the `amdgpu.ppfeaturemask=0xfffd7fff` flag, it survived for about 9 days before it crashes caused by AnyType (note taking app that presumably used GPU). My apps that use GPUs like the bevy game or image viewer sometimes experience lag spikes though. But this is good enough for now. I plan to upgrade to Ubuntu 24.04 and see if it improves the situation.


---

For the record, here's my system info and some resources I found:

### System Configuration

| Component | Details |
|-----------|---------|
| **GPU** | AMD Radeon RX 7900 XTX (24GB VRAM) - Navi 31, gfx1100 |
| **OS** | Ubuntu 22.04 LTS |
| **ROCm Version** | 6.4.3 |
| **Original Kernel** | 6.2.0-39-generic |
| **DKMS Driver** | amdgpu/6.3.6-1697589.22.04 |
| **CPU** | AMD Ryzen (with Raphael integrated graphics) |


### Resources

This is a **widely reported, ongoing issue** with extensive documentation:

| Source | Issue Numbers |
|--------|---------------|
| ROCm GitHub | #3265, #3166, #3452, #2689, #1977 |
| freedesktop.org GitLab | #2378, multiple others |

- [A Dummy's Guide to AMD GPU Issues on Linux](https://gist.github.com/danielrosehill/6a531b079906f160911a87dea50e1507) - Comprehensive kernel parameter guide


---

