#!/usr/bin/env bash
# Centralized Quality Gate & Build Pipeline Script (Lint -> Build -> Test -> Ready)
set -e

BUILD_TYPE="Debug"
CLEAN_BUILD=0
SKIP_LINT=0
SKIP_TEST=0

for arg in "$@"; do
    case $arg in
        --release)
            BUILD_TYPE="Release"
            shift
            ;;
        --clean)
            CLEAN_BUILD=1
            shift
            ;;
        --skip-lint)
            SKIP_LINT=1
            shift
            ;;
        --skip-test)
            SKIP_TEST=1
            shift
            ;;
        *)
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${ROOT_DIR}"

echo "=== Remote Access Platform - Quality Gate Build Pipeline (${BUILD_TYPE}) ==="

# Step 1: Static Analysis & Linting Pass
if [ ${SKIP_LINT} -eq 0 ]; then
    echo "[+] Stage 1: Running Static Analysis & Format Checks..."
    "${SCRIPT_DIR}/lint.sh"
else
    echo "[!] Stage 1: Static Analysis skipped via --skip-lint flag."
fi

# Step 2: Clean build if requested or generator changed
if [ ${CLEAN_BUILD} -eq 1 ] || [ -f "build/CMakeCache.txt" ]; then
    echo "[+] Cleaning previous CMake cache..."
    rm -rf build/CMakeCache.txt build/CMakeFiles
fi

# Step 3: Compilation
echo "[+] Stage 2: Configuring CMake C++ build..."
if command -v ninja &> /dev/null; then
    cmake -B build -S . -G Ninja -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" -DENABLE_TESTING=ON
else
    cmake -B build -S . -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" -DENABLE_TESTING=ON
fi

echo "[+] Compiling C++ targets..."
cmake --build build

echo "[+] Syncing QML template assets..."
mkdir -p build/apps/client/qml
cp -r apps/client/qml/* build/apps/client/qml/

echo "[+] Compiling Rust workspace crates with Cargo..."
if [ "${BUILD_TYPE}" = "Release" ]; then
    cargo build --workspace --release
else
    cargo build --workspace
fi

# Step 4: Test Suite Verification
if [ ${SKIP_TEST} -eq 0 ]; then
    echo "[+] Stage 3: Running Test Suites (CTest + Cargo Test)..."
    "${SCRIPT_DIR}/test.sh"
else
    echo "[!] Stage 3: Test execution skipped via --skip-test flag."
fi

echo "==============================================================="
echo "=== Quality Gate Complete: Build is Verified & Ready to Use! ==="
echo "==============================================================="
