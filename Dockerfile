ARG JETPACK_VERSION="r32.4.2"

FROM registry.hub.docker.com/mdegans/l4t-base:${JETPACK_VERSION}

### build argumements ###
# change these here or with --build-arg FOO="BAR" at build time
ARG OPENCV_VERSION="4.3.0"
ARG OPENCV_DO_TEST="FALSE"
# note: 8 jobs will fail on Nano. Try 1 instead.
ARG OPENCV_BUILD_JOBS="1"
# required for apt-get -y to work properly:
ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /usr/local/src/build_opencv

COPY build_opencv.sh .

RUN /bin/bash build_opencv.sh
