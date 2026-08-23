#!/usr/bin/env bash
#
# Easy source install of CCTV Viewer on Debian / Ubuntu desktops (no snap).
#
# It installs the build and runtime dependencies, fetches the git submodules,
# builds the application with CMake and installs it system-wide into /usr.
#
# Usage:
#   ./install-debian.sh            # build and install
#   ./install-debian.sh --uninstall
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    SUDO="sudo"
fi

# Build dependencies (Qt 5, FFmpeg/libav, build tools).
BUILD_DEPS=(
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

# Runtime QML modules and plugins needed at start-up.
RUNTIME_DEPS=(
    libqt5multimedia5-plugins
    qtwayland5
    qml-module-qtquick-layouts
    qml-module-qtqml-models2
    qml-module-qtquick-controls
    qml-module-qtquick-controls2
    qml-module-qtquick-templates2
    qml-module-qtquick-window2
    qml-module-qtquick-dialogs
    qml-module-qt-labs-settings
    qml-module-qtmultimedia
    qml-module-qtgraphicaleffects
)

uninstall() {
    echo ">> Uninstalling CCTV Viewer..."
    if [ -f "${BUILD_DIR}/install_manifest.txt" ]; then
        while IFS= read -r file; do
            $SUDO rm -f "$file"
        done < "${BUILD_DIR}/install_manifest.txt"
    else
        $SUDO rm -f /usr/bin/cctv-viewer \
                    /usr/share/pixmaps/cctv-viewer.svg \
                    /usr/share/applications/cctv-viewer.desktop
    fi
    $SUDO update-desktop-database /usr/share/applications 2>/dev/null || true
    echo ">> Done."
}

if [ "${1:-}" = "--uninstall" ]; then
    uninstall
    exit 0
fi

echo ">> Installing build and runtime dependencies (apt)..."
$SUDO apt-get update
$SUDO apt-get install -y "${BUILD_DEPS[@]}" "${RUNTIME_DEPS[@]}"

echo ">> Fetching git submodules..."
git -C "${SCRIPT_DIR}" submodule update --init --recursive

echo ">> Configuring (CMake)..."
cmake -S "${SCRIPT_DIR}" -B "${BUILD_DIR}" -DCMAKE_BUILD_TYPE=RelWithDebInfo

echo ">> Building..."
cmake --build "${BUILD_DIR}" --parallel "$(nproc)"

echo ">> Installing into /usr (requires privileges)..."
$SUDO cmake --install "${BUILD_DIR}"

echo ">> Refreshing desktop database and icon cache..."
$SUDO update-desktop-database /usr/share/applications 2>/dev/null || true
$SUDO gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null || true

echo ""
echo ">> CCTV Viewer installed. Launch it from your application menu or run: cctv-viewer"
