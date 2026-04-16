#!/usr/bin/env bash

echo "=============================="
echo " Installing system deps"
echo "=============================="

sudo apt update
sudo apt install -y \
  build-essential \
  cmake \
  git \
  pkg-config \
  extra-cmake-modules \
  qt6-base-dev \
  qt6-tools-dev \
  qt6-tools-dev-tools \
  qt6-svg-dev \
  qt6-networkauth-dev \
  qt6-declarative-dev \
  qt6-wayland \
  libqt6svg6 \
  libssl-dev \
  libz-dev \
  libsecret-1-dev \
  libsqlite3-dev \
  libfuse3-dev \
  fuse3 libfuse3-3 \
  libgl1-mesa-dev \
  patchelf \
  nlohmann-json3-dev \
  wget \
  file
