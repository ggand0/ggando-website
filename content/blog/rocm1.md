+++
title = "Upgrading ROCm from 5.7.1 to 6.4.3"
date = 2025-09-17
draft = false

[extra]
thumb = "https://ggando.b-cdn.net/rocm_upgrade2_640px.jpg"

[taxonomies]
categories = ["blog"]
tags = ["rocm", "amd", "pytorch", "triton"]
+++

<img src="https://ggando.b-cdn.net/rocm_upgrade2_640px.jpg" alt="img0" width="640" style="display: block; margin: auto;"/>

## Motivation
The other day, I was trying to run RT-DETR on my AMD GPU (7900XTX) but hit this error:
```bash
AttributeError: module 'triton' has no attribute 'language'
```

Newer PyTorch versions use [TorchDynamo](https://docs.pytorch.org/docs/stable/torch.compiler_dynamo_overview.html), which expects modern Triton APIs. Triton is already integrated into PyTorch for CUDA GPUs, but you need to install a separate ROCm implementation (pytorch-triton-rocm). I initially used PyTorch 2.4.1+rocm6.0 and pytorch-triton-rocm 3.0.0, but encountered the above error. After some research with Claude Code, I realized this version was a bit old (July 2024) and the current main branch does have the `triton.language` module.

PyTorch ROCm builds are locked to their specific pytorch-triton-rocm versions, so to upgrade triton I needed to upgrade PyTorch versions, and I decided to upgrade ROCm too.

## Checking the current versions
`cat /opt/rocm/.info/version` or `ls /opt/rocm*` should give you the ROCm version you installed. You can also check at the package level with `dpkg -l | grep rocm` or `apt list --installed | grep rocm` if you installed it via package manager. Example output:
```bash
$ dpkg -l | grep rocm
ii  rocm-cmake5.7.1                                             0.10.0.50701-98~22.04                               amd64        rocm-cmake built using CMake
ii  rocm-core                                                   6.0.0.60000-91~22.04                                amd64        Radeon Open Compute (ROCm) Runtime software stack
ii  rocm-core5.7.1                                              5.7.1.50701-98~22.04                                amd64        Radeon Open Compute (ROCm) Runtime software stack
ii  rocm-device-libs5.7.1                                       1.0.0.50701-98~22.04                                amd64 
...
```
You can see that ROCm 5.7.1 packages are installed here.

## Uninstalling ROCm 5.7.1
Looking at [the official uninstall instructions](https://rocm.docs.amd.com/en/docs-5.7.1/deploy/linux/os-native/uninstall.html#), I noticed that the installation package for ROCm 5.7.1 is `rocm-hip-sdk`, but for ROCm 6.4.3 it's just `rocm`, so I uninstalled the old ROCm to be safe. The uninstallation step is the same for 6.0.0 ([ref](https://rocm.docs.amd.com/projects/install-on-linux/en/docs-6.0.0/how-to/native-install/ubuntu.html#uninstalling)). I recommend running both `sudo apt autoremove <package-name>` and `sudo apt autoremove <package-name with release version>` to make sure you uninstall old packages completely:
```bash
sudo apt autoremove rocm-hip-sdk5.7.1
sudo apt autoremove rocm-core5.7.1
sudo apt autoremove rocm-hip-sdk
sudo apt autoremove rocm-core
```
My system only had these two packages though:
```bash
sudo apt autoremove rocm-hip-sdk5.7.1
sudo apt autoremove rocm-core
```

After uninstallation, verify that no ROCm packages are installed:
```bash
$ apt list --installed | grep rocm
$ ls /opt/rocm*
```

Finally, remove the apt ROCm repository:
```bash
$ sudo rm /etc/apt/sources.list.d/rocm.list
```

For the kernel driver, 6.4.3 still uses the same package `amdgpu-dkms`, so <u>I didn't have to uninstall it</u>.

## Installing ROCm 6.4.3

Now we can just follow [the ROCm 6.4.3 documentation](https://rocm.docs.amd.com/projects/install-on-linux/en/docs-6.4.3/install/install-methods/package-manager/package-manager-ubuntu.html#registering-rocm-repositories) to install it.

### Prerequisites
Read the official doc [here](https://rocm.docs.amd.com/projects/install-on-linux/en/docs-6.4.3/install/prerequisites.html#using-udev-rules). I don't use Secure Boot on this computer, and I just configured GPU access permissions by adding myself to the `render` and `video` groups:
```bash
sudo usermod -a -G render,video $LOGNAME
```

### Installation

Note that the new ROCm package is 23+GB.

Download and convert the package signing key:
```bash
sudo apt update && sudo apt upgrade

sudo mkdir --parents --mode=0755 /etc/apt/keyrings

wget https://repo.radeon.com/rocm/rocm.gpg.key -O - | \
    gpg --dearmor | sudo tee /etc/apt/keyrings/rocm.gpg > /dev/null
```

Register packages:
```bash
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/6.4.3 jammy main" \
    | sudo tee /etc/apt/sources.list.d/rocm.list
echo -e 'Package: *\nPin: release o=repo.radeon.com\nPin-Priority: 600' \
    | sudo tee /etc/apt/preferences.d/rocm-pin-600
sudo apt update
```

Install the ROCm package:
```bash
$ sudo apt install rocm
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following additional packages will be installed:
  amd-smi-lib comgr composablekernel-dev gdal-data half hip-dev hip-doc hip-runtime-amd hip-samples hipblas hipblas-common-dev hipblas-dev hipblaslt
...
rocthrust-dev roctracer roctracer-dev rocwmma-dev rpp rpp-dev unixodbc-common valgrind
0 upgraded, 183 newly installed, 0 to remove and 4 not upgraded.
Need to get 3,992 MB of archives.
After this operation, 23.8 GB of additional disk space will be used.
Do you want to continue? [Y/n]
```

### Post-installation setup

Make sure to follow [the post-installation instructions](https://rocm.docs.amd.com/projects/install-on-linux/en/docs-6.4.3/install/post-install.html), especially the system linker step:
```bash
sudo tee --append /etc/ld.so.conf.d/rocm.conf <<EOF
/opt/rocm/lib
/opt/rocm/lib64
EOF
sudo ldconfig
```

After that, you also need to configure paths:
```bash
sudo update-alternatives --display rocm
rocm - auto mode
  link best version is /opt/rocm-6.4.3
  link currently points to /opt/rocm-6.4.3
  link rocm is /opt/rocm
/opt/rocm-6.4.3 - priority 649626295
# -> shows update-alternatives is already working and has automatically configured ROCm 6.4.3 as the default version.

# Claude suggested this rather than the `export LD_LIBRARY_PATH=/opt/rocm-6.4.3/lib`
echo 'export LD_LIBRARY_PATH=/opt/rocm/lib' >> ~/.bashrc
```

Now, confirm that the new ROCm has been installed:
```bash
$ cat /opt/rocm/.info/version
6.4.3-128
```
Verify you can run `rocminfo` and `rocm-smi` commands. After a reboot, you should be able to install newer PyTorch and triton versions!

## What I installed for RT-DETR
For the record, after this upgrade I was able to install these newer torch packages for running RT-DETR GPU inference and resolve the previous `AttributeError`:
```toml
# Working setup
torch = "2.6.0+rocm6.4.3"
torchvision = "0.21.0+rocm6.4.3"
torchaudio = "2.6.0+rocm6.4.3"
pytorch-triton-rocm = "3.2.0+rocm6.4.3"  # <- Now has triton.language
transformers = "4.55.4"
```
Here's an example detection result with the RT-DETR Large model:

<img src="https://ggando.b-cdn.net/rtdetr_inference_4k.jpg" alt="img0" width="640" style="display: block; margin: auto;"/>