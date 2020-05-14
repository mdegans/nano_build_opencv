# this builds the same images as build.sh, just with 8 jobs

set -ex

# just change these to bump the version
readonly JETPACK_VERSION="r32.4.2"
readonly OPENCV_VERSION="4.3.0"

# build the image
docker build \
    --build-arg OPENCV_BUILD_JOBS=$(nproc) \
    --build-arg JETPACK_VERSION=${JETPACK_VERSION} \
    --build-arg OPENCV_VERSION=${OPENCV_VERSION} \
    -t mdegans/tegra-opencv:jp-${JETPACK_VERSION}-cv-${OPENCV_VERSION} \
    . 2>&1 | tee build.log
# tag it as latest
docker tag mdegans/tegra-opencv:jp-${JETPACK_VERSION}-cv-${OPENCV_VERSION} mdegans/tegra-opencv:latest
