#!/usr/bin/env bash
# 2019 Michael de Gans

set -ex

# change default constants here:
readonly PREFIX=/usr/local  # install prefix, (can be ~/.local for a user install)
readonly BUILD_TMP=/tmp/build_opencv

cleanup () {
    echo "REMOVING build files"
    rm -rf ${BUILD_TMP}

    echo "REMOVING build dependencies"
    apt-get purge -y --autoremove \
        gosu \
        build-essential \
        ca-certificates \
        cmake \
        git \
        cuda-compiler-10-2 \
        cuda-minimal-build-10-2 \
        cuda-libraries-dev-10-2 \
        libcudnn8-dev \
        python3-dev
    # there are probably more -dev packages that can be removed if the 
    # runtime packages are explicitly added below in install_dependencies
    # but the above ones I know offhand can be removed without breaking open_cv
    # TODO(mdegans): separate more build and runtime deps, purge build deps

    # this shaves about 20Mb off the image
    echo "REMOVING apt cache and lists"
    apt-get clean
    rm -rf /var/lib/apt/lists/*

    echo "REMOVING builder user and any owned files"
    deluser --remove-all-files builder
}

setup () {
    echo "CREATING new builder user to build opencv"
    adduser --system --group --no-create-home builder
    if [[ -d ${BUILD_TMP} ]] ; then
        echo "WARNING: It appears an existing build exists in /tmp/build_opencv"
        cleanup
    fi
    mkdir -p ${BUILD_TMP} && chown builder:builder ${BUILD_TMP}
    echo "CREATING symlink to /usr/local/cuda"
    ln -s /usr/local/cuda-10.0 /usr/local/cuda
    echo "ADDING /usr/local/cuda/bin to PATH"
    PATH=/usr/local/cuda/bin:$PATH
}

git_source () {
    cd ${BUILD_TMP}
    echo "CLONING version '$1' of OpenCV"
    gosu builder git clone --depth 1 --branch "$1" https://github.com/opencv/opencv.git
    gosu builder git clone --depth 1 --branch "$1" https://github.com/opencv/opencv_contrib.git
}

install_dependencies () {
    # open-cv has a lot of dependencies, but most can be found in the default
    # package repository or should already be installed (eg. CUDA).
    echo "Installing build dependencies."
    # well, shit, they fixed it, so we do this to get the certs temporarily
    mv /etc/apt/sources.list.d/nvidia-l4t-apt-source.list /etc/apt/
    apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates
    mv /etc/apt/nvidia-l4t-apt-source.list /etc/apt/sources.list.d
    apt-get update && apt-get install -y --no-install-recommends \
        gosu \
        cuda-compiler-10-2 \
        cuda-minimal-build-10-2 \
        cuda-libraries-dev-10-2 \
        libcudnn8-dev \
        build-essential \
        cmake \
        git \
        gfortran \
        libatlas-base-dev \
        libavcodec-dev \
        libavformat-dev \
        libavresample-dev \
        libeigen3-dev \
        libgstreamer-plugins-base1.0-dev \
        libgstreamer-plugins-good1.0-dev \
        libgstreamer1.0-dev \
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
        libx264-dev \
        pkg-config \
        python3-dev \
        python3-numpy \
        python3-pil \
        python3-matplotlib \
        v4l-utils \
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
        -D WITH_CUDNN=ON
        -D CUDNN_VERSION='8.0'
        -D OPENCV_DNN_CUDA=ON
        -D WITH_GSTREAMER=ON
        -D WITH_LIBV4L=ON
        -D WITH_OPENGL=ON"

    if [[ ${OPENCV_DO_TEST} != "TRUE" ]]; then
        CMAKEFLAGS="
        ${CMAKEFLAGS}
        -D BUILD_PERF_TESTS=OFF
        -D BUILD_TESTS=OFF"
    fi

    echo "cmake flags: ${CMAKEFLAGS}"

    cd ${BUILD_TMP}/opencv
    mkdir build && chown builder:builder build
    cd build
    gosu builder cmake ${CMAKEFLAGS} ..
}

main () {

    if [[ ! -f "/.dockerenv" ]]; then
        echo "this script will break your system if run outside docker" 1>&2
        exit 1
    fi

    echo "OPENCV_VERSION=${OPENCV_VERSION}"
    echo "OPENCV_DO_TEST=${OPENCV_DO_TEST}"
    echo "OPENCV_BUILD_JOBS=${OPENCV_BUILD_JOBS}"

    # prepare for the build:
    setup
    install_dependencies
    git_source ${OPENCV_VERSION}

    # configure the build
    configure

    # start the build
    gosu builder make -j${OPENCV_BUILD_JOBS}

    if [[ ${OPENCV_DO_TEST} == "TRUE" ]] ; then
        echo "MAKING tests"
        gosu builder make test  # (make and) run the tests
    fi

    make install

    cleanup
}

main "$@"
