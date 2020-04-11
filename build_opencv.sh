#!/usr/bin/env bash
# 2019 Michael de Gans

set -ex

# change default constants here:
readonly PREFIX=/usr/local  # install prefix, (can be ~/.local for a user install)
readonly DEFAULT_VERSION=4.2.0  # controls the default version (gets reset by the first argument)
readonly CPUS=$(nproc)  # controls the number of jobs

cleanup () {
# https://stackoverflow.com/questions/226703/how-do-i-prompt-for-yes-no-cancel-input-in-a-linux-shell-script
    while true ; do
        echo "Do you wish to remove temporary build files in /tmp/build_opencv ? "
        if ! [[ "$1" -eq "--test-warning" ]] ; then
            echo "(Doing so may make running tests on the build later impossible)"
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
    echo "Getting version '$1' of OpenCV"
    git clone --branch "$1" https://github.com/opencv/opencv.git
    git clone --branch "$1" https://github.com/opencv/opencv_contrib.git
}

install_dependencies () {
    # open-cv has a lot of dependencies, but most can be found in the default
    # package repository or should already be installed (eg. CUDA).
    echo "Installing build dependencies."
    sudo apt-get update
    sudo apt-get dist-upgrade -y --autoremove
    sudo apt-get install -y \
        build-essential \
        cmake \
        git \
        gfortran \
        libatlas-base-dev \
        libavcodec-dev \
        libavformat-dev \
        libavresample-dev \
        libcanberra-gtk3-module \
        libdc1394-22-dev \
        libeigen3-dev \
        libglew-dev \
        libgstreamer-plugins-base1.0-dev \
        libgstreamer-plugins-good1.0-dev \
        libgstreamer1.0-dev \
        libgtk-3-dev \
        libjpeg-dev \
        libjpeg8-dev \
        libjpeg-turbo8-dev \
        liblapack-dev \
        liblapacke-dev \
        libopenblas-dev \
        libpng-dev \
        libpostproc-dev \
        libswscale-dev \
        libtbb-dev \
        libtbb2 \
        libtesseract-dev \
        libtiff-dev \
        libv4l-dev \
        libxine2-dev \
        libxvidcore-dev \
        libx264-dev \
        pkg-config \
        python-dev \
        python-numpy \
        python3-dev \
        python3-numpy \
        python3-matplotlib \
        qv4l2 \
        v4l-utils \
        v4l2ucp \
        zlib1g-dev
}

configure () {
    local CMAKEFLAGS="
        -D CMAKE_LIBRARY_PATH=/usr/local/cuda/lib64/stubs
        -D BUILD_EXAMPLES=OFF
        -D BUILD_opencv_python2=ON
        -D BUILD_opencv_python3=ON
        -D CMAKE_BUILD_TYPE=RELEASE
        -D CMAKE_INSTALL_PREFIX=${PREFIX}
        -D CUDA_ARCH_BIN=5.3,6.2,7.2
        -D CUDA_ARCH_PTX=
        -D CUDA_FAST_MATH=ON
        -D EIGEN_INCLUDE_PATH=/usr/include/eigen3 
        -D ENABLE_NEON=ON
        -D OPENCV_ENABLE_NONFREE=ON
        -D OPENCV_EXTRA_MODULES_PATH=/tmp/build_opencv/opencv_contrib/modules
        -D OPENCV_GENERATE_PKGCONFIG=ON
        -D WITH_CUBLAS=ON
        -D WITH_CUDA=ON
        -D WITH_GSTREAMER=ON
        -D WITH_LIBV4L=ON
        -D WITH_OPENGL=ON"

    if ! [[ "$1" -eq "test" ]] ; then
        CMAKEFLAGS="
        ${CMAKEFLAGS}
        -D BUILD_PERF_TESTS=OFF
        -D BUILD_TESTS=OFF"
    fi

    echo "cmake flags: ${CMAKEFLAGS}"

    cd opencv
    mkdir build
    cd build
    cmake ${CMAKEFLAGS} ..
}

main () {

	echo "OPENCV_VERSION=${OPENCV_VERSION}"
	echo "OPENCV_DO_TEST=${OPENCV_DO_TEST}"
	echo "OPENCV_BUILD_JOBS=${OPENCV_BUILD_JOBS}"

    # prepare for the build:
    setup
    install_dependencies
    git_source ${OPENCV_VERSION}

    if [[ ${OPENCV_DO_TEST} == "TRUE" ]] ; then
        configure test
    else
        configure
    fi

    # start the build
    gosu builder make -j${OPENCV_BUILD_JOBS}

    if [[ ${OPENCV_DO_TEST} == "TRUE" ]] ; then
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
