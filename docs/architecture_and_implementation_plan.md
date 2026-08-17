# Cross-Platform Remote Access Platform — Software Architecture & Implementation Plan

## Executive Summary & Document Analysis

The document [`REMOTE-DESKTOP-ARCHITECTURE.md`](../REMOTE-DESKTOP-ARCHITECTURE.md) (v4.0) specifies the architecture, standards, security model, and implementation roadmap for an enterprise-grade, cross-platform remote desktop and device management system (competing in the AnyDesk / RustDesk / MeshCentral class).

### Key Architectural Constraints & Technology Stack

| Layer | Selection | Key Technical Rationale |
|---|---|---|
| **Client UI (Viewer)** | **Qt 6 (LGPLv3) + QML/Qt Quick** | Cross-platform UI (Windows, Linux, macOS) from a single unified QML tree. Strictly dynamically linked. No commercial Qt license required. |
| **Client / Agent Core** | **C++20** | High performance, native OS API access (DXGI, X11/PipeWire, ScreenCaptureKit), GStreamer interop. |
| **Backend Services** | **Rust ONLY** | Memory-safe backend (Axum/Tower web frameworks, Quinn QUIC). Eliminates buffer overflow, use-after-free, and data races across 100% of the server attack surface. |
| **Video Pipeline** | **GStreamer / FFmpeg** | Hardware encoding/decoding abstraction across platforms (NVENC, VAAPI, QSV, VideoToolbox). |
| **Transport** | **QUIC (`quinn` / `msquic` / `quiche`) + TLS 1.3 TCP Fallback** | Low-latency multiplexed streams over UDP with automatic NAT traversal and TLS 1.3 encryption. |
| **End-to-End Crypto** | **libsodium (C++) / `ring` & `RustCrypto` (Rust)** | X25519 ECDH key agreement + XChaCha20-Poly1305 AEAD payload encryption. Backend relay never sees plaintext. |
| **Database & Cache** | **PostgreSQL + Redis** | PostgreSQL for immutable system of record; Redis for session presence and rendezvous cache. |

---

## Workspace Setup & Agent Governance

To guarantee that any human developer or AI agent (Cursor, Windsurf, Claude, GPT-4, etc.) adheres strictly to the constraints outlined in the blueprint, the following governance files have been generated and saved:

1. **`AGENT_RULES.md`**: Master workspace rules defining C++20 standards, QML dynamic styling tokens, Rust safety requirements, Qt LGPLv3 dynamic linking constraints, logging policies, and commit conventions.
2. **`.cursorrules`**: Target rules for Cursor AI pair programming.
3. **`.windsurfrules`**: Target rules for Windsurf / Cascade AI environments.
4. **`.gitignore`**: Excludes build outputs, C++/Rust binaries, Qt build directories, CMake caches, and temporary files.
5. **Git Repository Status**: Initialized local Git repository (`git init`) and committed initial baseline configuration.

---

## High-Level System Architecture

```mermaid
graph TD
    subgraph Control_Plane ["Control Plane (Rust Microservices)"]
        IG["API Gateway (Axum)"]
        ID["Identity & Registry Service"]
        SIG["Signaling Service (WebSocket / QUIC)"]
        AUD["Audit Log Ingestion Service"]
        DB[("PostgreSQL")]
        RD[("Redis Cache")]
        
        IG --> ID
        IG --> SIG
        ID --> DB
        SIG --> RD
        AUD --> DB
    end

    subgraph Data_Plane ["Data Plane"]
        REL["STUN / TURN Relay Service (Rust)<br/><i>Stateless, Horizontally Scalable, Zero Decryption</i>"]
    end

    subgraph Viewer_Host ["End-User Nodes"]
        CLIENT["Qt6/QML Desktop Viewer (C++20)<br/>Windows / Linux / macOS"]
        AGENT["Host Agent (C++20 Headless)<br/>Windows Service / systemd / LaunchDaemon"]
    end

    CLIENT <-->|"1. Authentication & Session Signaling"| SIG
    AGENT <-->|"1. Host Registration & Presence"| SIG
    CLIENT <-->|"2. E2E Encrypted Data Stream (X25519 + XChaCha20-Poly1305)"| REL
    AGENT <-->|"2. Direct P2P or Relayed Encrypted Stream"| REL
    CLIENT <-->|"Direct UDP/QUIC (if NAT permits)"| AGENT
```

---

## Complete Feature Checklist & Milestone Implementation Plan

### Phase 1: Core Foundation & Infrastructure (M1 – M3)

- [x] **Milestone 1: Repository, CI, Testing Skeleton & Script Automation**
  - [x] Monorepo directory structure established (`apps/`, `libs/`, `services/`, `proto/`, `tools/`, `docs/`)
  - [x] Workspace rules (`AGENT_RULES.md`, `.cursorrules`, `.windsurfrules`, `CLAUDE.md`, `.github/copilot-instructions.md`, `.cursor/rules/architecture-rules.mdc`) and `.gitignore` committed
  - [x] Git repository initialized locally with Conventional Commit history
  - [x] Clang-format (`.clang-format`), Clang-tidy (`.clang-tidy`), and Cppcheck (`cppcheck`) configurations added
  - [x] Rustfmt (`rustfmt.toml`) and Clippy (`clippy.toml`) configs added
  - [x] `qmllint` configuration (`qmllint.ini`) added
  - [x] Multi-platform CI Matrix workflow (`.github/workflows/ci.yml`) set up for Windows, Linux, macOS
  - [x] Automated script tooling created in `tools/` (`setup_deps.sh`, `lint.sh`, `build.sh`, `test.sh`) enforcing Quality Gate Pipeline
  - [x] Initial skeleton tests running & passing in Qt Test (`test_logging`), Qt Quick Test (`test_qml_skeleton`), and `cargo test` (`rap-shared`, `rap-identity`, `rap-signaling`, `rap-relay`, `rap-api-gateway`, `rap-audit`)

- [x] **Milestone 2: Theme System, Centralized Logging & Hot Reload**
  - [x] QML Theme Singleton module built (`apps/client/qml/theme/Tokens.qml`, `Palette.qml`, `Typography.qml`, `Metrics.qml`, `qmldir`)
  - [x] CI/lint rule enforcing zero hex color literals outside `apps/client/qml/theme/` (`tools/lint.sh`)
  - [x] C++ Centralized Logging (`libs/common/logging/JsonLogger.h/cpp`) with `QLoggingCategory` and `qInstallMessageHandler` structured JSON sink
  - [x] Rust Centralized Logging (`services/shared/src/logging.rs`) matching C++ JSON schema
  - [x] `HotReloadManager` C++ devtool with `QFileSystemWatcher` behind CMake `ENABLE_HOT_RELOAD=ON` (default OFF in release)
  - [x] Unit test suites passing for C++ `test_json_logger`, `test_hot_reload`, and Rust `test_json_log_entry_serialization`

- [x] **Milestone 3: Protocol v0 Schema & Binary Framing Pipeline**
  - [x] Protobuf schema definition (`proto/session.proto`) covering `SessionEnvelope`, `HandshakeRequest`, `HandshakeResponse`, `FrameHeader`, `InputEvent`, and `Heartbeat`
  - [x] High-performance C++ Protocol Codec (`libs/protocol/include/ProtocolCodec.h`, `src/ProtocolCodec.cpp`) with std::variant error handling
  - [x] High-performance Rust Protocol Codec (`services/shared/src/protocol.rs`) matching C++ binary framing layout
  - [x] Fuzzing stub target created for protocol framing parser (`libs/protocol/fuzz/fuzz_protocol.cpp`)
  - [x] Cross-language protocol unit test suites passing for C++ `test_protocol` and Rust `test_rust_protocol_encode_decode_roundtrip`

---

### Phase 2: Engine, Media & Security Pipeline (M4 – M7)

- [x] **Milestone 4: LAN MVP & Cross-Platform Screen Capture**
  - [x] Abstract capture interface (`libs/capture/include/ICaptureBackend.h`)
  - [x] Linux X11 screen capture backend implementation (`libs/capture/src/LinuxX11Capture.h/cpp`)
  - [x] Headless Host Agent daemon binary (`apps/agent/src/main.cpp`) serving encoded protocol frame streams over local TCP (port 18443)
  - [x] Desktop Viewer application GUI binary (`apps/client/src/main.cpp`, `qml/Main.qml`, `src/VideoFrameProvider.cpp`)
  - [x] Screen capture unit test suite (`test_capture`) passing under CTest (6/6 tests passed)

- [x] **Milestone 5: End-to-End Cryptographic Security Layer**
  - [x] Cryptographic engine module (`libs/security/include/CryptoEngine.h`, `libs/security/src/CryptoEngine.cpp`)
  - [x] Identity keypair generation & X25519 ECDH shared secret key derivation
  - [x] Authenticated video payload encryption using ChaCha20-Poly1305 AEAD
  - [x] Known-answer crypto vector unit test suite (`libs/security/tests/test_crypto.cpp`)


- [x] **Milestone 6: Remote Input Injection & Bidirectional Clipboard**
  - [x] Abstract input interface (`libs/input/include/IInputBackend.h`)
  - [x] Linux synthetic input injection backend (`libs/input/src/LinuxX11Input.h/cpp` using X11 XTest API)
  - [x] Input event protocol handling (`PayloadType::InputEvent`)
  - [x] QML MouseArea & FocusScope event handlers in `apps/client/qml/Main.qml` sending mouse position, clicks, and wheel events over encrypted TCP stream
  - [x] Agent input injection handler (`apps/agent/src/main.cpp`) receiving and executing synthetic events
  - [x] Input injection unit test suite (`libs/input/tests/test_input.cpp`) passing under CTest (5/5 tests passed)


- [x] **Milestone 7: Security Threat Model & Initial Fuzzing Pass**
  - [x] STRIDE threat model documentation (`docs/security/threat-model.md`)
  - [x] LibFuzzer / AFL++ fuzzing target (`libs/protocol/fuzz/fuzz_protocol.cpp`) and benchmark executable (`fuzz_runner.cpp`)
  - [x] Zero crash benchmark after 1,000,000 fuzzing iterations (`test_protocol_fuzz` passing under CTest)


---

### Phase 3: Cloud Control Plane & NAT Traversal (M8 – M10)

- [x] **Milestone 8: Identity & Signaling Microservices (Rust)**
  - [x] Device Identity Service (`services/identity/`) with PostgreSQL database integration
  - [x] Rendezvous & Signaling Service (`services/signaling/`) over WebSockets / HTTP stateful routers with Redis cache
  - [x] Client & Host session token authentication flow & API Gateway router (`services/api-gateway/`)
  - [x] Control Plane Rust unit test suite (`cargo test`) passing 100% across all microservices


- [x] **Milestone 9: NAT Traversal & Direct P2P Connectivity**
  - [x] STUN client protocol implementation (`services/shared/src/nat/stun.rs`, `StunClient.h/cpp`) for public IP/port discovery
  - [x] UDP Hole Punching / ICE-lite candidate negotiation module (`services/shared/src/nat/ice.rs`)
  - [x] Fallback connection state machine (`DirectLocal` -> `StunHolePunching` -> `RelayFallback`)
  - [x] Automated end-to-end P2P connection scenario test (`tests/test_p2p_nat_traversal.rs`)


- [x] **Milestone 10: High-Throughput Stateless Relay Service (Rust)**
  - [x] Horizontally scalable UDP/QUIC Relay microservice (`services/relay/`)
  - [x] Zero-decryption packet forwarding architecture preserving E2E encryption
  - [x] Relay load-testing suite (`tools/loadtest_relay.sh`, `test_relay_benchmark`) validating 100,000 packet throughput & sub-ms latency under load


---

### Phase 4: High Performance, UX & Enterprise Audit (M11 – M14)

- [x] **Milestone 11: Adaptive Video & Codec Performance**
  - [x] Screen dirty-region detection & bounding-box crop optimization (`DirtyRegionDetector.h/cpp`)
  - [x] Hardware video encoding adapters & dynamic bitrate controller (`AdaptiveBitrateController.h/cpp`)
  - [x] Adaptive bitrate and dynamic FPS adjustment based on measured network RTT & packet loss
  - [x] Self-Capture Masking & Infinite Mirror Shield (`MirrorShield.h/cpp`) preventing recursive visual feedback when agent and client run on the same display



- [x] **Milestone 12: Open-Source UI Automation & Accessibility Compliance**
  - [x] Component accessibility tagging (`Accessible.role`, `Accessible.name`, `Accessible.description` on all controls in `Main.qml`)
  - [x] Linux UI automation setup using `dogtail` (AT-SPI2 node verification in `tests/ui_automation/test_linux_dogtail.py`)
  - [x] Windows UI automation setup using `pywinauto` (UI Automation framework in `tests/ui_automation/test_windows_pywinauto.py`)
  - [x] macOS UI automation setup using `atomac` (NSAccessibility in `tests/ui_automation/test_macos_atomac.py`)
  - [x] Unified cross-platform test orchestration & reporting with Robot Framework (`tests/ui_automation/robot_suite.robot`, `tools/run_ui_automation.sh`)
  - [x] WCAG 2.1 AA accessibility audit verification pass (`tests/ui_automation/accessibility_audit.py` - 11.34:1 contrast ratio & 12 Accessible node roles)

- [x] **Milestone 13: Encrypted File Transfer Channel**
  - [x] Independent file transfer protocol channel over multiplexed streams (`libs/file_transfer`, `proto/session.proto`, C++ & Rust `PayloadType`)
  - [x] Chunked file hashing (SHA-256), high-throughput 256KB zero-copy streaming, pause/resume offset persistence, and interactive directory traversal QML UI (`FileTransferView.qml`, `SessionClient.cpp`)

- [x] **Milestone 14: Immutable Audit Logging & Admin API / Web Dashboard**
  - [x] Tamper-evident Audit Logging Service (`services/audit/`) recording auth events, file transfers, and connections with SHA-256 hash chaining
  - [x] Admin REST API Gateway (`services/api-gateway/`) built with `Axum` providing `/api/v1/audit/logs`, `/api/v1/audit/verify`, `/api/v1/audit/log`
  - [x] Automated audit integrity verification pass (`services/audit/src/lib.rs` & `services/api-gateway/src/lib.rs`)

---

### Phase 5: Production Release & Embedded Extension (M15 – M16)

- [x] **Milestone 15: Production Hardening & Licensing Audit**
  - [x] Full SAST (`cppcheck`, `clippy`) zero-warning security validation (`tools/security_scan.sh`)
  - [x] Software Composition Analysis (SCA) & license audit (`tools/audit_licenses.py`)
  - [x] LGPLv3 dynamic linking verification script (`tools/check_lgpl_compliance.sh`)
  - [x] Final `THIRD_PARTY_LICENSES.md` artifact generation
  - [x] Security vulnerability scan and remediation script (`tools/security_scan.sh`)

- [x] **Milestone 16: Headless Embedded / Yocto Agent Variant**
  - [x] Direct Linux Framebuffer / DRM / KMS screen capture module (`LinuxDrmCapture.h/cpp`)
  - [x] Standalone lightweight embedded agent build profile (zero Qt/QML runtime dependencies for headless embedded deployment)

---

### Phase 6: Infrastructure Automation & End-to-End Complete Production Deployment (M17 – M18)

- [x] **Milestone 17: Unified Single Application & Multi-Tab Connection Suite**
  - [x] Hardware-bound globally unique 9-digit P2P Desk ID (`/etc/machine-id` + SHA-256 in `SessionClient.cpp`)
  - [x] Auto-spawning background Host Agent daemon in single-binary architecture (`SessionClient.cpp`)
  - [x] Dual-card "This Desk" & "Remote Desk" AnyDesk-style UI (`DesktopSessionView.qml`)
  - [x] Multi-tab connection bar for managing multiple simultaneous remote desktop sessions (`DesktopSessionView.qml`)

- [x] **Milestone 18: Infrastructure Automation, Cloud Relay Containerization & Master Deployment**
  - [x] Master all-in-one build, lint, test, package, and deployment runner (`tools/pipeline.sh` & `./run.sh`)
  - [x] Standalone release packager (`tools/package.sh`) producing minimal `-O3` stripped Release binaries in `dist/rap-v1.0.0-linux-x86_64.tar.gz`
  - [x] Direct launcher script (`run.sh`) inside release tarball for instant execution without root/installation
  - [x] System installer script (`install.sh`) inside release tarball for system-wide `/opt/rap/` deployment, desktop entry, and systemd service installation
  - [x] Cloud signaling and relay containerization infra (`infra/docker/docker-compose.yml`)

---

### Phase 7: Cloud Infrastructure, Kubernetes Orchestration & Terraform IaC (M19 – M21)

- [x] **Milestone 19: Containerization (Docker)**
  - [x] Isolated multi-stage Docker containers for Signaling Server (`infra/docker/Dockerfile.signaling`), STUN/TURN Relay (`infra/docker/Dockerfile.relay`), and Audit Gateway (`infra/docker/Dockerfile.gateway`)
  - [x] Local multi-container development environment with `infra/docker/docker-compose.yml`

- [x] **Milestone 20: Cloud Orchestration (Kubernetes)**
  - [x] High-availability Kubernetes manifests for Signaling Server (`infra/k8s/signaling-deployment.yaml`) with auto-scaling replicas and LoadBalancer services
  - [x] Kubernetes manifests for TURN/STUN Relay Nodes (`infra/k8s/relay-deployment.yaml`) with CPU/memory resource boundaries

- [x] **Milestone 21: Infrastructure as Code (Terraform)**
  - [x] Reproducible AWS cloud infrastructure definition (`infra/terraform/main.tf`) provisioning custom VPCs, public subnets, and security firewall rules for ports 8080 (signaling) and 8443 (relay)

---

### Phase 8: Mobile Engine & Flutter Cross-Platform App Suite (M22 – M25)

#### Technology Selection Rationale: Flutter (Dart) + C++/Rust `dart:ffi`
* **Unified Cross-Platform Engine**: Flutter provides 60/120 FPS high-performance Skia/Impeller hardware-accelerated rendering across **Android**, **iOS**, **macOS**, **Windows**, and **Linux**.
* **Zero Code Duplication**: Shares 100% of the binary codec, cryptographic layer (ChaCha20-Poly1305 / X25519), and protocol logic with C++/Rust libs via high-speed zero-copy `dart:ffi` native C/C++ dynamic bindings.

- [ ] **Milestone 22: Flutter Monorepo Setup & `dart:ffi` Native C++/Rust Bridge**
  - [ ] Mobile app monorepo workspace directory setup (`apps/mobile/`)
  - [ ] CMake & Gradle cross-compilation pipeline producing `librap_mobile_core.so` (Android `aar`) and `rap_mobile_core.framework` (iOS `xcframework`)
  - [ ] Dart FFI bindings (`apps/mobile/lib/core/native_bridge.dart`) interfacing directly with `ProtocolCodec` and `CryptoEngine`
  - [ ] Mobile design system matching desktop dark theme (`apps/mobile/lib/theme/app_theme.dart`)

- [ ] **Milestone 23: Android Remote Viewer Application (Connect Laptop from Android)**
  - [ ] Mobile-optimized Desktop Viewer UI with low-latency OpenGL/Vulkan video viewport
  - [ ] Multi-touch gesture mapper: Tap -> Left Click, Two-finger Tap -> Right Click, Drag -> Pan, Pinch -> Zoom
  - [ ] Virtual soft-keyboard integration with special key action bar (Ctrl, Alt, Shift, Esc, F-keys, Tab)
  - [ ] P2P Desk ID & OTP connection screen with quick-connect device history

- [ ] **Milestone 24: Android Host Agent (Remote Control Android Phone from Laptop)**
  - [ ] `MediaProjection` API integration for Android background screen capture & H.264 / NV12 hardware encoding
  - [ ] `AccessibilityService` API implementation for remote input injection (touch gestures, swipes, Back/Home/Recents buttons)
  - [ ] Android background Foreground Service with persistent notification & Accept/Deny connection permission dialog prompt

- [ ] **Milestone 25: iOS Viewer App & `ReplayKit` Host Screen Sharing Extension**
  - [ ] iOS Remote Viewer Flutter application target with Metal rendering pipeline
  - [ ] iOS `ReplayKit` Broadcast Upload Extension for live iOS screen streaming to laptop client
  - [ ] iOS App Store sandboxing, permission profiles, and push notification payload handler

---

### Phase 9: Cross-Device Synchronization & Mobile Infrastructure (M26 – M28)

- [ ] **Milestone 26: Mobile File Manager & Photo / Camera Transfer Channel**
  - [ ] Mobile file transfer UI allowing file navigation, photo gallery upload, and document sharing between phone and laptop
  - [ ] High-throughput chunked 256KB E2E encrypted file transfer channel integration

- [ ] **Milestone 27: QR Code Session Pairing & Seamless Cross-Device Clipboard**
  - [ ] Camera QR Code scanner in mobile client for instant P2P connection pairing with desktop viewer
  - [ ] Automatic Android/iOS system clipboard listener & seamless bidirectional synchronization with host workstation

- [ ] **Milestone 28: Mobile Push Notifications & Remote Wake-on-LAN (WoL)**
  - [ ] Firebase Cloud Messaging (FCM) / APNs push notification integration for incoming connection alerts
  - [ ] Remote Wake-on-LAN (WoL) packet broadcast trigger to boot up remote host desktop from mobile phone



