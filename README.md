# OpenCV build script for NVIDIA Jetson Nano

This is the Docker branch. A build is available
[here on Docker Hub](https://hub.docker.com/r/mdegans/tegra-opencv).

## Running pre-built image:
```shell
(sudo) docker run --runtime nvidia -it --rm mdegans/tegra-opencv:latest
```

## Building:

With script on Nano/tx1/tx2:
```shell
(sudo) ./build.sh
```
With script on Xavier:
```shell
(sudo) ./build_xavier.sh
```
... Or manually using the docker build and the dockerfiles as usual. Examples below.

## Specifying an OpenCV version (git branch):
```shell
(clone repo)
git checkout docker
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

