#!/bin/bash

set -ex

# just change these to bump the version
readonly JETPACK_VERSION="r32.5.0"
readonly OPENCV_VERSION="4.5.1"

# build the image
docker build --pull \
    --build-arg OPENCV_BUILD_JOBS=$(nproc) \
    --build-arg JETPACK_VERSION=${JETPACK_VERSION} \
    --build-arg OPENCV_VERSION=${OPENCV_VERSION} \
    -t mdegans/tegra-opencv:jp-${JETPACK_VERSION}-cv-${OPENCV_VERSION} \
    -t mdegans/tegra-opencv:latest \
    . 2>&1 | tee build.log
