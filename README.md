# OpenCV build script for Tegra

This script builds OpenCV from source on Tegra (Nano, NX, AGX, etc.).

Related thread on Nvidia developer forum 
[here](https://devtalk.nvidia.com/default/topic/1051133/jetson-nano/opencv-build-script/).

[How it Works](https://wiki.debian.org/QemuUserEmulation)

## Usage:
```shell
./build_opencv.sh
```

## Specifying an OpenCV version (git branch)
```shell
./build_opencv.sh 4.4.0
```

Where `4.4.0` is any version of openCV from 2.2 to 4.4.0
(any valid OpenCV git branch or tag will also attempt to work, however the very old versions have not been tested to build and may require spript modifications.).

**JetPack 4.4 NOTE:** the minimum version that will build correctly on JetPack 4.4 GA is 4.4.0. Prior versions of JetPack may need the CUDNN version adjusted (the `-D CUDNN_VERSION='8.0'` line can simply be removed).
