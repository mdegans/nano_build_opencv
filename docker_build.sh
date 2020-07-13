# this builds the same images as build.sh, just with 8 jobs

set -ex

# just change these to bump the version
readonly JETPACK_VERSION="r32.4.3"
readonly OPENCV_VERSION="master"

# build the image
docker build --pull \
    --build-arg OPENCV_BUILD_JOBS=$(nproc) \
    --build-arg JETPACK_VERSION=${JETPACK_VERSION} \
    --build-arg OPENCV_VERSION=${OPENCV_VERSION} \
    -t mdegans/tegra-opencv:jp-${JETPACK_VERSION}-cv-${OPENCV_VERSION} \
    -t mdegans/tegra-opencv:latest \
    . 2>&1 | tee build.log
