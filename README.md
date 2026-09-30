# OpenCV build script

[![build](https://github.com/mdegans/nano_build_opencv/actions/workflows/build.yml/badge.svg)](https://github.com/mdegans/nano_build_opencv/actions/workflows/build.yml)

This script builds OpenCV and the opencv_contrib modules from source, with
Python 3 bindings. It was written for Tegra (Jetson Nano, TX1/TX2, Xavier, Orin)
but works on any Debian or Ubuntu machine, x86_64 or aarch64, with or without
CUDA. It is tested in CI on Ubuntu 22.04 and 24.04 (x86_64 and arm64).

Related thread on Nvidia developer forum
[here](https://devtalk.nvidia.com/default/topic/1051133/jetson-nano/opencv-build-script/).

## Usage:
```shell
./build_opencv.sh
```

## Specifying an OpenCV version (git branch)
```shell
./build_opencv.sh 4.14.0
```

Where `4.14.0` is any OpenCV git tag or branch (the default is 4.14.0). Very old
versions have not been tested to build and may require script modifications.

## Running the tests

```shell
./build_opencv.sh 4.14.0 test
```

This also fetches the test data from
[opencv_extra](https://github.com/opencv/opencv_extra) and runs the accuracy
tests before installing. The script exits non-zero if any test fails.

## Options

Set these as environment variables, e.g. `PREFIX=~/.local ./build_opencv.sh`.

| Variable            | Default              | Description |
|---------------------|----------------------|-------------|
| `PREFIX`            | `/usr/local`         | Install prefix. `sudo` is only used if it isn't writable. |
| `BUILD_DIR`         | `/tmp/build_opencv`  | Where sources are fetched and built. |
| `JOBS`              | auto                 | Parallel build jobs. By default based on CPU count *and* RAM + swap, so a Nano won't run out of memory. |
| `WITH_CUDA`         | `auto`               | `ON`, `OFF`, or `auto` (on if `nvcc` is found, including in `/usr/local/cuda/bin`). |
| `CUDA_ARCH_BIN`     | auto                 | Compute capabilities, e.g. `8.7`. Detected from the Jetson SoC or `nvidia-smi`, otherwise OpenCV detects the local GPU. |
| `WITH_CONTRIB`      | `ON`                 | Build the opencv_contrib modules (including nonfree). |
| `INSTALL_DEPS`      | `ON`                 | Install build dependencies with `apt-get`. |
| `CLEANUP`           | `ask`                | `yes`, `no` or `ask` whether to remove `BUILD_DIR` (when an old build exists, and after installing). Defaults to `no` when not run interactively. |
| `EXTRA_CMAKE_FLAGS` |                      | Extra flags passed to cmake, e.g. `"-D WITH_QT=ON"`. |

cuDNN (and the CUDA DNN backend) is enabled automatically when its headers are
found.

**JetPack NOTE:** the CUDA version shipped with your JetPack limits which
OpenCV versions will build; for JetPack 4.4 the minimum is 4.4.0. On
non-Debian distributions the dependencies are not installed automatically;
install them with your package manager and the rest of the script will work.
