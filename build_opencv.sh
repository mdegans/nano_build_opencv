#!/usr/bin/env bash
# 2019 Michael de Gans
#
# Build OpenCV (with opencv_contrib) from source.
#
# Usage: ./build_opencv.sh [VERSION] [test]
#
# Works on Jetson (Nano, TX1/TX2, Xavier, Orin) as well as ordinary x86_64 and
# aarch64 machines running Debian or Ubuntu. CUDA is used when it is found.
#
# Most behaviour can be tweaked with environment variables, for example:
#   PREFIX=~/.local CLEANUP=no ./build_opencv.sh 4.14.0
#
# PREFIX         install prefix (default: /usr/local)
# BUILD_DIR      where sources are fetched and built (default: /tmp/build_opencv)
# JOBS           parallel build jobs (default: based on CPU count and memory)
# WITH_CUDA      auto, ON or OFF (default: auto, ON if nvcc is found)
# CUDA_ARCH_BIN  CUDA compute capabilities to build for, eg. "8.7"
#                (default: detected from the Jetson model or local GPU)
# WITH_CONTRIB   ON or OFF, build the opencv_contrib modules (default: ON)
# PYTHON3        python interpreter to build bindings for (default: python3
#                on the PATH). It needs numpy and its development headers.
# INSTALL_DEPS   ON or OFF, install build dependencies with apt (default: ON)
# CLEANUP        ask, yes or no, whether to remove BUILD_DIR when an old build
#                is found and after installing (default: ask if interactive,
#                otherwise no)
# EXTRA_CMAKE_FLAGS  extra flags passed as-is to cmake

set -eo pipefail

# change default constants here:
readonly DEFAULT_VERSION=4.14.0  # controls the default version (gets reset by the first argument)
readonly PREFIX=${PREFIX:-/usr/local}  # install prefix, (can be ~/.local for a user install)
readonly BUILD_DIR=${BUILD_DIR:-/tmp/build_opencv}
readonly WITH_CONTRIB=${WITH_CONTRIB:-ON}
readonly INSTALL_DEPS=${INSTALL_DEPS:-ON}
PYTHON3=${PYTHON3:-}
WITH_CUDA=${WITH_CUDA:-auto}
CUDA_ARCH_BIN=${CUDA_ARCH_BIN:-}
if [[ -z "${CLEANUP}" ]] ; then
    if [[ -t 0 ]] ; then CLEANUP=ask ; else CLEANUP=no ; fi
fi

# only use sudo when we need to (and when it exists, eg. not in a container)
SUDO=""
if [[ $(id -u) -ne 0 ]] ; then
    SUDO=sudo
fi

default_jobs () {
    # Pick the number of jobs from the cpu count *and* the memory available.
    # A Nano (4 cores, 4GB) will run out of memory towards the end of the build
    # with 4 jobs and no swap. Compiling CUDA code is especially hungry.
    local cpus mem_kb swap_kb per_job_kb jobs
    cpus=$(nproc)
    mem_kb=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)
    swap_kb=$(awk '/^SwapTotal:/ {print $2}' /proc/meminfo 2>/dev/null || echo 0)
    if [[ "${WITH_CUDA}" == "ON" ]] ; then
        per_job_kb=$((2 * 1024 * 1024))
    else
        per_job_kb=$((1536 * 1024))
    fi
    jobs=$(( (mem_kb + swap_kb) / per_job_kb ))
    if [[ ${jobs} -gt ${cpus} ]] ; then jobs=${cpus} ; fi
    if [[ ${jobs} -lt 1 ]] ; then jobs=1 ; fi
    echo "${jobs}"
}

cleanup () {
    local answer=${CLEANUP}
    while [[ "${answer}" == "ask" ]] ; do
        echo "Do you wish to remove temporary build files in ${BUILD_DIR} ? "
        if [[ "$1" == "--test-warning" ]] ; then
            echo "(Doing so may make running tests on the build later impossible)"
        fi
        read -r -p "Y/N " yn
        case ${yn} in
            [Yy]* ) answer=yes ;;
            [Nn]* ) answer=no ;;
            * ) echo "Please answer yes or no." ;;
        esac
    done
    if [[ "${answer}" == "yes" ]] ; then
        rm -rf "${BUILD_DIR}"
    fi
}

setup () {
    if [[ -d "${BUILD_DIR}" ]] ; then
        echo "It appears an existing build exists in ${BUILD_DIR}"
        cleanup
        if [[ -d "${BUILD_DIR}" ]] ; then
            echo "Not overwriting it. Remove it, or set BUILD_DIR, and try again."
            exit 1
        fi
    fi
    mkdir -p "${BUILD_DIR}"
    cd "${BUILD_DIR}"
}

git_source () {
    echo "Getting version '$1' of OpenCV"
    git clone --depth 1 --branch "$1" https://github.com/opencv/opencv.git
    if [[ "${WITH_CONTRIB}" == "ON" ]] ; then
        git clone --depth 1 --branch "$1" https://github.com/opencv/opencv_contrib.git
    fi
    if [[ "$2" == "test" ]] ; then
        # test data, without this most tests fail
        git clone --depth 1 --branch "$1" https://github.com/opencv/opencv_extra.git
    fi
}

install_dependencies () {
    # open-cv has a lot of dependencies, but most can be found in the default
    # package repository or should already be installed (eg. CUDA).
    if [[ "${INSTALL_DEPS}" != "ON" ]] ; then
        echo "Skipping dependency installation."
        return
    fi
    if ! command -v apt-get > /dev/null ; then
        echo "apt-get not found. Please install the build dependencies manually"
        echo "(a compiler, cmake, git, python3 with numpy, gtk3, ffmpeg, ...)."
        return
    fi
    echo "Installing build dependencies."
    export DEBIAN_FRONTEND=noninteractive
    ${SUDO} apt-get update
    # Packages come and go between Ubuntu releases, so only ask for the ones
    # this release actually has. "a|b" means the first of a or b that is
    # available. Nothing in the list is strictly required except the
    # compiler, cmake, git and python3.
    local wanted=(
        build-essential
        ca-certificates
        cmake
        git
        gfortran
        libavcodec-dev
        libavformat-dev
        libcanberra-gtk3-module
        "libdc1394-dev|libdc1394-22-dev"
        libeigen3-dev
        libglew-dev
        libgstreamer-plugins-base1.0-dev
        libgstreamer-plugins-good1.0-dev
        libgstreamer1.0-dev
        libgtk-3-dev
        libjpeg-dev
        liblapack-dev
        liblapacke-dev
        libopenblas-dev
        libpng-dev
        libpostproc-dev
        libswscale-dev
        libtbb-dev
        libtesseract-dev
        libtiff-dev
        libv4l-dev
        libxine2-dev
        libxvidcore-dev
        libx264-dev
        pkg-config
        python3-dev
        python3-numpy
        python3-matplotlib
        qv4l2
        v4l-utils
        zlib1g-dev
    )
    local available=() entry pkg
    for entry in "${wanted[@]}" ; do
        for pkg in ${entry//|/ } ; do
            if [[ -n "$(apt-cache policy "${pkg}" 2>/dev/null | awk '/Candidate:/ && $2 != "(none)"')" ]] ; then
                available+=("${pkg}")
                continue 2
            fi
        done
        echo "Package ${entry} is not available here, skipping it."
    done
    ${SUDO} apt-get install -y --no-install-recommends "${available[@]}"
}

find_cuda () {
    # JetPack and the CUDA packages install to /usr/local/cuda but don't
    # always put it on the PATH.
    if [[ -x /usr/local/cuda/bin/nvcc ]] && ! command -v nvcc > /dev/null ; then
        export PATH="/usr/local/cuda/bin:${PATH}"
    fi
    if [[ "${WITH_CUDA}" == "auto" ]] ; then
        if command -v nvcc > /dev/null ; then
            WITH_CUDA=ON
        else
            WITH_CUDA=OFF
        fi
    fi
    echo "CUDA: ${WITH_CUDA}"
}

detect_cuda_arch () {
    # Jetson modules, by SoC
    if [[ -r /proc/device-tree/compatible ]] ; then
        case $(tr '\0' ' ' < /proc/device-tree/compatible) in
            *tegra210*) echo "5.3" ; return ;;  # Nano, TX1
            *tegra186*) echo "6.2" ; return ;;  # TX2
            *tegra194*) echo "7.2" ; return ;;  # Xavier NX, AGX Xavier
            *tegra234*) echo "8.7" ; return ;;  # Orin
        esac
    fi
    # discrete GPUs
    if command -v nvidia-smi > /dev/null ; then
        nvidia-smi --query-gpu=compute_cap --format=csv,noheader 2>/dev/null \
            | sort -u | paste -sd, -
    fi
}

have_cudnn () {
    local include_dirs=(/usr/include /usr/include/*-linux-gnu /usr/local/cuda/include)
    local dir
    for dir in "${include_dirs[@]}" ; do
        if compgen -G "${dir}/cudnn*.h" > /dev/null ; then
            return 0
        fi
    done
    return 1
}

find_python () {
    if [[ -z "${PYTHON3}" ]] ; then
        PYTHON3=$(command -v python3 || true)
    fi
    if [[ -z "${PYTHON3}" ]] || ! "${PYTHON3}" -c "import numpy" > /dev/null 2>&1 ; then
        echo "WARNING: '${PYTHON3:-python3}' can't import numpy, so the Python"
        echo "bindings will not be built. Set PYTHON3 to an interpreter with numpy"
        echo "(eg. PYTHON3=/usr/bin/python3) if you want them."
    fi
    echo "Python: ${PYTHON3}"
}

configure () {
    local CMAKEFLAGS=(
        -D BUILD_EXAMPLES=OFF
        -D BUILD_opencv_python3=ON
        -D PYTHON3_EXECUTABLE="${PYTHON3}"
        -D PYTHON_DEFAULT_EXECUTABLE="${PYTHON3}"
        -D CMAKE_BUILD_TYPE=RELEASE
        -D CMAKE_INSTALL_PREFIX="${PREFIX}"
        -D OPENCV_GENERATE_PKGCONFIG=ON
        -D WITH_GSTREAMER=ON
        -D WITH_LIBV4L=ON
        -D WITH_OPENGL=ON
        -D WITH_TBB=ON
    )

    if [[ "${WITH_CONTRIB}" == "ON" ]] ; then
        CMAKEFLAGS+=(
            -D OPENCV_ENABLE_NONFREE=ON
            -D OPENCV_EXTRA_MODULES_PATH="${BUILD_DIR}/opencv_contrib/modules"
        )
    fi

    if [[ "${WITH_CUDA}" == "ON" ]] ; then
        CMAKEFLAGS+=(
            -D WITH_CUDA=ON
            -D WITH_CUBLAS=ON
            -D CUDA_FAST_MATH=ON
            -D CUDA_ARCH_PTX=
        )
        if [[ -z "${CUDA_ARCH_BIN}" ]] ; then
            CUDA_ARCH_BIN=$(detect_cuda_arch)
        fi
        if [[ -n "${CUDA_ARCH_BIN}" ]] ; then
            CMAKEFLAGS+=(-D CUDA_ARCH_BIN="${CUDA_ARCH_BIN}")
        else
            # let OpenCV figure out what GPU is in this machine
            CMAKEFLAGS+=(-D CUDA_GENERATION=Auto)
        fi
        # libcuda.so comes with the driver, not the toolkit. When building on a
        # machine without the driver (eg. in a container) link to the stub.
        if ! ldconfig -p | grep -q "libcuda.so " && \
                [[ -e /usr/local/cuda/lib64/stubs/libcuda.so ]] ; then
            echo "libcuda.so not found, linking against the CUDA stub library."
            CMAKEFLAGS+=(-D CUDA_CUDA_LIBRARY=/usr/local/cuda/lib64/stubs/libcuda.so)
        fi
        if have_cudnn ; then
            CMAKEFLAGS+=(-D WITH_CUDNN=ON -D OPENCV_DNN_CUDA=ON)
        else
            echo "cuDNN not found, the DNN module will not use CUDA."
        fi
    else
        CMAKEFLAGS+=(-D WITH_CUDA=OFF)
    fi

    if [[ "$1" == "test" ]] ; then
        CMAKEFLAGS+=(
            -D BUILD_TESTS=ON
            -D BUILD_PERF_TESTS=OFF
        )
    else
        CMAKEFLAGS+=(
            -D BUILD_TESTS=OFF
            -D BUILD_PERF_TESTS=OFF
        )
    fi

    # shellcheck disable=SC2206  # word splitting is intended
    CMAKEFLAGS+=(${EXTRA_CMAKE_FLAGS})

    echo "cmake flags: ${CMAKEFLAGS[*]}"

    cd "${BUILD_DIR}/opencv"
    mkdir build
    cd build
    cmake "${CMAKEFLAGS[@]}" .. 2>&1 | tee -a configure.log
}

run_tests () {
    # Accuracy tests only. These need the data from opencv_extra, and a few
    # tests are known to be flaky or hardware dependent upstream, so failures
    # are reported but don't stop the install.
    export OPENCV_TEST_DATA_PATH="${BUILD_DIR}/opencv_extra/testdata"
    if ctest --output-on-failure 2>&1 | tee -a test.log ; then
        echo "All tests passed."
    else
        echo "Some tests failed, see ${BUILD_DIR}/opencv/build/test.log"
        TESTS_FAILED=1
    fi
}

main () {

    local VER=${DEFAULT_VERSION}

    # parse arguments
    if [[ -n "$1" ]] ; then
        VER="$1"  # override the version
    fi

    local DO_TEST=""
    if [[ "$#" -gt 1 ]] && [[ "$2" == "test" ]] ; then
        DO_TEST="test"
    fi

    # prepare for the build:
    setup
    install_dependencies
    git_source "${VER}" "${DO_TEST}"
    find_cuda
    find_python

    local JOBS=${JOBS:-$(default_jobs)}
    echo "Building with ${JOBS} jobs."

    configure "${DO_TEST}"

    # start the build
    cmake --build . -- -j"${JOBS}" 2>&1 | tee -a build.log

    if [[ -n "${DO_TEST}" ]] ; then
        run_tests
    fi

    # avoid a sudo make install (and root owned files in ~) if $PREFIX is writable
    mkdir -p "${PREFIX}" 2>/dev/null || true
    if [[ -w ${PREFIX} ]] ; then
        cmake --build . --target install 2>&1 | tee -a install.log
    else
        ${SUDO} cmake --build . --target install 2>&1 | tee -a install.log
    fi
    # refresh the linker cache for system-wide installs
    if [[ "${PREFIX}" != "${HOME}"* ]] ; then
        ${SUDO} ldconfig || true
    fi

    echo "OpenCV ${VER} installed to ${PREFIX}"

    cleanup --test-warning

    if [[ -n "${TESTS_FAILED}" ]] ; then
        exit 1
    fi
}

main "$@"
