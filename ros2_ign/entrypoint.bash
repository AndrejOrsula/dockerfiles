#!/usr/bin/env bash
set -e

## ROS 2
source /opt/ros/${ROS2_DISTRO}/setup.bash

## Ignition
source ${ROS2_IGN_WS}/ign_${IGNITION_VERSION}/install/local_setup.bash

## ROS 2 <-> Ignition (bridge)
source ${ROS2_IGN_WS}/ros2_ign/install/local_setup.bash

# If a CMD is passed, execute it
exec "$@"
