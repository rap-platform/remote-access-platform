#!/usr/bin/env bash
# Ubuntu 20.04 LTS (glibc 2.31) Fast Cached Container Builder & Packager
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

IMAGE_NAME="rap-ubuntu2004-builder:latest"

echo "================================================================="
echo "   REMOTE ACCESS PLATFORM - UBUNTU 20.04 RELEASE BUILDER        "
echo "================================================================="

# Step 1: Check if cached build image exists, otherwise build it once
if ! docker image inspect "${IMAGE_NAME}" &> /dev/null; then
    echo "[+] Creating cached Ubuntu 20.04 build image (${IMAGE_NAME})... (One-time setup)"
    docker build -t "${IMAGE_NAME}" -f "${SCRIPT_DIR}/Dockerfile.ubuntu2004" "${SCRIPT_DIR}"
else
    echo "[+] Found cached build image (${IMAGE_NAME}). Skipping dependency installation!"
fi

# Step 2: Run build directly inside the pre-configured container
echo "[+] Executing compilation & packaging in container..."
docker run --rm \
  -v "${ROOT_DIR}:/workspace" \
  -w /workspace \
  "${IMAGE_NAME}" bash -c "sed -i 's/\r$//' tools/*.sh && bash ./tools/package.sh"

echo "================================================================="
echo " 🎉 UBUNTU 20.04 RELEASE PACKAGE READY AT:"
echo "    ${ROOT_DIR}/dist/rap-v1.0.0-linux-x86_64.tar.gz"
echo "================================================================="
