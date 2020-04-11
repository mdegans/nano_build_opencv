# OpenCV build script for NVIDIA Jetson Nano

This is the Docker branch, __currently in a broken state__ because `cicc` is not in the l4t base image.

Related thread on Nvidia developer forum 
[here](https://devtalk.nvidia.com/default/topic/1051133/jetson-nano/opencv-build-script/).

[How it Works](https://wiki.debian.org/QemuUserEmulation)

## Usage:
```shell
(clone repo)
(sudo) docker build -t tegra_opencv:latest nano_build_opencv
```

## Specifying an OpenCV version (git branch):
```shell
(clone repo)
(sudo) docker build --build-arg OPENCV_VERSION="4.1.0" -t tegra_opencv:4.1.0 nano_build_opencv
```

Where `4.2.0` is any version of openCV from 2.2 to 4.2.0
(any valid OpenCV git branch or tag will also attempt to work, however the very old versions have not been tested to build and may require spript modifications.).


## Other --build-arg options:
```Dockerfile
# Performs tests:
ARG OPENCV_DO_TEST="FALSE"
# Number of cores to use to build (1 is recommend on Nano unless you have a swapfile mounted. More will use more memory)
# 8 is recommended on Xavier
ARG OPENCV_BUILD_JOBS="1"
```

