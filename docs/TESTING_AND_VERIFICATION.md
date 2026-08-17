# Remote Access Platform — Testing & Verification Guide

> **Live Document Version:** 1.0.0  
> **Target Audience:** Developers, QA Engineers, Security Auditors, Penetration Testers  
> **Source Repository:** [`Remote-Desktop`](https://github.com/remote-desktop/remote-desktop)

---

## 1. Overview & Verification Scope

This document provides a comprehensive, step-by-step testing and verification guide for the **Remote Access Platform**. It details how to validate the system across three primary tiers:

1. **User Functional Verification**: End-to-end interactive desktop streaming, QML UI theme engine, and session lifecycle.
2. **Security & Cryptographic Audit (Milestone 5)**: Network wire packet inspection, ChaCha20-Poly1305 AEAD payload encryption, X25519 ECDH key agreement, and active MITM bit-flip tamper rejection.
3. **Automated Quality Gate Testing**: Static analysis, formatting compliance, and CTest/Cargo test suite execution.

---

## 2. Tier 1: User Functional Verification Suite

### 2.1 Starting the Host Agent Daemon

Launch the headless agent binary in your first desktop terminal window:

```bash
./build/apps/agent/rap-agent
```

**Expected Console Output**:
```text
[Agent] Remote Desktop Headless Host Agent starting up...
[Agent] Screen capture initialized: "Linux X11 Capture Backend"
[Agent] E2E Session Encryption Layer (ChaCha20-Poly1305 / X25519) Initialized.
[Agent] TCP Server listening on port 18443. Waiting for desktop client connections...
```

### 2.2 Starting the Desktop Viewer

Launch the desktop client application in your second desktop terminal window:

```bash
./build/apps/client/rap-client
```

**Steps to Connect**:
1. In the top navigation bar, ensure the target host is set to `127.0.0.1` and port `18443`.
2. Click **Connect Session**.
3. Verify that the UI status bar updates to:
   ```text
   Status: Connected — Encrypted Desktop Session Active
   ```
4. Verify that live desktop video streams smoothly at ~30 FPS inside the main viewport.

### 2.3 Verification of Clean Session Termination

1. Click **Disconnect Session** or press `Ctrl+C` in the viewer terminal.
2. Verify host agent output logs:
   ```text
   [Agent] Client disconnected.
   ```
3. Confirm that `rap-client` closes without `malloc_consolidate()` memory warnings or core dumps.

---

## 3. Tier 2: Security & Cryptographic Audit Verification (Milestone 5)

### 3.1 Network Wire Packet Capture Inspection (`tcpdump`)

To prove that desktop screen pixels are encrypted on the network interface and unreadable by unauthorized relays or eavesdroppers:

1. Start streaming between `rap-agent` and `rap-client`.
2. Execute `tcpdump` on the loopback interface:
   ```bash
   sudo tcpdump -i lo -X -n port 18443
   ```
3. **Audit Findings Checklist**:
   - [x] Header contains `RAP0` (`0x52415030`) protocol framing magic bytes.
   - [x] Payload data consists entirely of randomized high-entropy ciphertext.
   - [x] Zero raw RGBA pixel buffers, image headers (PNG/BMP), or plaintext desktop contents appear on the wire.

### 3.2 Automated Cryptographic Known-Answer Test Suite

Run the standalone C++ cryptographic unit test binary:

```bash
./build/libs/security/test_crypto
```

**Expected Output**:
```text
Config: Using QtTest library 6.x
PASS   : TestCryptoEngine::initTestCase()
PASS   : TestCryptoEngine::testKeyPairGeneration()     # Ed25519/X25519 identity keypairs
PASS   : TestCryptoEngine::testECDHKeyDerivation()       # Diffie-Hellman key agreement
PASS   : TestCryptoEngine::testEncryptDecryptRoundtrip() # ChaCha20-Poly1305 AEAD cipher
PASS   : TestCryptoEngine::testTamperDetection()        # Poly1305 MAC bit-flip rejection
PASS   : TestCryptoEngine::cleanupTestCase()
Totals: 6 passed, 0 failed, 0 skipped, 0 blacklisted, 0ms
```

### 3.3 Active MITM Bit-Flip Tamper Rejection Test

To test active Man-In-The-Middle (MITM) tamper resistance:
1. When any single bit of an encrypted network payload is mutated in transit, the Poly1305 authentication tag verification fails in constant time.
2. The client logger outputs:
   ```text
   [Client] E2E Crypto Authentication Failed! Dropping corrupted or tampered frame payload.
   ```
3. Corrupted or tampered frame payloads are dropped immediately before any memory allocation or rendering occurs.

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
| `test_hot_reload` | `apps/client` | QML file watcher devtool |
| `test_qml_skeleton` | `apps/client` | QML engine startup & ThemePalette bindings |
| `cargo test` | `services/` | Rust microservices & cross-lang protocol roundtrips |

---

## 5. Maintenance & Governance Rule

Per **Rule 0.3** of [`AGENT_RULES.md`](../AGENT_RULES.md), whenever new features, network protocol frames, video codecs, or security subsystems are added:
- Developers and AI agents **MUST** update this file (`docs/TESTING_AND_VERIFICATION.md`) with the new step-by-step verification commands and security audit procedures.
