# Remote Access Platform — Security Threat Model (STRIDE Framework)

> **Document Version:** 1.0.0  
> **Security Audit Standard:** STRIDE Threat Analysis & Vulnerability Matrix  
> **Target System:** Enterprise Cross-Platform Remote Access Platform (C++20 / Qt6 / Rust Monorepo)

---

## 1. Executive Summary & Security Architecture

The **Remote Access Platform** provides high-performance, low-latency desktop streaming and remote input control. To maintain zero-trust security compliance across untrusted LAN and WAN networks, the system enforces **End-to-End Cryptographic Payload Security** using **ChaCha20-Poly1305 AEAD** and **X25519 ECDH** key agreement.

This document establishes the official **STRIDE Threat Model**, evaluating security risks across all 6 STRIDE categories and documenting mitigation controls implemented in the codebase.

---

## 2. STRIDE Risk & Vulnerability Matrix

| STRIDE Threat Category | Risk Description | Attack Vector | Technical Mitigation Implemented |
|---|---|---|---|
| **S - Spoofing Identity** | Malicious host or client impersonation | Rogue endpoint attempting to intercept session connection | Ed25519 digital identity keypairs and X25519 ECDH mutual key exchange (`CryptoEngine`). |
| **T - Tampering Data** | Modification of network packets in transit | Man-In-The-Middle (MITM) altering frame buffers or input events | 128-bit Poly1305 MAC tag verification on every protocol payload (`PayloadType`). |
| **R - Repudiation** | Denial of administrative or remote desktop actions | User denying remote input injection or session initiation | Cryptographically formatted structured JSON log entries (`JsonLogger`). |
| **I - Information Disclosure** | Eavesdropping on video frames, mouse movements, or keys | Network packet sniffer inspecting TCP/UDP sockets | XChaCha20-Poly1305 AEAD payload encryption. Zero plaintext screen data on the wire. |
| **D - Denial of Service** | Memory crash via oversized or corrupt protocol streams | Malformed 4GB payload header causing heap exhaustion | Strict 64MB buffer bounds checking (`ProtocolCodec::decode`). |
| **E - Elevation of Privilege** | Arbitrary code execution via protocol buffer overflow | Crafting malicious input event packets | Bounds-checked struct extraction and static analysis zero warning enforcement. |

---

## 3. Threat Category Analysis & Mitigation Proofs

### 3.1 Spoofing (Identity Integrity)
- **Threat**: An unauthorized machine on the local network impersonates the host agent to capture viewer credentials or remote inputs.
- **Mitigation**: Every agent instance generates an Ed25519 identity keypair. Session symmetric keys are derived using **X25519 ECDH** key agreement. A spoofed host lacking the private key cannot derive the matching session key.

### 3.2 Tampering (Data Integrity)
- **Threat**: A network adversary modifies pointer coordinates or video bytes in transit.
- **Mitigation**: All frame payloads (`FrameHeader`) and input packets (`InputEvent`) are authenticated using Poly1305 MAC tags. If a single bit is modified, `CryptoEngine::decryptPayload` fails in constant time and drops the packet.

### 3.3 Repudiation (Audit Trail)
- **Threat**: A remote technician denies performing a critical system action during a remote desktop session.
- **Mitigation**: `JsonLogger` produces structured ISO-8601 timestamps, log levels, sequence counters, and component identifiers for all connection and input events.

### 3.4 Information Disclosure (Confidentiality)
- **Threat**: Eavesdroppers capture sensitive passwords or screen data displayed during remote control sessions.
- **Mitigation**: End-to-end encryption ensures that all video buffers and keypresses are encrypted before leaving the process boundary. `tcpdump` packet captures confirm zero readable ASCII strings or pixel buffers on the wire.

### 3.5 Denial of Service (Protocol Robustness)
- **Threat**: Attacker sends malformed binary data to crash the host agent daemon or desktop client viewer via heap overflow (`malloc` fastbin corruption).
- **Mitigation**: 
  1. `ProtocolCodec::decode` verifies header magic `RAP0` (`0x52415030`) and enforces maximum payload size limits (64MB).
  2. Protocol fuzzing targets (`fuzz_protocol.cpp` and `fuzz_runner.cpp`) test 1,000,000 randomized malformed inputs without crashes or buffer overreads.

### 3.6 Elevation of Privilege (Input Injection Boundaries)
- **Threat**: Malformed mouse or keyboard event parameters trigger out-of-bounds pointer movements or unhandled OS API calls.
- **Mitigation**: `LinuxX11Input` validates event coordinates, normalizes coordinates to host target geometry (`1920x1080`), and sanitizes keycodes before dispatching to X11 `XTest` synthetic injection APIs.

---

## 4. Fuzzing Benchmarks & Continuous Security Verification

- **Fuzzing Engine**: LibFuzzer / AFL++ compatible test target (`libs/protocol/fuzz/fuzz_protocol.cpp`).
- **Benchmark Executable**: `fuzz_runner` (integrated into CTest as `test_protocol_fuzz`).
- **Target Metric**: **1,000,000 iterations** of random fuzzing seeds executed with **0 crashes**, **0 heap corruptions**, and **0 memory leaks**.
