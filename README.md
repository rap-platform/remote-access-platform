# Cross-Platform Remote Access & Device Management Platform

[![CI Matrix](https://github.com/remote-desktop/platform/actions/workflows/ci.yml/badge.svg)](https://github.com/remote-desktop/platform/actions/workflows/ci.yml)
[![License: LGPLv3 / Proprietary](https://img.shields.io/badge/License-LGPLv3%20%2F%20Proprietary-blue.svg)](./SECURITY.md)

An enterprise-grade, cross-platform remote desktop and device management system (AnyDesk/RustDesk/MeshCentral class) built with high performance, strict cryptographic security, and memory safety designed in from commit #1.

---

## 1. Technology Stack Decisions

| Subsystem | Technology | Rationale |
|---|---|---|
| **Desktop Client UI** | **Qt 6 (LGPLv3) + QML** | Single unified QML view tree across Windows, Linux, macOS. Dynamically linked for LGPLv3 compliance. |
| **Client / Agent Core** | **C++20** | High performance, native OS API integration (DXGI, X11/PipeWire, ScreenCaptureKit), GStreamer interop. |
| **Backend Services** | **Rust ONLY** | Memory safety across 100% of the server attack surface (`#![forbid(unsafe_code)]`). Built with Axum, Quinn, and Tokio. |
| **Video Pipeline** | **GStreamer / FFmpeg** | Hardware acceleration abstraction (NVENC, VAAPI, QSV, VideoToolbox). |
| **Transport** | **QUIC / TLS 1.3 TCP** | Low-latency UDP stream multiplexing with NAT traversal and TLS 1.3 encryption. |
| **End-to-End Crypto** | **libsodium / RustCrypto** | X25519 ECDH key agreement + XChaCha20-Poly1305 payload encryption. Relay never sees plaintext. |

---

## 2. Monorepo Directory Structure

```
remote-platform/
├── apps/
│   ├── client/                     # Qt6/QML viewer (Win/Linux/macOS)
│   └── agent/                      # Headless Host Agent (Win/Linux/macOS/Embedded)
├── libs/                           # Platform-agnostic C++ libraries
│   ├── protocol/                   # Protobuf schema bindings
│   ├── transport/                  # QUIC/TCP/UDP abstraction
│   ├── security/                   # libsodium crypto wrappers
│   ├── common/                     # QLoggingCategory & central log sinks
│   └── testing/                    # Shared C++ test fixtures
├── services/                       # Rust microservices
│   ├── identity/                   # Device identity & cert issuance
│   ├── signaling/                  # Rendezvous WebSocket/QUIC
│   ├── relay/                      # High-throughput UDP/QUIC packet forwarder
│   ├── api-gateway/                # Admin REST/gRPC API
│   ├── audit/                      # Immutable audit log ingestion
│   └── shared/                     # Shared Rust crates (`rap-shared`)
├── proto/                          # Protobuf schemas (single source of truth)
├── e2e/                            # Cross-service E2E integration test scenarios
├── docs/                           # Architecture docs, threat models & implementation log
├── CODING_STANDARDS.md             # C++, Rust, QML coding guidelines
├── SECURITY.md                     # Security disclosure policy & SLA
└── AGENT_RULES.md                  # Workspace governance rules for AI & human developers
```

---

## 3. Prerequisites & Environment Setup

- **C++ Compiler**: GCC 13+, Clang 16+, or MSVC 2022+ (supporting C++20 standard).
- **CMake**: Version 3.22 or higher.
- **Ninja**: Version 1.10 or higher.
- **Qt 6**: Version 6.5+ (specifically `Qt6Core`, `Qt6Gui`, `Qt6Quick`, `Qt6Test`, `Qt6QuickTest`).
- **Rust Toolchain**: 1.80+ (`rustc`, `cargo`, `rustfmt`, `clippy`).

---

## 4. Building the Project

### Building C++ & QML Targets (CMake)

```bash
# 1. Configure the build tree with CMake & Ninja
cmake -B build -S . -G Ninja -DCMAKE_BUILD_TYPE=Debug -DENABLE_TESTING=ON

# 2. Compile all C++ targets
cmake --build build
```

### Building Rust Backend Microservices (Cargo)

```bash
# Build all Rust crates in the workspace
cargo build --workspace
```

---

## 5. Running Tests

### Running C++ & QML Unit Tests (CTest)

```bash
# Execute unit tests via CTest
ctest --test-dir build --output-on-failure
```

*Runs both C++ Qt Tests (`test_logging`) and QML Qt Quick Tests (`test_qml_skeleton`).*

### Running Rust Unit & Integration Tests (Cargo Test)

```bash
# Execute unit tests across all backend crates
cargo test --workspace
```

### Static Analysis & Formatting Validation

```bash
# C++ Format Check
find apps/ libs/ -name '*.cpp' -o -name '*.h' | xargs clang-format --dry-run --Werror

# Rust Format & Linter Check
cargo fmt --check
cargo clippy --workspace --all-targets -- -D warnings
```

---

## 6. Live Documentation & Architecture Specs

- **Project Roadmap & Feature Matrix**: [`ROADMAP.md`](./ROADMAP.md)
- **Developer Onboarding & Contributing Guide**: [`CONTRIBUTING.md`](./CONTRIBUTING.md)
- **Architecture Blueprint**: [`docs/REMOTE-DESKTOP-ARCHITECTURE.md`](./docs/REMOTE-DESKTOP-ARCHITECTURE.md)
- **Live Implementation Log**: [`docs/IMPLEMENTATION_LOG.md`](./docs/IMPLEMENTATION_LOG.md) *(Continuously updated for every milestone)*
- **Implementation Plan & Checklist**: [`docs/architecture_and_implementation_plan.md`](./docs/architecture_and_implementation_plan.md)
- **Testing Strategy**: [`docs/testing-strategy.md`](./docs/testing-strategy.md)
- **Coding Standards**: [`CODING_STANDARDS.md`](./CODING_STANDARDS.md)
- **Security Policy**: [`SECURITY.md`](./SECURITY.md)


---

## 7. License & Compliance Notice

This project utilizes **Qt 6 under the LGPLv3 license** with dynamic linking only (`BUILD_SHARED_LIBS=ON`). Host agent components remain strictly Qt-free. Proprietary application components are cleanroom implemented without any AGPL/GPL copied code.
