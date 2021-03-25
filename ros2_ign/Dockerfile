
# TODO: Dockerfile - Replace ros2_ign with a multi-stage build of ROS 2 and Ignition images
# TODO: Allows specifying argument and/or parent image for CUDA/non-CUDA systems

# TODO: Replace parent CUDA image with something much more sensible...
ARG PARENT_IMAGE=nvidia/cuda:11.0.3-cudnn8-devel-ubuntu20.04
FROM ${PARENT_IMAGE}

# Enable OpenGl for ignition camera sensors (required to create context)
COPY --from=nvidia/opengl:1.2-glvnd-runtime-ubuntu20.04 /usr/local /usr/local
ENV NVIDIA_VISIBLE_DEVICES ${NVIDIA_VISIBLE_DEVICES:-all}
ENV NVIDIA_DRIVER_CAPABILITIES ${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}graphics

### Use bash by default
SHELL ["/bin/bash", "-c"]

### Setup timezone (in order to prevent interactive install)
ARG TIMEZONE=Europe/Copenhagen
ARG DEBIAN_FRONTEND=noninteractive
RUN rm -f /etc/localtime && \
    ln -s /usr/share/zoneinfo/"${TIMEZONE}" /etc/localtime && \
    apt-get update && \
    apt-get install -yq --no-install-recommends \
        locales \
        locales-all \
        tzdata && \
    rm -rf /var/lib/apt/lists/*

### Install toolchain
ARG PYTHON3_VERSION=3.8
RUN apt-get update && \
    apt-get install -yq --no-install-recommends \
        git \
        wget \
        curl \
        cmake \
        gnupg2 \
        apt-utils \
        lsb-release \
        build-essential \
        software-properties-common \
        python3-pip \
        python3-wheel \
        python${PYTHON3_VERSION} \
        python${PYTHON3_VERSION}-dev \
        libpython${PYTHON3_VERSION}-dev \
        nano && \
    rm -rf /var/lib/apt/lists/*

### Set workspace directory
ENV ROS2_IGN_WS=/root/ros2_ign
WORKDIR ${ROS2_IGN_WS}

### ROS 2
ARG ROS2_DISTRO=foxy
ENV ROS2_DISTRO=${ROS2_DISTRO}
## Install binaries
RUN sh -c 'echo "deb [arch=$(dpkg --print-architecture)] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros2-latest.list' && \
    curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add - && \
    apt-get update && \
    apt-get install -yq --no-install-recommends \
        ros-${ROS2_DISTRO}-ros-base && \
    pip3 install \
        argcomplete && \
    apt-get install -yq --no-install-recommends \
        python3-colcon-common-extensions \
        python3-vcstool \
        python3-rosdep && \
    rosdep init && \
    rosdep update && \
    rm -rf /var/lib/apt/lists/*
## Build from source
# TODO: Build ROS 2 from source

### Ignition
ARG IGNITION_VERSION=edifice
ENV IGNITION_VERSION=${IGNITION_VERSION}
# ## Install binaries
# RUN sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" > /etc/apt/sources.list.d/gazebo-stable.list' && \
#     sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-prerelease $(lsb_release -cs) main" > /etc/apt/sources.list.d/gazebo-prerelease.list' && \
#     sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-nightly $(lsb_release -cs) main" > /etc/apt/sources.list.d/gazebo-nightly.list' && \
#     wget http://packages.osrfoundation.org/gazebo.key -O - | apt-key add - && \
#     apt-get update && \
#     apt-get install -yq --no-install-recommends \
#         ignition-${IGNITION_VERSION} && \
#     rm -rf /var/lib/apt/lists/*
## Build from source
RUN mkdir -p ${ROS2_IGN_WS}/ign_${IGNITION_VERSION}/src  && \
    cd ${ROS2_IGN_WS}/ign_${IGNITION_VERSION}/src && \
    wget https://raw.githubusercontent.com/ignition-tooling/gazebodistro/master/collection-${IGNITION_VERSION}.yaml && \
    vcs import < collection-${IGNITION_VERSION}.yaml && \
    sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable `lsb_release -cs` main" > /etc/apt/sources.list.d/gazebo-stable.list' && \
    wget http://packages.osrfoundation.org/gazebo.key -O - | apt-key add - && \
    apt-get update && \
    apt -y install \
        $(sort -u $(find . -iname 'packages-'`lsb_release -cs`'.apt' -o -iname 'packages.apt' | grep -v '/\.git/') | sed '/ignition\|sdf/d' | tr '\n' ' ') && \
    rm -rf /var/lib/apt/lists/* && \
    cd ${ROS2_IGN_WS}/ign_${IGNITION_VERSION} && \
    colcon build --merge-install --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release --cmake-args -DBUILD_TESTING=OFF


## Build ROS 2 - Ignition bridge
# TODO: Build ROS 2 - Ignition (bridge) from source
RUN mkdir -p ${ROS2_IGN_WS}/ros2_ign/src && \
    cd ${ROS2_IGN_WS}/ros2_ign/src && \
    git clone https://github.com/osrf/ros_ign.git -b ros2 && \
    cd ${ROS2_IGN_WS}/ros2_ign && \
    sh -c 'echo "deb [arch=$(dpkg --print-architecture)] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros2-latest.list' && \
    curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add - && \
    apt-get update && \
    source /opt/ros/${ROS2_DISTRO}/setup.bash && \
    source ${ROS2_IGN_WS}/ign_${IGNITION_VERSION}/install/local_setup.bash && \
    rosdep install -r --from-paths src -i -y --rosdistro ${ROS_DISTRO} && \
    rm -rf /var/lib/apt/lists/* && \
    colcon build --merge-install --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release

### Add entrypoint sourcing the environment
COPY ./entrypoint.bash ./entrypoint.bash
RUN chmod +x ./entrypoint.bash

### Set domain ID for ROS2 in order to not interfere with host
### Note: ROS_LOCALHOST_ONLY prevents MoveIt2 from working, so please do not use it
ENV ROS_DOMAIN_ID 69

ENTRYPOINT ["/bin/bash", "entrypoint.bash"]
CMD ["/bin/bash"]
