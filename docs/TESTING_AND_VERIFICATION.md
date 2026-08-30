# Remote Access Platform — Testing & Verification Guide

> **Live Document Version:** 1.6.0  
> **Target Audience:** Developers, QA Engineers, Security Auditors, Penetration Testers  
> **Source Repository:** [`Remote-Desktop`](https://github.com/remote-desktop/remote-desktop)

---

## 1. Overview & Verification Scope

This document provides a comprehensive, step-by-step testing and verification guide for the **Remote Access Platform**. It details how to validate the system across primary operational tiers:

1. **User Functional Verification**: End-to-end interactive desktop streaming, real-time remote input injection (pointer movement, left/right clicks, wheel scrolling), QML UI theme engine, and session lifecycle.
2. **Security & Cryptographic Audit (Milestones 5, 6 & 7)**: STRIDE threat model compliance (`docs/security/threat-model.md`), network wire packet inspection (`tcpdump`), ChaCha20-Poly1305 AEAD payload encryption for video & input events, X25519 ECDH key agreement, active MITM bit-flip tamper rejection, and **1,000,000 iterations continuous fuzzing test benchmark**.
3. **Cloud Control Plane & Microservices (Milestone 8)**: Device Identity Management (`rap-identity`), Rendezvous & Session Signaling (`rap-signaling`), and HTTP API Gateway REST routing (`rap-api-gateway`).
4. **NAT Traversal & Direct P2P Connectivity (Milestone 9)**: STUN client protocol (RFC 5389), ICE candidate pair negotiation, UDP hole punching, and connection mode fallback state machine (`DirectLocal` → `StunHolePunching` → `RelayFallback`).
5. **High-Throughput Stateless Relay Service (Milestone 10)**: Zero-decryption packet forwarding architecture (`rap-relay`), session pair routing, real-time telemetry metrics, and **100,000 packet load benchmark**.
6. **Adaptive Video & Codec Performance (Milestone 11)**: Dirty-region detection (`DirtyRegionDetector`), Infinite Mirror Shield loopback exclusion (`MirrorShield`), and Adaptive Bitrate / FPS Scaling (`AdaptiveBitrateController`).
7. **Automated Quality Gate Testing**: Static analysis, formatting compliance, and CTest/Cargo test suite execution.

---

## 2. Tier 1: User Functional & Input Injection Verification Suite

### 2.1 Starting the Host Agent Daemon

Launch the headless agent binary in your first desktop terminal window:

```bash
./build/apps/agent/rap-agent
```

### 2.2 Starting the Desktop Viewer & Testing Remote Input Injection

Launch the desktop client application in your second desktop terminal window:

```bash
./build/apps/client/rap-client
```

---

## 3. Tier 2: Performance & Infinite Mirror Shield Verification (Milestone 11)

Run the standalone C++ performance and mirror shield test binary:

```bash
./build/libs/capture/test_performance
```

**Verified Capabilities**:
- **Dirty Region Bounding-Box Detection**: Sub-sampled scanning calculating minimal dirty bounding boxes for frame delta encoding.
- **Infinite Mirror Shield Loopback Severing**: Overlays non-recursive privacy pattern over viewer window region during same-screen testing.
- **Adaptive Bitrate & FPS Controller**: Dynamically scales target FPS (60 → 30 → 15) and bitrate (8000 Kbps → 2000 Kbps) under measured network congestion.

---

## 4. Tier 3: Security & Cryptographic Audit Verification

Run the standalone C++ cryptographic unit test binary and protocol fuzzing runner:

```bash
./build/libs/security/test_crypto
./build/libs/protocol/test_protocol_fuzz
```

---

## 5. Tier 4: Rust Control Plane & Microservices Verification Suite (Milestones 8 – 10)

To run the full Rust control plane test suite and stateless relay load benchmark:

```bash
cargo test --workspace
./tools/loadtest_relay.sh
```

---

## 6. Tier 5: Manual Build Execution & Quality Gate Pipeline

To build and run all test targets manually:

```bash
./tools/build.sh
```

---

## 7. Maintenance & Governance Rule

Per **Rule 0.3** of [`AGENT_RULES.md`](../AGENT_RULES.md), whenever new features, network protocol frames, video codecs, or security subsystems are added:
- Developers and AI agents **MUST** update this file (`docs/TESTING_AND_VERIFICATION.md`) with the new step-by-step verification commands and security audit procedures.
