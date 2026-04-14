#!/usr/bin/env bash
set -euo pipefail

# =========================
# OpenCloud AppImage Builder (ARM64 / Qt6)
# =========================

APP_NAME="OpenCloud"
ORIG_HOME=$(eval echo ~${SUDO_USER})
WORKDIR="$ORIG_HOME/opencloud-build"
SRC_DIR="$WORKDIR/src"
BUILD_DIR="$WORKDIR/build"
INSTALL_DIR="$WORKDIR/AppDir/usr"
APPDIR="$WORKDIR/AppDir"
OUTPUT="$WORKDIR/output"

JOBS=$(nproc)

mkdir -p "$WORKDIR" "$SRC_DIR" "$BUILD_DIR" "$INSTALL_DIR" "$OUTPUT"

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
  libgl1-mesa-dev \
  patchelf \
  wget \
  file

echo "=============================="
echo " Build dependencies"
echo "=============================="

cd "$SRC_DIR"

# ---- LibreGraphAPI ----
if [ ! -d libre-graph-api-cpp-qt-client ]; then
  git clone https://github.com/opencloud-eu/libre-graph-api-cpp-qt-client
fi

cd libre-graph-api-cpp-qt-client
rm -rf build
mkdir build && cd build

cmake ../client/ \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR"

make -j"$JOBS"
make install


# ---- KDSingleApplication ----
cd "$SRC_DIR"

if [ ! -d KDSingleApplication ]; then
  git clone https://github.com/KDAB/KDSingleApplication.git
fi

cd KDSingleApplication
rm -rf build
mkdir build && cd build

cmake .. \
  -DBUILD_WITH_QT6=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR"

make -j"$JOBS"
make install


# ---- QtKeychain ----
cd "$SRC_DIR"

if [ ! -d qtkeychain ]; then
  git clone https://github.com/frankosterfeld/qtkeychain.git
fi

cd qtkeychain
rm -rf build
mkdir build && cd build

cmake .. \
  -DBUILD_WITH_QT6=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR"

make -j"$JOBS"
make install


echo "=============================="
echo " Build OpenCloud Desktop"
echo "=============================="

cd "$SRC_DIR"

if [ ! -d desktop ]; then
  git clone https://github.com/opencloud-eu/desktop.git
fi

cd desktop
rm -rf build
mkdir build && cd build

cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR"

cmake --build . -j"$JOBS"
cmake --install .


echo "=============================="
echo " Create AppDir structure"
echo "=============================="

mkdir -p "$APPDIR"

# Copy desktop files if they exist
if [ -f "$SRC_DIR/desktop/resources/opencloud.desktop" ]; then
  cp "$SRC_DIR/desktop/resources/opencloud.desktop" "$APPDIR/"
else
  echo "WARNING: .desktop file not found"
fi

if [ -f "$SRC_DIR/desktop/resources/opencloud.png" ]; then
  cp "$SRC_DIR/desktop/resources/opencloud.png" "$APPDIR/"
fi

echo "=============================="
echo " Create AppRun"
echo "=============================="

cat > "$APPDIR/AppRun" << 'EOF'
#!/usr/bin/env bash

HERE="$(dirname "$(readlink -f "${0}")")"

export LD_LIBRARY_PATH="$HERE/usr/lib:$HERE/usr/lib/aarch64-linux-gnu:$LD_LIBRARY_PATH"
export QT_PLUGIN_PATH="$HERE/usr/lib/qt6/plugins:$QT_PLUGIN_PATH"
export QML2_IMPORT_PATH="$HERE/usr/lib/qt6/qml:$QML2_IMPORT_PATH"

exec "$HERE/usr/bin/opencloud" "$@"
EOF

chmod +x "$APPDIR/AppRun"


echo "=============================="
echo " Bundle dependencies (linuxdeploy)"
echo "=============================="

cd "$WORKDIR"

# Download linuxdeploy if missing
if [ ! -f linuxdeploy ]; then
  wget -q https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-aarch64.AppImage
  mv linuxdeploy-aarch64.AppImage linuxdeploy
  chmod +x linuxdeploy
fi

# Download Qt plugin
if [ ! -f linuxdeploy-plugin-qt ]; then
  wget -q https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-aarch64.AppImage
  mv linuxdeploy-plugin-qt-aarch64.AppImage linuxdeploy-plugin-qt
  chmod +x linuxdeploy-plugin-qt
fi


./linuxdeploy \
  --appdir "$APPDIR" \
  --plugin qt \
  --output appimage


echo "=============================="
echo " DONE"
echo "=============================="

ls -lh *.AppImage || true

echo "AppImage should be in: $WORKDIR"
