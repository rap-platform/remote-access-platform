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
BUILD_DIR="${PROJECT_ROOT}/build_macos"
OUTPUT_DIR="${PROJECT_ROOT}/dist/desktop/macos"

# Read version from VERSION file
APP_VERSION="0.3.0"
if [ -f "${PROJECT_ROOT}/VERSION" ]; then
    APP_VERSION="$(grep -E '^AppVersion=' "${PROJECT_ROOT}/VERSION" | cut -d'=' -f2 || echo "0.3.0")"
fi

echo -e "${CYAN}=== Remote Access Platform — macOS Desktop Packaging Pipeline ===${NC}"
echo "Target Version: ${APP_VERSION}"
echo "Project Root: ${PROJECT_ROOT}"
echo "Output Directory: ${OUTPUT_DIR}"

# Check for macOS environment
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${YELLOW}NOTICE: macOS packaging (.dmg / .app) requires a macOS host with Xcode and Qt 6 installed.${NC}"
    echo "Windows/Linux developers can use build_and_package.bat or package-appimage.sh."
    exit 0
fi

# Load .env file overrides if present
if [ -f "${PROJECT_ROOT}/.env" ]; then
    set -a
    source "${PROJECT_ROOT}/.env"
    set +a
fi

# Locate CMake
CMAKE_CMD=""
if [ -n "${MACOS_CMAKE_PATH:-}" ] && [ -x "${MACOS_CMAKE_PATH}" ]; then
    CMAKE_CMD="${MACOS_CMAKE_PATH}"
elif command -v cmake &>/dev/null; then
    CMAKE_CMD="$(command -v cmake)"
else
    echo -e "${RED}ERROR: CMake not found in PATH or MACOS_CMAKE_PATH.${NC}"
    exit 1
fi
echo -e "${GREEN}Using CMake: ${CMAKE_CMD}${NC}"

# Locate Qt 6 macdeployqt
MACDEPLOYQT_CMD=""
if [ -n "${QT_MACOS_PATH:-}" ] && [ -x "${QT_MACOS_PATH}/bin/macdeployqt" ]; then
    MACDEPLOYQT_CMD="${QT_MACOS_PATH}/bin/macdeployqt"
else
    QT_FOUND_DEPLOY="$(find "$HOME/Qt" /opt/Qt /usr/local/opt/qt6 -name "macdeployqt" 2>/dev/null | head -n 1 || true)"
    if [ -n "${QT_FOUND_DEPLOY}" ] && [ -x "${QT_FOUND_DEPLOY}" ]; then
        MACDEPLOYQT_CMD="${QT_FOUND_DEPLOY}"
    elif command -v macdeployqt &>/dev/null; then
        MACDEPLOYQT_CMD="$(command -v macdeployqt)"
    fi
fi

if [ -n "${MACDEPLOYQT_CMD}" ]; then
    echo -e "${GREEN}Using macdeployqt: ${MACDEPLOYQT_CMD}${NC}"
else
    echo -e "${YELLOW}WARNING: macdeployqt not found. Standard .app bundle will be staged without embedded Qt frameworks.${NC}"
fi

# 1. Configure and Build C++ release binaries
echo -e "${CYAN}--> Configuring CMake for macOS (Release)...${NC}"
mkdir -p "${BUILD_DIR}"
QT_PREFIX=""
if [ -n "${MACDEPLOYQT_CMD}" ]; then
    QT_PREFIX="$(dirname "$(dirname "${MACDEPLOYQT_CMD}")")"
    "${CMAKE_CMD}" -S "${PROJECT_ROOT}" -B "${BUILD_DIR}" -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="${QT_PREFIX}"
else
    "${CMAKE_CMD}" -S "${PROJECT_ROOT}" -B "${BUILD_DIR}" -DCMAKE_BUILD_TYPE=Release
fi

echo -e "${CYAN}--> Compiling release binaries (rap-client, rap-agent)...${NC}"
"${CMAKE_CMD}" --build "${BUILD_DIR}" --config Release -j"$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"

# 2. Stage .app bundle
APP_BUNDLE="${BUILD_DIR}/apps/client/rap-client.app"
mkdir -p "${OUTPUT_DIR}"

if [ -d "${APP_BUNDLE}" ]; then
    # Copy rap-agent binary into .app bundle helper binaries directory
    mkdir -p "${APP_BUNDLE}/Contents/MacOS"
    if [ -f "${BUILD_DIR}/apps/agent/rap-agent" ]; then
        cp -f "${BUILD_DIR}/apps/agent/rap-agent" "${APP_BUNDLE}/Contents/MacOS/"
    fi

    # 3. Execute macdeployqt to create standalone .dmg
    if [ -n "${MACDEPLOYQT_CMD}" ] && [ -x "${MACDEPLOYQT_CMD}" ]; then
        echo -e "${CYAN}--> Running macdeployqt to create standalone .dmg package...${NC}"
        "${MACDEPLOYQT_CMD}" "${APP_BUNDLE}" -qmldir="${PROJECT_ROOT}/apps/client/qml" -dmg
        
        # Move generated DMG file to output directory
        DMG_FILE="$(find "${BUILD_DIR}/apps/client" -name "*.dmg" 2>/dev/null | head -n 1 || true)"
        if [ -n "${DMG_FILE}" ] && [ -f "${DMG_FILE}" ]; then
            mv -f "${DMG_FILE}" "${OUTPUT_DIR}/RemoteAccessPlatform-${APP_VERSION}.dmg"
            echo -e "${GREEN}SUCCESS: Generated ${OUTPUT_DIR}/RemoteAccessPlatform-${APP_VERSION}.dmg${NC}"
        fi
    fi

    # Zip output archive fallback
    echo -e "${CYAN}--> Archiving rap-client.app bundle...${NC}"
    (cd "${BUILD_DIR}/apps/client" && zip -r -q "${OUTPUT_DIR}/RemoteAccessPlatform-${APP_VERSION}-macOS.zip" "rap-client.app")
fi

# 4. Generate SHA-256 and MD5 Checksums
echo -e "${CYAN}--> Generating checksums...${NC}"
CHECKSUM_FILE="${OUTPUT_DIR}/checksums.txt"
{
    echo "Remote Access Platform macOS Desktop V${APP_VERSION} Release Checksums"
    echo "Date: $(date)"
    echo "========================================================================="
    for f in "${OUTPUT_DIR}"/*; do
        if [ -f "$f" ] && [ "$(basename "$f")" != "checksums.txt" ]; then
            FNAME="$(basename "$f")"
            if command -v shasum &>/dev/null; then
                echo "SHA-256 ($FNAME): $(shasum -a 256 "$f" | awk '{print $1}')"
            fi
            if command -v md5 &>/dev/null; then
                echo "MD5    ($FNAME): $(md5 "$f" | awk '{print $1}')"
            fi
            echo "---"
        fi
    done
} > "${CHECKSUM_FILE}"

echo -e "${GREEN}=========================================================================${NC}"
echo -e "${GREEN}macOS DESKTOP PACKAGING COMPLETE!${NC}"
echo -e "${GREEN}Artifacts saved to: ${OUTPUT_DIR}${NC}"
echo -e "${GREEN}=========================================================================${NC}"
