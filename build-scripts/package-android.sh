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
OUTPUT_DIR="${PROJECT_ROOT}/dist/mobile/android"

# Read version from VERSION file
APP_VERSION="0.3.0"
if [ -f "${PROJECT_ROOT}/VERSION" ]; then
    APP_VERSION="$(grep -E '^AppVersion=' "${PROJECT_ROOT}/VERSION" | cut -d'=' -f2 || echo "0.3.0")"
fi

echo -e "${CYAN}=== Remote Access Platform — Android Packaging Pipeline ===${NC}"
echo "Target Version: ${APP_VERSION}"
echo "Mobile Project: ${MOBILE_DIR}"
echo "Output Directory: ${OUTPUT_DIR}"

# Load .env overrides if present
if [ -f "${PROJECT_ROOT}/.env" ]; then
    set -a
    source "${PROJECT_ROOT}/.env"
    set +a
fi

# Locate Flutter executable
FLUTTER_CMD=""
if [ -n "${FLUTTER_ROOT:-}" ] && [ -x "${FLUTTER_ROOT}/bin/flutter" ]; then
    FLUTTER_CMD="${FLUTTER_ROOT}/bin/flutter"
elif command -v flutter &>/dev/null; then
    FLUTTER_CMD="$(command -v flutter)"
else
    echo -e "${RED}ERROR: Flutter SDK not found in PATH or FLUTTER_ROOT.${NC}"
    echo "Please install Flutter SDK and set FLUTTER_ROOT in .env"
    exit 1
fi
echo -e "${GREEN}Using Flutter SDK: ${FLUTTER_CMD}${NC}"

# Stage JNI native C-ABI libraries
echo -e "${CYAN}--> Staging Android JNI Native Libraries...${NC}"
for ABI in "arm64-v8a" "armeabi-v7a" "x86_64"; do
    JNI_DIR="${MOBILE_DIR}/android/app/src/main/jniLibs/${ABI}"
    mkdir -p "${JNI_DIR}"
    
    # Copy native C-ABI dynamic library if compiled
    NATIVE_LIB="${PROJECT_ROOT}/build/libs/common/librap_common.so"
    if [ -f "${NATIVE_LIB}" ]; then
        cp -f "${NATIVE_LIB}" "${JNI_DIR}/librap_common.so"
    fi
done

# Clean output directory
mkdir -p "${OUTPUT_DIR}"

cd "${MOBILE_DIR}"

echo -e "${CYAN}--> Resolving Flutter packages...${NC}"
"${FLUTTER_CMD}" pub get

# 1. Universal Release APK
echo -e "${CYAN}--> Building Universal Release APK...${NC}"
"${FLUTTER_CMD}" build apk --release

# 2. Per-ABI Split Release APKs
echo -e "${CYAN}--> Building Per-ABI Split APKs...${NC}"
"${FLUTTER_CMD}" build apk --split-per-abi --release

# 3. Play Store App Bundle (AAB)
echo -e "${CYAN}--> Building Google Play App Bundle (AAB)...${NC}"
"${FLUTTER_CMD}" build appbundle --release

# Copy artifacts to dist
echo -e "${CYAN}--> Copying artifacts to release distribution folder...${NC}"
BUILD_APK_DIR="${MOBILE_DIR}/build/app/outputs/flutter-apk"
BUILD_BUNDLE_DIR="${MOBILE_DIR}/build/app/outputs/bundle/release"

if [ -f "${BUILD_APK_DIR}/app-release.apk" ]; then
    cp -f "${BUILD_APK_DIR}/app-release.apk" "${OUTPUT_DIR}/RemoteAccessPlatform-${APP_VERSION}.apk"
fi

if [ -f "${BUILD_APK_DIR}/app-arm64-v8a-release.apk" ]; then
    cp -f "${BUILD_APK_DIR}/app-arm64-v8a-release.apk" "${OUTPUT_DIR}/RemoteAccessPlatform-${APP_VERSION}-arm64-v8a.apk"
fi

if [ -f "${BUILD_BUNDLE_DIR}/app-release.aab" ]; then
    cp -f "${BUILD_BUNDLE_DIR}/app-release.aab" "${OUTPUT_DIR}/RemoteAccessPlatform-${APP_VERSION}.aab"
fi

# Generate SHA-256 and MD5 Checksums
echo -e "${CYAN}--> Generating checksums...${NC}"
CHECKSUM_FILE="${PROJECT_ROOT}/dist/mobile/checksums.txt"
mkdir -p "${PROJECT_ROOT}/dist/mobile"

{
    echo "Remote Access Platform Mobile V${APP_VERSION} Release Checksums"
    echo "Date: $(date)"
    echo "========================================================================="
    for f in "${OUTPUT_DIR}"/*; do
        if [ -f "$f" ]; then
            FNAME="$(basename "$f")"
            if command -v sha256sum &>/dev/null; then
                echo "SHA-256 ($FNAME): $(sha256sum "$f" | awk '{print $1}')"
            fi
            if command -v md5sum &>/dev/null; then
                echo "MD5    ($FNAME): $(md5sum "$f" | awk '{print $1}')"
            fi
            echo "---"
        fi
    done
} > "${CHECKSUM_FILE}"

echo -e "${GREEN}=========================================================================${NC}"
echo -e "${GREEN}ANDROID PACKAGING COMPLETE!${NC}"
echo -e "${GREEN}Artifacts staged in: ${OUTPUT_DIR}${NC}"
echo -e "${GREEN}Checksums written to: ${CHECKSUM_FILE}${NC}"
echo -e "${GREEN}=========================================================================${NC}"
