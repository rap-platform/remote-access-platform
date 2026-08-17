# Remote Access Platform — Testing & Verification Guide

> **Live Document Version:** 1.1.0  
> **Target Audience:** Developers, QA Engineers, Security Auditors, Penetration Testers  
> **Source Repository:** [`Remote-Desktop`](https://github.com/remote-desktop/remote-desktop)

---

## 1. Overview & Verification Scope

This document provides a comprehensive, step-by-step testing and verification guide for the **Remote Access Platform**. It details how to validate the system across three primary tiers:

1. **User Functional Verification**: End-to-end interactive desktop streaming, real-time remote input injection (pointer movement, left/right clicks, wheel scrolling), QML UI theme engine, and session lifecycle.
2. **Security & Cryptographic Audit (Milestones 5 & 6)**: Network wire packet inspection, ChaCha20-Poly1305 AEAD payload encryption for video & input events, X25519 ECDH key agreement, and active MITM bit-flip tamper rejection.
3. **Automated Quality Gate Testing**: Static analysis, formatting compliance, and CTest/Cargo test suite execution.

---

## 2. Tier 1: User Functional & Input Injection Verification Suite

### 2.1 Starting the Host Agent Daemon

Launch the headless agent binary in your first desktop terminal window:

```bash
./build/apps/agent/rap-agent
```

**Expected Console Output**:
```text
[Agent] Remote Desktop Headless Host Agent starting up...
[Agent] Screen capture initialized: "Linux X11 Capture Backend"
[Agent] Remote Input Injection initialized: "Linux X11 Input Injection Backend"
[Agent] E2E Session Encryption Layer (ChaCha20-Poly1305 / X25519) Initialized.
[Agent] TCP Server listening on port 18443. Waiting for desktop client connections...
```

### 2.2 Starting the Desktop Viewer & Testing Remote Input Injection

Launch the desktop client application in your second desktop terminal window:

```bash
./build/apps/client/rap-client
```

**Steps to Connect & Verify Input Control**:
1. Click **Connect Session**.
2. Verify connection status bar:
   ```text
   Status: Connected — Encrypted Desktop Session Active
   ```
3. **Pointer Movement**: Move your mouse cursor across the `videoSurface` viewport inside the viewer window. Notice that pointer coordinates are normalized to target host display space (`1920x1080`) and sent over the encrypted TCP stream.
4. **Mouse Clicks & Dragging**: Click or right-click any UI element inside the live video surface. Verify synthetic click execution on the target desktop via X11 XTest API.
5. **Scroll Wheel**: Scroll your mouse wheel over the viewport to test remote window scrolling.

---

## 3. Tier 2: Security & Cryptographic Audit Verification

### 3.1 Network Wire Packet Capture Inspection (`tcpdump`)

To prove that input events and video frames are encrypted on the network interface and unreadable by unauthorized relays or eavesdroppers:

1. Start streaming between `rap-agent` and `rap-client`.
2. Execute `tcpdump` on the loopback interface:
   ```bash
   sudo tcpdump -i lo -X -n port 18443
   ```
3. **Audit Findings Checklist**:
   - [x] Protocol magic header `RAP0` (`0x52415030`) framing.
   - [x] Input event payloads (`PayloadType::InputEvent`) are encrypted using ChaCha20-Poly1305 AEAD.
   - [x] Zero plain mouse coordinates, keycodes, or unencrypted keystrokes appear on the wire.

### 3.2 Automated Input Injection Unit Test Suite

Run the standalone input injection C++ unit test binary:

```bash
./build/libs/input/test_input
```

**Expected Output (5/5 Input Tests Passed)**:
```text
Config: Using QtTest library 6.x
PASS   : TestInputBackend::initTestCase()
PASS   : TestInputBackend::testBackendInitialization() # Initializes X11 XTest extension
PASS   : TestInputBackend::testMouseMoveInjection()     # Pointer position normalization & motion
PASS   : TestInputBackend::testMouseButtonInjection()   # Left, right, middle button press/release
PASS   : TestInputBackend::testMouseWheelInjection()    # Scroll wheel delta processing
PASS   : TestInputBackend::testKeyboardInjection()      # Key press & key release events
PASS   : TestInputBackend::cleanupTestCase()
Totals: 7 passed, 0 failed, 0 skipped, 0 blacklisted, 0ms
```

---

## 4. Tier 3: Automated Quality Gate & CI Test Suite

To run the complete static analysis, formatting, and unit testing pipeline prior to code check-in:

```bash
./tools/build.sh
```

### 4.1 Test Targets Executed

| Test Target | Component | Scope |
|---|---|---|
| `test_logging` | `libs/common` | Category filtering & console logging sinks |
| `test_json_logger` | `libs/common` | Structured JSON log schema compliance |
| `test_protocol` | `libs/protocol` | Binary framing codec serialization/deserialization |
| `test_capture` | `libs/capture` | X11 / DRM frame grabber lifecycle & frame rates |
| `test_crypto` | `libs/security` | Cryptographic engine, ECDH key agreement, AEAD |
| `test_input` | `libs/input` | Synthetic mouse & keyboard injection via XTest |
| `test_hot_reload` | `apps/client` | QML file watcher devtool |
| `test_qml_skeleton` | `apps/client` | QML engine startup & ThemePalette bindings |
| `cargo test` | `services/` | Rust microservices & cross-lang protocol roundtrips |

---

## 5. Maintenance & Governance Rule

Per **Rule 0.3** of [`AGENT_RULES.md`](../AGENT_RULES.md), whenever new features, network protocol frames, video codecs, or security subsystems are added:
- Developers and AI agents **MUST** update this file (`docs/TESTING_AND_VERIFICATION.md`) with the new step-by-step verification commands and security audit procedures.
