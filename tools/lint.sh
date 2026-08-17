#!/usr/bin/env bash
# Centralized Reusable Static Analysis & Format Checker Script
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${ROOT_DIR}"

echo "=== Quality Gate Step 1: Static Analysis & Format Verification ==="

if command -v clang-format &> /dev/null; then
    echo "[+] Checking C++ Formatting with clang-format..."
    find apps/ libs/ -name '*.cpp' -o -name '*.h' | xargs clang-format --dry-run --Werror
else
    echo "[!] clang-format not installed locally. Run ./tools/setup_deps.sh to install it (enforced in CI)."
fi

if command -v cppcheck &> /dev/null; then
    echo "[+] Running C++ Static Analysis with cppcheck..."
    cppcheck --enable=warning,performance,portability,style \
             --error-exitcode=1 \
             --suppress=missingIncludeSystem \
             --suppress=unusedFunction \
             --suppress=unknownMacro \
             --inline-suppr \
             apps/ libs/
else
    echo "[!] cppcheck not installed locally. Run ./tools/setup_deps.sh to install it (enforced in CI)."
fi

echo "[+] Checking QML Hex Color Enforcer (No hardcoded hex colors outside theme/)..."
HEX_VIOLATIONS=$(find apps/client/qml/ -name '*.qml' ! -path '*/theme/*' -exec grep -Hn '#[0-9a-fA-F]\{3,8\}' {} + || true)
if [ -n "${HEX_VIOLATIONS}" ]; then
    echo "[!] QML Theme Violation: Hardcoded hex color literals found outside theme/:"
    echo "${HEX_VIOLATIONS}"
    exit 1
else
    echo "[+] QML Theme Check Passed: Zero hardcoded hex colors outside theme/."
fi

echo "[+] Checking Rust Formatting with rustfmt..."
cargo fmt --check

echo "[+] Running Rust Clippy Linters..."
cargo clippy --workspace --all-targets -- -D warnings

echo "=== All Quality Gate Static Analysis Checks Passed! ==="
