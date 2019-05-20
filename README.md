# OpenCV build script for NVIDIA Jetson Nano

This script builds OpenCV from source on Jetson Nano.

Related thread on Nvidia developer forum 
[here](https://devtalk.nvidia.com/default/topic/1051133/jetson-nano/opencv-build-script/).

## Usage:
```shell
./build_opencv.sh $1 $2
```

where:
- __$1__ optional argument: number or tag of OpenCV you want to attempt to build
  (__default 4.1.0__)
- __$2__ optional argument: if "test", runs the test suite (see notes below on that)

## Specifying an OpenCV version (git branch)
```shell
./build_opencv.sh 4.0.0
```

Where `4.0.0` is any version of openCV from 2.2 to 4.1.0
(any valid OpenCV git branch or tag will also work).
