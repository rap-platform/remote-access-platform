#!/usr/bin/env bash
# Centralized Reusable Test Runner Script (CTest + Cargo Test)
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${ROOT_DIR}"

echo "=== Running Full Test Suite ==="

if [ ! -d "build" ]; then
    echo "[!] Build directory missing. Triggering automated build first..."
    "${SCRIPT_DIR}/build.sh"
fi

echo "[+] Executing C++ & QML Unit Tests via CTest..."
ctest --test-dir build --output-on-failure

echo "[+] Running Automated Agent Rules Quality Gate Audit Suite..."
python3 "${ROOT_DIR}/tests/agent_rules_audit.py"

echo "[+] Running Security SAST Scan & Hardening Auditor..."
bash "${ROOT_DIR}/tools/security_scan.sh"

echo "=== All Test Suites Passed Successfully! ==="
