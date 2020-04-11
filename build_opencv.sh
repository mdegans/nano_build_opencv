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
		cmake \
		git \
		python3-dev
	# there are probably more -dev packages that can be removed if the 
	# runtime packages are explicitly added below in install_dependencies
	# but the above ones I know offhand can be removed without breaking open_cv
	# TODO(mdegans): separate more build and runtime deps, purge build deps

	# this shaves about 20Mb off the image
	echo "REMOVING apt cache and lists"
	apt-get clean
	rm /var/lib/apt/lists/*

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
}

git_source () {
	cd ${BUILD_TMP}
    echo "CLONING version '$1' of OpenCV"
    gosu builder git clone --branch "$1" https://github.com/opencv/opencv.git
    gosu builder git clone --branch "$1" https://github.com/opencv/opencv_contrib.git
}

install_dependencies () {
    # open-cv has a lot of dependencies, but most can be found in the default
    # package repository or should already be installed (eg. CUDA).
    echo "Installing build dependencies."
    apt-get update && apt-get install -y --no-install-recommends \
        gosu \
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
        python3-dev \
        python3-numpy \
		python3-pil \
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
    mkdir build && chown builder:builder build
    cd build
    gosu builder cmake ${CMAKEFLAGS} ..
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
        gosu builder make test  # (make and) run the tests
    fi

    # avoid a sudo make install (and root owned files in ~) if $PREFIX is writable
    if [[ -w ${PREFIX} ]] ; then
        make install
    else
        sudo make install
    fi

    cleanup --test-warning

    cleanup
}

main "$@"
