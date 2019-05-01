#!/usr/bin/env sh
# 2019 Michael de Gans

set -e

# Constants (change these if you wish)

VERSION=4.1.0  # controls the default version
JOBS=3  # controls the number of jobs (make -j 3)

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
    while true; do
        read -p "Do you wish to remove temporary build files in /tmp/build_opencv ? " yn
        case ${yn} in
            [Yy]* ) rm -rf /tmp/build_opencv ; break;;
            [Nn]* ) exit;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# parse arguments
if [[ $# -gt 0 ]] ; then
    VERSION=$1
fi

if [[ $# -gt 1 ]] && [[ $2 -eq "test" ]] ; then
    DO_TEST=1
fi

# prepare for the build:
setup
install_dependencies
git_source ${VERSION}
configure

# start the build
make -j${JOBS}

# ifdef DO_TEST ; then
if [[ ${DO_TEST} ]]; then
    make test  # (make and) run the tests
fi

sudo make install
cleanup

