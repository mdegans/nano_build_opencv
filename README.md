# OpenCV build script for NVIDIA Jetson Nano

This script builds OpenCV from source on Jetson Nano.

This script is untested and expected it to break. Please report breakage 
[here](https://github.com/mdegans/nano_build_opencv/issues).

Related thread on Nvidia developer forum 
[here](https://devtalk.nvidia.com/default/topic/1051133/jetson-nano/opencv-build-script/).

## Usage:
```shell
sh build_opencv.sh
```

## Specifying an OpenCV version (git branch)
```shell
sh build_opencv.sh 4.0.0
```

## Running Tests
Becuase the tests consume so much memory, it's recommended to mount an external 
swapfile via usb3 before doing so as otherwise you will swap from your microsd 
card and that will shorten it's lifespan artificially. Once that's done you can

```shell
sh build_opencv.sh 4.0.0 test
```

Where `4.0.0` is any version of openCV from 2.2 to 4.1.0
(any valid OpenCV git branch or tag will also work).