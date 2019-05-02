#!/usr/bin/env bash
# 2019 Michael de Gans

set -e

# change default constants here:
readonly PREFIX=/usr/local  # install prefix, (can be ~/.local for a user install)
readonly DEFAULT_VERSION=4.1.0  # controls the default version (gets reset by the first argument)
readonly JOBS=1  # controls the number of jobs
# (recommend leaving JOBS to 1 since each  `cc1plus` process towards the end of
# the build consumes close to 1.7G memory) If you have an external drive connected
# as swap you can increase this and parts will build faster, while others might
# build slower. This is currently untested

cleanup () {
# https://stackoverflow.com/questions/226703/how-do-i-prompt-for-yes-no-cancel-input-in-a-linux-shell-script
    while true ; do
        echo "Do you wish to remove temporary build files in /tmp/build_opencv ? "
        if ! [[ "$1" -eq "--test-warning" ]] ; then
            "(Doing so may make running tests on the build later impossible)"
        fi
        read -p "Y/N " yn
        case ${yn} in
            [Yy]* ) rm -rf /tmp/build_opencv ; break;;
            [Nn]* ) exit ;;
            * ) echo "Please answer yes or no." ;;
        esac
    done
}

setup () {
    cd /tmp
    if [[ -d "build_opencv" ]] ; then
        echo "It appears an existing build exists in /tmp/build_opencv"
        cleanup
    fi
    mkdir build_opencv
    cd build_opencv
}

git_source () {
    echo "Getting version '$1' of opencv"
    git clone --branch "$1" https://github.com/opencv/opencv.git
    git clone --branch "$1" https://github.com/opencv/opencv_contrib.git
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
        libavresample-dev \
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
        python-numpy \
        python3-dev \
        python3-numpy
}

configure () {
    cd opencv
    mkdir build
    cd build
    cmake -D CMAKE_BUILD_TYPE=Release \
        -D BUILD_EXAMPLES=OFF \
        -D BUILD_opencv_python2=ON \
        -D BUILD_opencv_python3=ON \
        -D BUILD_PERF_TESTS=OFF \
        -D BUILD_TESTS=OFF \
        -D CMAKE_INSTALL_PREFIX=${PREFIX} \
        -D CUDA_ARCH_BIN="5.3" \
        -D CUDA_ARCH_PTX="" \
        -D CUDA_FAST_MATH=1 \
        -D OPENCV_EXTRA_MODULES_PATH=/tmp/build_opencv/opencv_contrib/modules \
        -D WITH_CUDA=ON \
        -D WITH_GSTREAMER=ON \
        -D WITH_LIBV4L=ON \
        ..
}

main () {

    local VER=${DEFAULT_VERSION}

    # parse arguments
    if [[ "$#" -gt 0 ]] ; then
        VER="$1"  # override the version
    fi

    if [[ "$#" -gt 1 ]] && [[ "$2" -eq "test" ]] ; then
        DO_TEST=1
    fi

    # prepare for the build:
    setup
    install_dependencies
    git_source ${VER}
    configure

    # start the build
    make -j${JOBS}

    # ifdef DO_TEST ; then
    if [[ ${DO_TEST} ]] ; then
        make test  # (make and) run the tests
    fi

    # avoid a sudo make install (and root owned files in ~) if $PREFIX is writable
    if [[ -w ${PREFIX} ]] ; then
        make install
    else
        sudo make install
    fi

    cleanup --test-warning

}

main "$@"