# AI Agent Instructions & Workspace Coding Rules

> **Project:** Enterprise Cross-Platform Remote Access & Device Management Platform  
> **Source of Truth:** [`docs/REMOTE-DESKTOP-ARCHITECTURE.md`](./docs/REMOTE-DESKTOP-ARCHITECTURE.md) (Version 4.0)

---

## 0. Mandatory Rules

### 0.1 Live Technical Documentation Log (`docs/IMPLEMENTATION_LOG.md`)
Every milestone and feature implemented MUST be continuously updated and documented in `docs/IMPLEMENTATION_LOG.md`.
For every change, the log MUST record:
1. **What** was implemented (files created/modified, components built).
2. **How** it was implemented (architectural patterns, code structure, CMake/Cargo configuration).
3. **Why** specific decisions were made (rationale, trade-offs, security considerations).
4. **Standards & Best Practices** followed (C++20, LGPLv3 dynamic linking, Rust safety, OWASP ASVS, Conventional Commits).
5. **Verification & Test Results** (test execution outputs, static analysis results).

### 0.2 Implementation Plan Sync Rule (`docs/architecture_and_implementation_plan.md`)
Whenever a milestone, new feature, component, script, or architectural decision is added or completed, the master implementation plan (`docs/architecture_and_implementation_plan.md`) MUST be updated alongside `docs/IMPLEMENTATION_LOG.md`.

### 0.3 DRY Repository & Script Automation Standard
- **Zero Code/Script Duplication (DRY)**: Keep the codebase clean, modular, and DRY.
- **Automated Reusable Scripts (`tools/`)**: All environment bootstrap, dependency installation, building, testing, linting, formatting, and deployment MUST be driven by standardized scripts in `tools/`:
  - `tools/setup_deps.sh` — Prerequisites setup & dependency installer (includes `cppcheck`, `clang-tidy`, `clippy`)
  - `tools/build.sh` — Unified CMake + Cargo build wrapper with integrated quality gates
  - `tools/test.sh` — Unified CTest + Cargo test suite wrapper
  - `tools/lint.sh` — Unified Clang-format, Clang-tidy, Cppcheck, Rustfmt, Clippy, and Qmllint check wrapper
- **Reutilization over Ad-Hoc Execution**: Human developers and AI agents MUST utilize and re-use the centralized scripts in `tools/` rather than typing manual ad-hoc terminal commands.

### 0.4 Mandatory Quality Gate Rule (Lint -> Build -> Test -> Ready)
- **Strict Quality Pipeline Order**: No build artifact is considered ready or releaseable until:
  1. **Static Analysis & Linting Pass**: Code must pass `cppcheck`, `clang-tidy`, `clippy`, `rustfmt`, and `qmllint` with zero warnings (`./tools/lint.sh`).
  2. **Compilation**: Clean build under C++20 `-Werror` and Rust `#![forbid(unsafe_code)]`.
  3. **Test Suite Verification**: All C++ Qt Tests, QML Qt Quick Tests, and Rust Cargo unit/integration tests must pass cleanly (`./tools/test.sh`).
- **Enforcement**: `./tools/build.sh` automatically enforces this order. If static analysis or tests fail, the build fails immediately and no output binary is marked ready.

---

## 1. Non-Negotiable Core Rules

1. **Cleanroom Implementation**: Zero reverse-engineering or code copying from AnyDesk, RustDesk, Sunshine, or GPL/AGPL repositories. Study architecture concepts only, never copy code.
2. **Backend Language**: **Rust ONLY** across all backend services (`services/`). Do NOT use Go, Node, or Python for backend runtime services. `#![forbid(unsafe_code)]` is mandatory at crate root unless strictly isolated in audited shims.
3. **Client UI & Core**: **Qt 6 (LGPLv3, dynamic linking ONLY)** + QML for UI (`apps/client/`). **C++20** for performance-critical client/agent core (`apps/client/src/core/`, `apps/agent/`).
4. **Qt Licensing Compliance**:
   - **MUST NOT** statically link Qt libraries under any circumstances.
   - **MUST NOT** use GPLv3-only Qt modules (`Qt Charts`, `Qt Data Visualization`, `Qt Virtual Keyboard`).
   - Agent MUST remain Qt-free to prevent LGPL §4 "User Product" relinking obligations on locked embedded devices.
5. **Cross-Platform Isolation**:
   - Supported platforms: Windows, Linux, macOS.
   - **NO platform-specific `#ifdef` macros** (`_WIN32`, `__linux__`, `__APPLE__`) in `apps/` code outside dedicated `platform/<os>/` subdirectories.
   - All platform capabilities (Capture, Input, Encoding) must sit behind common abstract C++ interfaces defined in `libs/` (`ICaptureBackend`, `IInputBackend`, `IEncoderBackend`).

---

## 2. QML & Design Token Standards

Every QML file submitted or modified MUST adhere strictly to the following rules:

1. **Mandatory `id` Declaration**: Every visual element must declare an `id` as its very first property.
2. **Relative Sizing Only**:
   - **NEVER** use hardcoded pixel sizes (`width: 320`, `height: 240`) except inside `qml/theme/Tokens.qml` or `Metrics.qml`.
   - Use `anchors.fill: parent`, `Layout.preferredWidth: parent.width * 0.4`, or `implicitWidth`/`implicitHeight`.
   - All spacing and padding MUST use `Metrics.spacingXs`, `Metrics.spacingMd`, etc.
3. **Centralized Theming**:
   - Color references MUST use `Palette.<semanticColor>` (e.g., `Palette.background`, `Palette.accent`). **NO raw hex codes** (`"#1e1e1e"`) in component QML.
   - Font sizes MUST use `Typography.<style>` (e.g., `Typography.bodySize`).
4. **Zero Business Logic in QML**:
   - QML is strictly presentation. State and logic live in C++ view-models (`QObject` subclasses with `Q_PROPERTY` and `QML_ELEMENT`).
   - Max 10 lines of simple presentation JS allowed in QML handlers.
5. **Property Ordering**:
   Order properties as: `id` -> Custom properties -> Signal declarations -> JS helper functions -> Attached/Grouped properties -> Child objects/states.

---

## 3. C++ Coding Standards (C++20)

1. **Standard & Warnings**: C++20, clean build with `-Wall -Wextra -Wpedantic -Werror` / MSVC `/W4 /WX`.
2. **File & Function Ceilings**:
   - Headers ≤ 300 lines; Implementation `.cpp` ≤ 600 lines.
   - Function length ≤ 60 lines. Max 15 public methods per class.
3. **Memory & Safety**:
   - **NO raw `new` / `delete`**. Use `std::make_unique`, `std::make_shared`, or stack allocation.
   - Error handling via `std::expected<T, Error>` or `Result<T>` pattern. Do not cross module boundaries with raw exceptions.
4. **Encapsulation**:
   - Direct raw crypto or socket calls outside `libs/security` and `libs/transport` are **STRICTLY PROHIBITED**.

---

## 4. Rust Backend Standards

1. **Toolchain & Lints**: `rustfmt` + `clippy -D warnings` enforced on all PRs.
2. **Safety**: `#![forbid(unsafe_code)]` required in all service crates.
3. **Error Handling**: Explicit `Result<T, E>`. **NO `.unwrap()` or `.expect()`** in production service code.
4. **Architecture**: Clean separation into `handlers/`, `service/`, and `repo/` layers. Use `axum` for web/signaling and `quinn` for QUIC.

---

## 5. Centralized Logging & Diagnostic Rules

1. **C++ Logging**: Use Qt's `QLoggingCategory` via `libs/common/logging/`. Every subsystem MUST use its declared category (e.g., `qCDebug(rapTransport)`, `qCDebug(rapCapture)`).
2. **Rust Logging**: Use `tracing` crate with structured JSON subscriber matching the C++ log field schema.
3. **Security Boundary**: **NEVER log sensitive data** (session keys, passwords, credentials, clipboard text, or raw video frame data).
4. **Audit Separation**: Diagnostic logging is completely decoupled from the tamper-evident immutable audit log (`services/audit`).

---

## 6. Commit & Testing Expectations

1. **Commit Format**: Conventional Commits (`feat:`, `fix:`, `sec:`, `refactor:`, `test:`, `docs:`, `ci:`).
2. **Testing First**:
   - Unit tests required for all C++ logic (`Qt Test` / `GoogleTest`), QML (`Qt Quick Test`), and Rust crates (`cargo test`).
   - Line coverage targets: ≥ 80% on `libs/security`, `libs/protocol`, `libs/transport`, and Rust `services/*`.
