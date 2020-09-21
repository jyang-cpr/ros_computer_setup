#!/bin/bash -eu
# Software License Agreement (BSD)
#
# Author    Tony Baltovski <tbaltovski@clearpathrobotics.com>
# Copyright (c) 2020, Clearpath Robotics, Inc., All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided that
# the following conditions are met:
# * Redistributions of source code must retain the above copyright notice, this list of conditions and the
#   following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
#   following disclaimer in the documentation and/or other materials provided with the distribution.
# * Neither the name of Clearpath Robotics nor the names of its contributors may be used to endorse or
#   promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

#set -x

echo "Starting ROS installion"

# Get Ubuntu version
ubuntu_version=`lsb_release -sc`

echo ""
echo -e "\e[39mChecking your Ubuntu version\e[0m"
echo -e "\e[39mDetected Ubuntu: $ubuntu_version\e[0m"

case $ubuntu_version in
  "xenial" )
    ros_version="kinetic"
  ;;
  "bionic" )
    ros_version="melodic"
  ;;
  *)
    echo -e "\e[31mERROR: Unsupported Ubuntu version: $ubuntu_version\e[0m"
    exit 0
esac

echo -e "\e[32mUbuntu ${ubuntu_version} is supported, proceeding to install ROS ${ros_version}\e[0m"

echo ""
echo -e "\e[39mWhich computing platform are you installing on?"
echo -e "[1]\e[32m Nvidia Jetson Xavier NX\e[0m"
echo -e "[2]\e[32m Nvidia Jetson Nano\e[0m"
echo -e "[3]\e[32m Nvidia Jetson AGX Xavier\e[0m"
echo -e "[4]\e[32m Nvidia Jetson TX2\e[0m"

read answer
case "$answer" in
  1)
    compute_type="jetson-xavier-nx"
    ;;
  2)
    compute_type="jetson-nano"
    ;;
  3)
    compute_type="jetson-xavier-agx"
    ;;
  4)
    compute_type="jetson-tx2"
    ;;
  * )
    compute_type="jetson-xavier-nx"
    ;;
esac

echo "Selected ${compute_type}."
echo ""

echo "Which robot are you installing?"
echo -e "[1] \e[21;30;103mClearpath Husky\e[0m"
echo -e "[2] \e[21;30;103mClearpath Jackal\e[0m"
echo -e "[3] \e[21;30;103mClearpath Dingo\e[0m"
echo -e "Enter your selection (Default is 1):"
read answer
case "$answer" in
  1)
    platform="husky"
    ;;
  2)
    platform="jackal"
    ;;
  3)
    platform="dingo"
    ;;
  * )
    platform="husky"
    ;;
esac

echo "Selected ${platform}."
echo ""
echo "Summary: Installing ROS ${ros_version} on ${compute_type} in ${platform}"

echo ""
echo -e "\e[94mConfiguring Ubuntu repositories\e[0m"

sudo add-apt-repository -y universe
sudo add-apt-repository -y restricted
sudo add-apt-repository -y multiverse
sudo apt-get install -qq -y apt-transport-https apt-utils bash-completion git nano screen

echo -e "\e[32mDone: Configuring Ubuntu repositories\e[0m"
echo ""

echo -e "\e[94mSetup your apt sources\e[0m"


# Check if ROS sources are already installed
if [ -e /etc/apt/sources.list.d/ros-latest.list ]; then
  echo -e "\e[33mWarn: ROS sources exist, skipping\e[0m"
else
  sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
  sudo apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654
  # Check if sources were added
  if [ ! -e /etc/apt/sources.list.d/ros-latest.list ]; then
    echo -e "\e[31mError: Unable to add ROS sources, exiting\e[0m"
    exit 0
  fi
fi

# Check if CPR sources are already installed
if [ -e /etc/apt/sources.list.d/clearpath-latest.list ]; then
  echo -e "\e[33mWarn: CPR sources exist, skipping\e[0m"
else
  wget https://packages.clearpathrobotics.com/public.key -O - | sudo apt-key add -
  sudo sh -c 'echo "deb https://packages.clearpathrobotics.com/stable/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/clearpath-latest.list'
  # Check if sources were added
  if [ ! -e /etc/apt/sources.list.d/clearpath-latest.list ]; then
    echo -e "\e[31mError: Unable to add CPR sources, exiting\e[0m"
    exit 0
  fi
fi

echo -e "\e[32mDone: Setup your apt sources\e[0m"
echo ""

echo -e "\e[94mUpdating packages\e[0m"
sudo apt -y -qq update
sudo apt -y -qq dist-upgrade
echo -e "\e[32mDone: Updating packages\e[0m"
echo ""

echo -e "\e[94mInstalling ROS prerequisites\e[0m"
sudo apt install -qq -y python-rosdep python-rosinstall python-rosinstall-generator python-wstool build-essential
echo -e "\e[32mDone: Installing ROS prerequisites\e[0m"
echo ""

echo -e "\e[94mInstalling ${platform} packages\e[0m"
sudo apt install -qq -y ros-${ros_version}-${platform}-robot
echo -e "\e[32mDone: Installing ${platform} packages\e[0m"
echo ""

echo -e "\e[94mConfiguring Robot environment\e[0m"

sudo mkdir -p /etc/ros

if [ -e /etc/profile.d/clearpath-ros-environment.sh ]; then
  echo -e "\e[33mWarn: CPR ROS environment exist, skipping\e[0m"
else
  sudo wget -q -O /etc/profile.d/clearpath-ros-environment.sh \
    https://raw.githubusercontent.com/clearpathrobotics/ros_computer_setup/main/files/clearpath-ros-environment.sh
  # Check if was added
  if [ ! -e /etc/profile.d/clearpath-ros-environment.sh ]; then
    echo -e "\e[31mError: CPR ROS environment exist, exiting\e[0m"
    exit 0
  fi
fi

if [ -e /etc/ros/setup.bash ]; then
  echo -e "\e[33mWarn: CPR ROS robot environment exist, skipping\e[0m"
else
  sudo wget -q -O /etc/ros/setup.bash \
    https://raw.githubusercontent.com/clearpathrobotics/ros_computer_setup/main/files/setup.bash
  sudo sed -i "s/UNKNOWN_ROS_DISTRO/${ros_version}/g" /etc/ros/setup.bash
  # Check if was added
  if [ ! -e /etc/ros/setup.bash ]; then
    echo -e "\e[31mError: CPR ROS robot environment exist, exiting\e[0m"
    exit 0
  fi
fi

echo "source /opt/ros/${ros_version}/setup.bash" >> $HOME/.bashrc
echo -e "\e[32mDone: Configuring Robot environment\e[0m"
echo ""

echo -e "\e[94mConfiguring rosdep\e[0m"
if [ -e /etc/ros/rosdep/sources.list.d/20-default.list ]; then
  echo -e "\e[33mWarn: rosdep was initalized, skipping\e[0m"
else
  sudo rosdep -q init
  if [ ! -e /etc/ros/rosdep/sources.list.d/20-default.list ]; then
    echo -e "\e[31mError: rosdep failed to initalize, exiting\e[0m"
    exit 0
  fi
fi

if [ -e /etc/ros/rosdep/sources.list.d/50-clearpath.list ]; then
  echo -e "\e[33mWarn: CPR rosdeps exist, skipping\e[0m"
else
  sudo wget -q https://raw.githubusercontent.com/clearpathrobotics/public-rosdistro/master/rosdep/50-clearpath.list -O \
    /etc/ros/rosdep/sources.list.d/50-clearpath.list
  # Check if was added
  if [ ! -e /etc/ros/rosdep/sources.list.d/50-clearpath.list ]; then
    echo -e "\e[31mError: CPR rosdeps, exiting\e[0m"
    exit 0
  fi
fi
rosdep -q update
echo -e "\e[32mDone: Configuring rosdep\e[0m"
echo ""

echo -e "\e[94mConfiguring udev rules\e[0m"
sudo wget -q -O /etc/udev/rules.d/10-microstrain.rules \
  https://raw.githubusercontent.com/clearpathrobotics/ros_computer_setup/main/files/udev/10-microstrain.rules
sudo wget -q -O /etc/udev/rules.d/41-clearpath.rules \
  https://raw.githubusercontent.com/clearpathrobotics/ros_computer_setup/main/files/udev/41-clearpath.rules
sudo wget -q -O /etc/udev/rules.d/41-hokuyo.rules \
  https://raw.githubusercontent.com/clearpathrobotics/ros_computer_setup/main/files/udev/41-hokuyo.rules
sudo wget -q -O /etc/udev/rules.d/41-logitech.rules \
  https://raw.githubusercontent.com/clearpathrobotics/ros_computer_setup/main/files/udev/41-logitech.rules
sudo wget -q -O /etc/udev/rules.d/41-playstation.rules \
  https://raw.githubusercontent.com/clearpathrobotics/ros_computer_setup/main/files/udev/41-playstation.rules
sudo wget -q -O /etc/udev/rules.d/52-ftdi.rules \
  https://raw.githubusercontent.com/clearpathrobotics/ros_computer_setup/main/files/udev/52-ftdi.rules
sudo wget -q -O /etc/udev/rules.d/60-startech.rules \
  https://raw.githubusercontent.com/clearpathrobotics/ros_computer_setup/main/files/udev/60-startech.rules
echo -e "\e[32mDone: Configuring udev rules\e[0m"
echo ""

echo -e "\e[94mConfiguring system configs\e[0m"
wget -q -O $HOME/.screenrc \
  https://raw.githubusercontent.com/clearpathrobotics/ros_computer_setup/main/files/config/.screenrc
wget -q -O $HOME/.vimrc \
  https://raw.githubusercontent.com/clearpathrobotics/ros_computer_setup/main/files/config/.vimrc
echo -e "\e[32mDone: Configuring system configs\e[0m"
echo ""

echo -e "\e[94mConfiguring ${platform}\e[0m"
source /etc/ros/setup.bash
if [ "platform" == "jackal" ]; then
  sudo sh -c 'echo export JACKAL_WIRELESS_INTERFACE=wlan0 >> /etc/ros/setup.bash'
fi
# rosrun ${platform}_bringup install
echo -e "\e[32mDone: Configuring ${platform}\e[0m"
echo ""

echo -e "\e[94mConfiguring Bluetooth\e[0m"
sudo apt install -qq -y bluez bluez-tools
echo -e "\e[32mDone: Configuring Bluetooth\e[0m"
echo ""

echo -e "\e[94mConfiguring Wireless\e[0m"
sudo usermod -a -G netdev $USER
sudo apt install -qq -y wicd-curses bridge-utils
echo -e "\e[32mDone: Configuring Wiresless\e[0m"
echo ""

echo -e "\e[94mRemoving unused packages\e[0m"
sudo apt-get -qq -y autoremove
echo -e "\e[32mDone: Removing unused packages\e[0m"
echo ""

echo -e "\e[94mVerifying install\e[0m"
if [ "$ros_version" == `rosversion -d` ]; then
    echo -e "\e[32mDone: Verifying install\e[0m"
else
    echo -e "\e[33mWarn: Verifying install might not be complete\e[0m"
fi
echo ""

echo -e "\e[32mDone: Installing ROS ${ros_version} on ${compute_type} in ${platform}\e[0m"
