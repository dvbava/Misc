#!/bin/bash
set -e

# =========================
# OpenCloud Desktop Builder (ARM64)
# =========================

WORKDIR=$HOME/opencloud-build
mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "=== Installing system dependencies ==="
apt update

apt install -y \
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
  libsqlite3-dev \
  libfuse3-dev \
  libgl1-mesa-dev

# =========================
# LibreGraphAPI SDK
# =========================
echo "=== Building LibreGraphAPI ==="
cd "$WORKDIR"

if [ ! -d libre-graph-api-cpp-qt-client ]; then
  git clone https://github.com/opencloud-eu/libre-graph-api-cpp-qt-client
fi

cd libre-graph-api-cpp-qt-client
rm -rf build
mkdir build && cd build

cmake ../client/
make -j$(nproc)
make install

# =========================
# KDSingleApplication
# =========================
echo "=== Building KDSingleApplication ==="
cd "$WORKDIR"

if [ ! -d KDSingleApplication ]; then
  git clone https://github.com/KDAB/KDSingleApplication.git
fi

cd KDSingleApplication
rm -rf build
mkdir build && cd build

cmake .. -DBUILD_WITH_QT6=ON
make -j$(nproc)
make install

# =========================
# OpenCloud Desktop
# =========================
echo "=== Building OpenCloud Desktop ==="
cd "$WORKDIR"

if [ ! -d desktop ]; then
  git clone https://github.com/opencloud-eu/desktop.git
fi

cd desktop
rm -rf build
mkdir build && cd build

cmake ..
cmake --build . -j$(nproc)

echo "=== BUILD COMPLETE ==="
echo "Run with:"
echo "$WORKDIR/desktop/build/bin/opencloud"
