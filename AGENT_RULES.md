# Agent Rules & Architectural Governance Standard

> **Project:** Enterprise Cross-Platform Remote Access Platform  
> **Source of Truth:** [`docs/REMOTE-DESKTOP-ARCHITECTURE.md`](./docs/REMOTE-DESKTOP-ARCHITECTURE.md)  
> **Implementation Plan:** [`docs/architecture_and_implementation_plan.md`](./docs/architecture_and_implementation_plan.md)

---

## 0. Mandatory Rules for Agent Execution

### 0.1 Live Technical Implementation Log Standard (`docs/IMPLEMENTATION_LOG.md`)
For **EVERY** core feature, architectural decision, script creation, static analysis addition, build system update, or milestone completed:
- The agent **MUST** update `docs/IMPLEMENTATION_LOG.md` immediately with:
  1. **What Was Implemented** (files modified/created, technical rationale).
  2. **Architectural & Design Patterns Followed** (C++20, Rust 2021, Qt6/QML tokens, LGPLv3 compliance).
  3. **Quality Standards Followed** (Static analysis zero warnings, formatting rules).
  4. **Verification & Test Results** (test execution outputs, static analysis results).

### 0.2 Implementation Plan Sync Rule (`docs/architecture_and_implementation_plan.md`)
Whenever a milestone, new feature, component, script, or architectural decision is added or completed, the master implementation plan (`docs/architecture_and_implementation_plan.md`) MUST be updated alongside `docs/IMPLEMENTATION_LOG.md`.

### 0.3 DRY Repository & Script Automation Standard
- **Zero Code/Script Duplication (DRY)**: Keep the codebase clean, modular, and DRY.
- **Automated Tooling Scripts (`tools/`)**:
  - `tools/setup_deps.sh`: Installs system dependencies.
  - `tools/lint.sh`: Static analysis runner (`cppcheck`, `clang-format`, `rustfmt`, `clippy`).
  - `tools/test.sh`: Automated test runner (CTest + Cargo test).
  - `tools/build.sh`: Quality Gate pipeline (Lint -> Build -> Test -> Ready).

### 0.4 Interactive User Terminal Standard
- **No Internal Long-Running Commands**: Do not run long-running build scripts, server daemons, or GUI applications internally inside background execution tools.
- **User Terminal Instructions**: Provide clear, step-by-step, copy-pasteable terminal commands so the user can run them directly in their own desktop terminal windows to view live output, scroll up/down, and inspect execution logs.

---

## 1. Architectural & Engineering Standards
1. **Industry-Standard Practices**: High-performance, memory-safe, modular design.
2. **C++ Standard**: **C++20** (`-std=c++20`).
3. **Rust Edition**: **Rust 2021** edition (`#![forbid(unsafe_code)]` in services).
4. **Qt6/QML Design System**: Centralized design tokens in `apps/client/qml/theme/`. Zero hardcoded hex color literals outside theme tokens.
5. **Static Analysis Enforcement**: Code must pass `cppcheck`, `clang-format`, `rustfmt`, `clippy`, and QML hex color enforcer before build artifact readiness.
6. **Git History Standard**: Granular git commits using Conventional Commits (`feat:`, `fix:`, `docs:`, `test:`, `refactor:`).
7. **Comprehensive README**: Maintain [`README.md`](./README.md) with complete instructions.
