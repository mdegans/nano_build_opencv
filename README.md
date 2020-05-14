# OpenCV build script for NVIDIA Jetson Nano

This is the Docker branch. A build is available
[here on Docker Hub](https://hub.docker.com/r/mdegans/tegra-opencv).

## Running pre-built image:
```shell
(sudo) docker run --runtime nvidia -it --rm mdegans/tegra-opencv:latest
```

## Building:

On all tegra boards:
```shell
(sudo) ./docker_build.sh
```

## Specifying an OpenCV version (git branch):

Just change JETPACK_VERSION and OPENCV_VERSION as needed in the docker_build.sh

## Other --build-arg options:

For those who want to modify the Dockerfile or use other `--build-arg` options, there are these:

```Dockerfile
# Performs tests:
ARG OPENCV_DO_TEST="FALSE"
# Number of cores to use to build (1 is recommend on Nano unless you have a swapfile mounted. More will use more memory)
# 8 is recommended on Xavier
ARG OPENCV_BUILD_JOBS="1"
```

