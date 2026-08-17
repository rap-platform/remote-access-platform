#!/usr/bin/env bash
# MASTER ALL-IN-ONE PIPELINE SCRIPT
# Handles: Build -> Static Analysis & SAST -> Test Suite Execution -> Release Packaging -> Deployment/Execution

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

ACTION="${1:-all}"
TARGET="${2:-local}"

cd "${ROOT_DIR}"

echo "================================================================="
echo "      REMOTE ACCESS PLATFORM - MASTER AUTOMATION PIPELINE       "
echo "================================================================="
echo "Action Mode : ${ACTION}"
echo "Deploy Target: ${TARGET}"
echo "================================================================="

run_build() {
    echo "[+] Step 1: Building C++ & Rust Workspace Targets..."
    bash "${SCRIPT_DIR}/build.sh"
}

run_lint() {
    echo "[+] Step 2: Running Quality Gate Lints, SAST, & Agent Rules..."
    bash "${SCRIPT_DIR}/lint.sh"
}

run_tests() {
    echo "[+] Step 3: Executing CTest & Cargo Unit/Integration Test Suites..."
    bash "${SCRIPT_DIR}/test.sh"
}

run_package() {
    echo "[+] Step 4: Packaging Standalone Release Distribution..."
    bash "${SCRIPT_DIR}/package.sh"
}

run_deploy() {
    echo "[+] Step 5: Deploying Release Artifacts..."
    bash "${SCRIPT_DIR}/deploy.sh" "${TARGET}"
}

run_app() {
    echo "[+] Step 6: Launching Remote Access Platform Unified Application..."
    if [ -f "${ROOT_DIR}/build/apps/client/rap-client" ]; then
        exec "${ROOT_DIR}/build/apps/client/rap-client" "$@"
    else
        echo "[!] Binary build/apps/client/rap-client not found!"
        exit 1
    fi
}

case "${ACTION}" in
    build)
        run_build
        ;;
    lint)
        run_lint
        ;;
    test)
        run_build
        run_tests
        ;;
    package)
        run_build
        run_package
        ;;
    deploy)
        run_build
        run_package
        run_deploy
        ;;
    run)
        run_build
        run_app
        ;;
    all|*)
        run_build
        run_lint
        run_tests
        run_package
        run_deploy
        echo "================================================================="
        echo "   🎉 ALL PIPELINE STAGES COMPLETED SUCCESSFULLY (100% VERIFIED) "
        echo "================================================================="
        ;;
esac
