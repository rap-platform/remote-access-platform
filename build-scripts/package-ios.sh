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
MOBILE_DIR="${PROJECT_ROOT}/apps/mobile"
OUTPUT_DIR="${PROJECT_ROOT}/dist/mobile/ios"

# Read version from VERSION file
APP_VERSION="0.3.0"
if [ -f "${PROJECT_ROOT}/VERSION" ]; then
    APP_VERSION="$(grep -E '^AppVersion=' "${PROJECT_ROOT}/VERSION" | cut -d'=' -f2 || echo "0.3.0")"
fi

echo -e "${CYAN}=== Remote Access Platform — iOS Packaging Pipeline ===${NC}"
echo "Target Version: ${APP_VERSION}"
echo "Mobile Project: ${MOBILE_DIR}"
echo "Output Directory: ${OUTPUT_DIR}"

# Check for macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${YELLOW}WARNING: iOS IPA packaging requires macOS with Xcode installed.${NC}"
    echo "This script is designed for execution on macOS environment."
    exit 0
fi

# Load .env overrides if present
if [ -f "${PROJECT_ROOT}/.env" ]; then
    set -a
    source "${PROJECT_ROOT}/.env"
    set +a
fi

# Locate Flutter
FLUTTER_CMD=""
if [ -n "${FLUTTER_ROOT:-}" ] && [ -x "${FLUTTER_ROOT}/bin/flutter" ]; then
    FLUTTER_CMD="${FLUTTER_ROOT}/bin/flutter"
elif command -v flutter &>/dev/null; then
    FLUTTER_CMD="$(command -v flutter)"
else
    echo -e "${RED}ERROR: Flutter SDK not found in PATH or FLUTTER_ROOT.${NC}"
    exit 1
fi

mkdir -p "${OUTPUT_DIR}"
cd "${MOBILE_DIR}"

echo -e "${CYAN}--> Resolving Flutter and CocoaPods packages...${NC}"
"${FLUTTER_CMD}" pub get

if [ -d "ios" ]; then
    cd ios
    if command -v pod &>/dev/null; then
        pod install
    fi
    cd ..
fi

EXPORT_PLIST="${MOBILE_DIR}/ios/ExportOptions.plist"
if [ ! -f "${EXPORT_PLIST}" ]; then
    EXPORT_PLIST="${MOBILE_DIR}/ios/ExportOptions.plist.example"
fi

echo -e "${CYAN}--> Compiling & Archiving iOS Release Package (IPA)...${NC}"
if [ -f "${EXPORT_PLIST}" ]; then
    "${FLUTTER_CMD}" build ipa --release --export-options-plist="${EXPORT_PLIST}"
else
    "${FLUTTER_CMD}" build ipa --release
fi

BUILD_IPA_DIR="${MOBILE_DIR}/build/ios/ipa"
if [ -d "${BUILD_IPA_DIR}" ]; then
    cp -f "${BUILD_IPA_DIR}"/*.ipa "${OUTPUT_DIR}/RemoteAccessPlatform-${APP_VERSION}.ipa" 2>/dev/null || true
    echo -e "${GREEN}SUCCESS: iOS IPA generated at ${OUTPUT_DIR}/RemoteAccessPlatform-${APP_VERSION}.ipa${NC}"
else
    echo -e "${YELLOW}iOS build completed; IPA archive staged at ${MOBILE_DIR}/build/ios/archive${NC}"
fi
