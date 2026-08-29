#!/usr/bin/env bash
set -euo pipefail

# ANSI Color Codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build"
APPDIR="${BUILD_DIR}/AppDir"
OUTPUT_DIR="${PROJECT_ROOT}/dist"

APP_NAME="RemoteAccessPlatform"

echo -e "${CYAN}=== Packaging ${APP_NAME} (AppImage) ===${NC}"
echo "Project Root: ${PROJECT_ROOT}"
echo "Build Dir:    ${BUILD_DIR}"
echo "AppDir:       ${APPDIR}"

# 1. Allow AppImage binaries (linuxdeploy) to run without FUSE in containers/CI
export APPIMAGE_EXTRACT_AND_RUN=1

# Load .env file if it exists to pick up custom paths
if [ -f "${PROJECT_ROOT}/.env" ]; then
    set -a
    source "${PROJECT_ROOT}/.env"
    set +a
fi

# 2. Locate QMAKE
if [ -n "${LINUX_QMAKE_PATH:-}" ] && [ -x "${LINUX_QMAKE_PATH}" ]; then
    QMAKE="${LINUX_QMAKE_PATH}"
elif [ -n "${QMAKE:-}" ] && [ -x "${QMAKE}" ]; then
    QMAKE="${QMAKE}"
else
    QT_AUTOFOUND_QMAKE="$(find "$HOME/Qt" /opt/Qt -maxdepth 4 -name "qmake" -path "*/gcc_64/bin/*" 2>/dev/null | head -n 1 || true)"
    if [ -n "${QT_AUTOFOUND_QMAKE}" ] && [ -x "${QT_AUTOFOUND_QMAKE}" ]; then
        QMAKE="${QT_AUTOFOUND_QMAKE}"
    else
        QMAKE="$(command -v qmake6 2>/dev/null || command -v qmake 2>/dev/null || echo "/usr/lib/qt6/bin/qmake")"
    fi
fi
export QMAKE
echo "Using QMAKE: ${QMAKE}"

# Locate CMAKE
if [ -n "${LINUX_CMAKE_PATH:-}" ] && [ -x "${LINUX_CMAKE_PATH}" ]; then
    CMAKE="${LINUX_CMAKE_PATH}"
elif [ -n "${CMAKE:-}" ] && [ -x "${CMAKE}" ]; then
    CMAKE="${CMAKE}"
else
    QT_TOOLS_CMAKE="$(find "$HOME/Qt/Tools/CMake/bin" /opt/Qt/Tools/CMake/bin -name "cmake" 2>/dev/null | head -n 1 || true)"
    if [ -n "${QT_TOOLS_CMAKE}" ] && [ -x "${QT_TOOLS_CMAKE}" ]; then
        CMAKE="${QT_TOOLS_CMAKE}"
    else
        CMAKE="$(command -v cmake || echo "cmake")"
    fi
fi
echo "Using CMAKE: ${CMAKE}"

# Export QML path for linuxdeploy-plugin-qt to bundle QML runtime modules
export QML_SOURCES_PATHS="${PROJECT_ROOT}/apps/client/qml"
echo "QML Sources Path: ${QML_SOURCES_PATHS}"

# Ensure linuxdeploy tools are available; download if missing
TOOLS_DIR="${PROJECT_ROOT}/tools"
mkdir -p "${TOOLS_DIR}"

LINUXDEPLOY="${TOOLS_DIR}/linuxdeploy-x86_64.AppImage"
LINUXDEPLOY_QT="${TOOLS_DIR}/linuxdeploy-plugin-qt-x86_64.AppImage"

if [ ! -f "${LINUXDEPLOY}" ]; then
    echo -e "${YELLOW}Downloading linuxdeploy tool...${NC}"
    wget -q -O "${LINUXDEPLOY}" "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage" || true
    chmod +x "${LINUXDEPLOY}" 2>/dev/null || true
fi

if [ ! -f "${LINUXDEPLOY_QT}" ]; then
    echo -e "${YELLOW}Downloading linuxdeploy qt plugin...${NC}"
    wget -q -O "${LINUXDEPLOY_QT}" "https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage" || true
    chmod +x "${LINUXDEPLOY_QT}" 2>/dev/null || true
fi

# Clean previous package directory
rm -rf "${APPDIR}"
mkdir -p "${APPDIR}"
mkdir -p "${OUTPUT_DIR}"

echo -e "${CYAN}--> Running CMake configure and build...${NC}"
QT_PREFIX_DIR="$(dirname "$(dirname "$QMAKE")")"
"${CMAKE}" -S "${PROJECT_ROOT}" -B "${BUILD_DIR}" -DCMAKE_PREFIX_PATH="${QT_PREFIX_DIR}" -DCMAKE_BUILD_TYPE=Release
"${CMAKE}" --build "${BUILD_DIR}" -j"$(nproc 2>/dev/null || echo 4)"

# Populate AppDir structure
echo -e "${CYAN}--> Installing application files into AppDir...${NC}"
mkdir -p "${APPDIR}/usr/bin"
mkdir -p "${APPDIR}/usr/share/applications"
mkdir -p "${APPDIR}/usr/share/icons/hicolor/256x256/apps"

cp -f "${BUILD_DIR}/apps/client/rap-client" "${APPDIR}/usr/bin/" 2>/dev/null || true
cp -f "${BUILD_DIR}/apps/agent/rap-agent" "${APPDIR}/usr/bin/" 2>/dev/null || true

# Generate Desktop Entry
cat <<EOF > "${APPDIR}/usr/share/applications/remote-access-platform.desktop"
[Desktop Entry]
Type=Application
Name=Remote Access Platform
Exec=rap-client
Icon=remote-access-platform
Categories=Utility;Network;
Comment=Enterprise Cross-Platform Remote Desktop Viewer and Management System
EOF

if [ -f "${LINUXDEPLOY}" ] && [ -x "${LINUXDEPLOY}" ]; then
    echo -e "${CYAN}--> Generating AppImage package...${NC}"
    "${LINUXDEPLOY}" --appdir "${APPDIR}" --plugin qt --output appimage
    mv -f Remote_Access_Platform*.AppImage "${OUTPUT_DIR}/" 2>/dev/null || true
    echo -e "${GREEN}AppImage build completed: ${OUTPUT_DIR}${NC}"
else
    echo -e "${YELLOW}NOTICE: linuxdeploy tool binary unavailable; AppDir output staged at ${APPDIR}${NC}"
fi
