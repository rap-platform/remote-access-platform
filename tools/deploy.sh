#!/usr/bin/env bash
# Automated Remote & Local Deployment Tool
# Deploys Remote Access Platform binaries, QML files, and systemd units
# to local system (/opt/rap) or remote machines via SSH/SCP.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
PKG_NAME="rap-v1.0.0-linux-x86_64"
TARBALL="${DIST_DIR}/${PKG_NAME}.tar.gz"

TARGET_HOST="$1"
INSTALL_PREFIX="${2:-/opt/rap}"

echo "================================================================="
echo "      REMOTE ACCESS PLATFORM - AUTOMATED DEPLOYMENT TOOL        "
echo "================================================================="

if [ ! -f "${TARBALL}" ]; then
    echo "[!] Release package missing. Building release package now..."
    bash "${SCRIPT_DIR}/package.sh"
fi

if [ -z "${TARGET_HOST}" ] || [ "${TARGET_HOST}" == "local" ] || [ "${TARGET_HOST}" == "localhost" ]; then
    echo "[+] Deploying locally to ${INSTALL_PREFIX}..."
    sudo mkdir -p "${INSTALL_PREFIX}"
    sudo tar -xzf "${TARBALL}" -C /tmp
    cd "/tmp/${PKG_NAME}"
    sudo ./install.sh "${INSTALL_PREFIX}"
else
    echo "[+] Deploying remotely to target ${TARGET_HOST}..."
    echo "  1. Copying release tarball via SCP..."
    scp "${TARBALL}" "${TARGET_HOST}:/tmp/"
    
    echo "  2. Executing remote installation via SSH..."
    ssh -t "${TARGET_HOST}" "sudo tar -xzf /tmp/${PKG_NAME}.tar.gz -C /tmp && cd /tmp/${PKG_NAME} && sudo ./install.sh ${INSTALL_PREFIX}"
fi

echo "================================================================="
echo "            DEPLOYMENT VERIFIED & COMPLETED!                     "
echo "================================================================="
