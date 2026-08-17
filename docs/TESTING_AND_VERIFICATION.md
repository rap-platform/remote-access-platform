# Remote Access Platform — Testing & Verification Guide

> **Live Document Version:** 1.3.0  
> **Target Audience:** Developers, QA Engineers, Security Auditors, Penetration Testers  
> **Source Repository:** [`Remote-Desktop`](https://github.com/remote-desktop/remote-desktop)

---

## 1. Overview & Verification Scope

This document provides a comprehensive, step-by-step testing and verification guide for the **Remote Access Platform**. It details how to validate the system across three primary tiers:

1. **User Functional Verification**: End-to-end interactive desktop streaming, real-time remote input injection (pointer movement, left/right clicks, wheel scrolling), QML UI theme engine, and session lifecycle.
2. **Security & Cryptographic Audit (Milestones 5, 6 & 7)**: STRIDE threat model compliance (`docs/security/threat-model.md`), network wire packet inspection (`tcpdump`), ChaCha20-Poly1305 AEAD payload encryption for video & input events, X25519 ECDH key agreement, active MITM bit-flip tamper rejection, and **1,000,000 iterations continuous fuzzing test benchmark**.
3. **Cloud Control Plane & Microservices (Milestone 8)**: Device Identity Management (`rap-identity`), Rendezvous & Session Signaling (`rap-signaling`), and HTTP API Gateway REST routing (`rap-api-gateway`).
4. **Automated Quality Gate Testing**: Static analysis, formatting compliance, and CTest/Cargo test suite execution.

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

### 3.2 Automated Cryptographic Known-Answer Test Suite

Run the standalone C++ cryptographic unit test binary:

```bash
./build/libs/security/test_crypto
```

### 3.3 1,000,000 Iterations Continuous Stress Fuzzing Benchmark (Milestone 7)

Run the standalone protocol fuzzing stress test binary:

```bash
./build/libs/protocol/test_protocol_fuzz
```

---

## 4. Tier 3: Rust Control Plane & Microservices Verification Suite (Milestone 8)

To manually run the Rust Control Plane test suite:

```bash
cargo test --workspace
```

**Expected Test Output**:
```text
running 1 test
test tests::test_device_registration_and_authentication_flow ... ok (rap-identity)

running 1 test
test tests::test_signaling_session_lifecycle ... ok (rap-signaling)

running 2 tests
test tests::test_api_gateway_health_check ... ok (rap-api-gateway)
test tests::test_api_gateway_registration_and_session_initiation ... ok (rap-api-gateway)
```

---

## 5. Tier 4: Manual Build Execution & Quality Gate Pipeline

To build and run all test targets manually:

```bash
./tools/build.sh
```

---

## 6. Maintenance & Governance Rule

Per **Rule 0.3** of [`AGENT_RULES.md`](../AGENT_RULES.md), whenever new features, network protocol frames, video codecs, or security subsystems are added:
- Developers and AI agents **MUST** update this file (`docs/TESTING_AND_VERIFICATION.md`) with the new step-by-step verification commands and security audit procedures.
