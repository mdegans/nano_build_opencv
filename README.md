# OpenCV build script for NVIDIA Jetson Nano

This script builds OpenCV from source on Jetson Nano.

Related thread on Nvidia developer forum 
[here](https://devtalk.nvidia.com/default/topic/1051133/jetson-nano/opencv-build-script/).

[How it Works](https://wiki.debian.org/QemuUserEmulation)

## Usage:
```shell
./build_opencv.sh
```

## Specifying an OpenCV version (git branch)
```shell
./build_opencv.sh 4.3.0
```

Where `4.3.0` is any version of openCV from 2.2 to 4.3.0
(any valid OpenCV git branch or tag will also attempt to work, however the very old versions have not been tested to build and may require spript modifications.).
