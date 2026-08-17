# Production Packaging & Standalone Release Bundler Script
# Packages rap-client, rap-agent, QML resources, runtime shared libraries,
# systemd service units, and desktop shortcuts into a redistributable tarball.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

BUILD_DIR="${ROOT_DIR}/build"
DIST_DIR="${ROOT_DIR}/dist"
PKG_NAME="rap-v1.0.0-linux-x86_64"
STAGE_DIR="${DIST_DIR}/${PKG_NAME}"

echo "================================================================="
echo "       REMOTE ACCESS PLATFORM - PRODUCTION PACKAGING TOOL        "
echo "================================================================="

echo "[+] Step 1: Building optimized Release mode binaries (-O3, Stripped)..."
RELEASE_BUILD_DIR="${ROOT_DIR}/build-release"
mkdir -p "${RELEASE_BUILD_DIR}"
cd "${RELEASE_BUILD_DIR}"
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="-O3" "${ROOT_DIR}"
make -j$(nproc)

BUILD_DIR="${RELEASE_BUILD_DIR}"

echo "[+] Preparing release staging directory at ${STAGE_DIR}..."
rm -rf "${STAGE_DIR}"
mkdir -p "${STAGE_DIR}/bin"
mkdir -p "${STAGE_DIR}/lib"
mkdir -p "${STAGE_DIR}/qml"
mkdir -p "${STAGE_DIR}/share/applications"
mkdir -p "${STAGE_DIR}/share/systemd"

echo "[+] Copying & stripping production binaries and QML assets..."
cp "${BUILD_DIR}/apps/client/rap-client" "${STAGE_DIR}/bin/"
cp "${BUILD_DIR}/apps/agent/rap-agent" "${STAGE_DIR}/bin/"
strip --strip-unneeded "${STAGE_DIR}/bin/rap-client" "${STAGE_DIR}/bin/rap-agent" 2>/dev/null || true

# Copy QML interface templates
cp -r "${ROOT_DIR}/apps/client/qml/"* "${STAGE_DIR}/qml/"

# Copy systemd unit and desktop files
cp "${DIST_DIR}/rap-client.desktop" "${STAGE_DIR}/share/applications/"
cp "${DIST_DIR}/rap-agent.service" "${STAGE_DIR}/share/systemd/"

# Copy license & documentation notices
cp "${ROOT_DIR}/THIRD_PARTY_LICENSES.md" "${STAGE_DIR}/"
cp "${ROOT_DIR}/README.md" "${STAGE_DIR}/" 2>/dev/null || true

echo "[+] Bundling minimal required dependent dynamic libraries..."
QT_LIB_DIR="/lib/x86_64-linux-gnu"
for lib in libQt6Quick.so.6 libQt6Gui.so.6 libQt6Qml.so.6 libQt6Network.so.6 libQt6Core.so.6 libQt6OpenGL.so.6 libQt6DBus.so.6; do
    if [ -f "${QT_LIB_DIR}/${lib}" ]; then
        cp "${QT_LIB_DIR}/${lib}" "${STAGE_DIR}/lib/"
    fi
done

echo "[+] Creating Standalone App Launcher & Direct Runner Script (run.sh)..."
cat << 'EOF' > "${STAGE_DIR}/run.sh"
#!/usr/bin/env bash
# Direct Launcher for Remote Access Platform Client (No installation required)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LD_LIBRARY_PATH="${SCRIPT_DIR}/lib:${LD_LIBRARY_PATH}"
export QML2_IMPORT_PATH="${SCRIPT_DIR}/qml:${QML2_IMPORT_PATH}"
echo "[+] Starting Remote Access Platform..."
exec "${SCRIPT_DIR}/bin/rap-client" "$@"
EOF
chmod +x "${STAGE_DIR}/run.sh"
cp "${STAGE_DIR}/run.sh" "${STAGE_DIR}/rap-client-launcher.sh"

echo "[+] Creating System-Wide Deployment Installer Script (install.sh)..."
cat << 'EOF' > "${STAGE_DIR}/install.sh"
#!/usr/bin/env bash
set -e
TARGET_PREFIX="${1:-/opt/rap}"
echo "================================================================="
echo "   REMOTE ACCESS PLATFORM - AUTOMATED SYSTEM-WIDE INSTALLER      "
echo "================================================================="
echo "[+] Installing binaries and assets to ${TARGET_PREFIX}..."
mkdir -p "${TARGET_PREFIX}/bin"
mkdir -p "${TARGET_PREFIX}/lib"
mkdir -p "${TARGET_PREFIX}/qml"
mkdir -p "${TARGET_PREFIX}/share/applications"

cp -r bin/* "${TARGET_PREFIX}/bin/"
cp -r lib/* "${TARGET_PREFIX}/lib/" 2>/dev/null || true
cp -r qml/* "${TARGET_PREFIX}/qml/"
cp run.sh "${TARGET_PREFIX}/bin/rap-client-launcher"
chmod +x "${TARGET_PREFIX}/bin/rap-client-launcher"

if [ -d "/usr/share/applications" ] && [ -w "/usr/share/applications" ]; then
    cp share/applications/rap-client.desktop /usr/share/applications/
    echo "  ✓ Desktop application shortcut installed to /usr/share/applications/rap-client.desktop"
fi

if [ -d "/etc/systemd/system" ] && [ -w "/etc/systemd/system" ]; then
    cp share/systemd/rap-agent.service /etc/systemd/system/
    echo "  ✓ Host Agent systemd daemon installed to /etc/systemd/system/rap-agent.service"
    echo "    Enable background host daemon: sudo systemctl enable --now rap-agent"
fi

echo "================================================================="
echo "        🎉 INSTALLATION COMPLETED SUCCESSFULLY!                 "
echo "  Direct Execution: ${TARGET_PREFIX}/bin/rap-client-launcher"
echo "================================================================="
EOF
chmod +x "${STAGE_DIR}/install.sh"

echo "[+] Creating release tarball archive..."
cd "${DIST_DIR}"
tar -czf "${PKG_NAME}.tar.gz" "${PKG_NAME}"

echo "================================================================="
echo " SUCCESS: Release package created at:"
echo "   ${DIST_DIR}/${PKG_NAME}.tar.gz"
echo "================================================================="
