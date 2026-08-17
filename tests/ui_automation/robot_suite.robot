*** Settings ***
Documentation    Cross-Platform Remote Access Platform UI Automation & Accessibility Test Suite
Library          Process
Library          OperatingSystem

*** Test Cases ***
Verify QML Accessibility WCAG Compliance
    [Documentation]    Audit QML component accessibility attributes and contrast ratios
    ${result}=    Run Process    python3    ${CURDIR}/accessibility_audit.py
    Should Be Equal As Integers    ${result.rc}    0

Verify Linux Dogtail AT-SPI2 Accessibility Tree
    [Documentation]    Validate Linux AT-SPI2 accessibility tree nodes
    ${result}=    Run Process    python3    ${CURDIR}/test_linux_dogtail.py
    Should Be Equal As Integers    ${result.rc}    0

Verify Windows PyWinAuto UI Automation Target
    [Documentation]    Validate Windows UI Automation framework readiness
    ${result}=    Run Process    python3    ${CURDIR}/test_windows_pywinauto.py
    Should Be Equal As Integers    ${result.rc}    0

Verify macOS Atomac NSAccessibility Target
    [Documentation]    Validate macOS NSAccessibility readiness
    ${result}=    Run Process    python3    ${CURDIR}/test_macos_atomac.py
    Should Be Equal As Integers    ${result.rc}    0
