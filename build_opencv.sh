#!/usr/bin/env sh
# 2019 Michael Crawford

set -e

VERSION=4.1.0
JOBS=3

setup () {
    cd /tmp
    mkdir build_opencv
    cd build_opencv
}

git_source () {
    echo "Getting version $1 of opencv"
    git clone --branch $1 https://github.com/opencv/opencv.git
    git clone --branch $1 https://github.com/opencv/opencv_contrib.git
}

install_dependencies () {
    # open-cv has a lot of dependencies, but most can be found in the default
    # package repository or should already be installed (eg. CUDA).
    echo "Installing build dependencies."
    sudo apt-get update
    sudo apt-get install -y \
        build-essential \
        cmake \
        git \
        libavcodec-dev \
        libavformat-dev \
        libdc1394-22-dev \
        libgstreamer1.0-dev \
        libgtk2.0-dev \
        libjpeg-dev \
        libpng-dev \
        libswscale-dev \
        libtbb-dev \
        libtbb2 \
        libtiff-dev \
        libv4l-dev \
        pkg-config \
        python-dev \
        python-numpy
}

configure () {
    mkdir build
    cd build
    cmake -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_PERF_TESTS=OFF \
        -D CUDA_FAST_MATH=1 \
        -D OPENCV_EXTRA_MODULES_PATH=/tmp/build_opencv/opencv_contrib/modules \
        -D WITH_CUDA=ON \
        -D WITH_GSTREAMER=ON \
        -D WITH_LIBV4L=ON \
        ..
}

cleanup () {
    rm -rf /tmp/build_opencv
    # maybe remove build-deps here, but they usually come in handy
}


if [[ $# -eq 1 ]] ; then
    VERSION=$1
fi

setup
install_dependencies
git_source $(VERSION)
configure
make -j$(JOBS)
make test
sudo make install
cleanup

