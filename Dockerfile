# @NVIDIA: if you are reading this, a "latest" tag would be nice
FROM nvcr.io/nvidia/l4t-base:r32.3.1

### build argumements ###
# change these here or with --build-arg FOO="BAR" at build time
ARG OPENCV_VERSION="4.2.0"
ARG OPENCV_DO_TEST="FALSE"
# note: 8 jobs will fail on Nano. Try 1 instead.
ARG OPENCV_BUILD_JOBS="1"

### environment variables ###
# required for apt-get -y to work properly:
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /usr/local/src/build_opencv

COPY build_opencv.sh .

RUN /bin/bash build_opencv.sh ${OPENCV_VERSION}