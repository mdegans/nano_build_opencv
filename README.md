# OpenCV build script for NVIDIA Jetson Nano

This script is untested and expected it to break. Please report breakage [here]
(https://github.com/mdegans/nano_build_opencv/issues).

This script builds OpenCV from source on Jetson Nano.

## Usage:
```shell
git clone nano_build_opencv
sh build_opencv.sh
```

## Specifying a git branch (version)
```shell
git clone https://github.com/mdegans/nano_build_opencv.git
cd nano_build_opencv
sh build_opencv.sh 4.0.0
```

Where `4.0.0` is any version of openCV from 2.2 to 4.1.0
(any valid OpenCV git branch or tag will also work).