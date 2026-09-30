# OpenCV build script

[![build](https://github.com/mdegans/nano_build_opencv/actions/workflows/build.yml/badge.svg)](https://github.com/mdegans/nano_build_opencv/actions/workflows/build.yml)

This script builds OpenCV and the opencv_contrib modules from source, with
Python 3 bindings. It was written for Tegra (Jetson Nano, TX1/TX2, Xavier, Orin)
but works on any Debian or Ubuntu machine, x86_64 or aarch64, with or without
CUDA. It is tested in CI on Ubuntu 18.04, 20.04, 22.04 and 24.04, on x86_64
and arm64.

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
tests before installing (under Xvfb if there is no display). The script exits
non-zero if any test fails; `TEST_EXCLUDE` can skip known upstream failures.

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
| `PYTHON3`           | `python3` on `PATH`  | Interpreter to build the bindings for. It needs numpy; use `/usr/bin/python3` if you have pyenv/conda first on your `PATH`. |
| `CLEANUP`           | `ask`                | `yes`, `no` or `ask` whether to remove `BUILD_DIR` (when an old build exists, and after installing). Defaults to `no` when not run interactively. |
| `TEST_EXCLUDE`      |                      | Tests to skip in test mode, as a gtest filter, e.g. `"Media.audio/*:Highgui_GUI.*"`. |
| `EXTRA_CMAKE_FLAGS` |                      | Extra flags passed to cmake, e.g. `"-D WITH_QT=ON"`. |

cuDNN (and the CUDA DNN backend) is enabled automatically when its headers are
found.

## Jetson / JetPack

On a Jetson the CUDA architecture is picked from the SoC (Nano/TX1 5.3, TX2 6.2,
Xavier 7.2, Orin 8.7), and CUDA is found in `/usr/local/cuda` even if it isn't
on your `PATH`. The script also works when building without a GPU driver
(e.g. in a container), by linking against the CUDA stub library; set
`CUDA_ARCH_BIN` in that case, otherwise OpenCV builds for every architecture.

CI builds the script on Ubuntu 18.04 (JetPack 4) and 20.04 (JetPack 5) on
arm64, and does a CUDA 12.8 + cuDNN 9 build for Orin (`sm_87`). It has no Jetson
hardware or GPU, so nothing CUDA related is *run* in CI.

The CUDA version shipped with your JetPack limits which OpenCV versions will
build; for JetPack 4.4 the minimum is 4.4.0.

## Other distributions

On non-Debian distributions the dependencies are not installed automatically;
install them with your package manager, run with `INSTALL_DEPS=OFF`, and the
rest of the script will work.
