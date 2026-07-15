#!/usr/bin/env bash
#
# Build a .deb package of CCTV Viewer for Debian / Ubuntu desktops (no snap).
#
# The resulting package is written to the parent directory and can be installed
# with:  sudo apt install ../cctv-viewer_*.deb
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    SUDO="sudo"
fi

PACKAGING_DEPS=(
    devscripts
    debhelper
    dpkg-dev
    build-essential
    cmake
    git
    pkg-config
    libva-dev
    libglx-dev
    libavformat-dev
    libavcodec-dev
    libavutil-dev
    libswscale-dev
    libswresample-dev
    libavdevice-dev
    qtdeclarative5-dev
    qtmultimedia5-dev
    qttools5-dev
)

echo ">> Installing packaging dependencies (apt)..."
$SUDO apt-get update
$SUDO apt-get install -y "${PACKAGING_DEPS[@]}"

echo ">> Fetching git submodules..."
git -C "${SCRIPT_DIR}" submodule update --init --recursive

echo ">> Building the .deb package..."
cd "${SCRIPT_DIR}"
dpkg-buildpackage -us -uc -b

echo ""
echo ">> Package built. Install it with:"
echo "     sudo apt install ../cctv-viewer_*.deb"
