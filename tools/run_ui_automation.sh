#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "================================================================="
echo "  Remote Access Platform — UI Automation & Accessibility Gate   "
echo "================================================================="

cd "$WORKSPACE_ROOT"

chmod +x tests/ui_automation/*.py

echo "[+] Step 1: Running WCAG 2.1 AA Accessibility Audit..."
python3 tests/ui_automation/accessibility_audit.py

echo ""
echo "[+] Step 2: Running Linux AT-SPI2 / Dogtail UI Automation Test..."
python3 tests/ui_automation/test_linux_dogtail.py

echo ""
echo "[+] Step 3: Running Windows PyWinAuto UI Automation Test..."
python3 tests/ui_automation/test_windows_pywinauto.py

echo ""
echo "[+] Step 4: Running macOS Atomac NSAccessibility Test..."
python3 tests/ui_automation/test_macos_atomac.py

echo ""
echo "=== UI Automation & Accessibility Verification PASSED 100%! ==="
