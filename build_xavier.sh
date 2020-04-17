# this builds the same images as build.sh, just with 8 jobs
exec docker build --build-arg OPENCV_BUILD_JOBS=8 -t mdegans/tegra-opencv:latest . 2>&1 | tee build.log