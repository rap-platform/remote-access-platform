# Contributing to Remote Access Platform

Thank you for contributing! This document provides guidelines and instructions for building, testing, and submitting code to the **Remote Access Platform** repository.

---

## 1. Development Environment Prerequisites

Ensure you have the following installed on your development workstation:

* **C++ Compiler**: GCC 13+, Clang 16+, or MSVC 2022+ (supporting C++20 standard).
* **CMake**: Version 3.22 or higher.
* **Ninja**: Version 1.10 or higher.
* **Qt 6**: Version 6.5+ (`Qt6Core`, `Qt6Gui`, `Qt6Quick`, `Qt6Test`).
* **Rust Toolchain**: 1.80+ (`rustc`, `cargo`, `rustfmt`, `clippy`).
* **Flutter SDK**: 3.22+ (for mobile app work in `apps/mobile`).

---

## 2. Building the Project

### Building C++ & Qt6 Targets (Desktop Client & Libraries)

```bash
# 1. Configure the build tree with CMake & Ninja
cmake -B build -S . -G Ninja -DCMAKE_BUILD_TYPE=Debug -DENABLE_TESTING=ON

# 2. Compile all targets
cmake --build build
```

### Building Rust Microservices (Backend Services)

```bash
# Build all Rust crates in the workspace
cargo build --workspace
```

### Building Mobile Client (Flutter)

```bash
cd apps/mobile
flutter pub get
flutter build apk --debug
```

---

## 3. Running Tests & Static Analysis

Before opening a Pull Request, verify that all test suites pass and static linters run clean:

```bash
# 1. Run C++ & Qt Quick Unit Tests
ctest --test-dir build --output-on-failure

# 2. Run Rust Unit & Integration Tests
cargo test --workspace

# 3. Check Rust formatting and lints
cargo fmt --check
cargo clippy --workspace --all-targets -- -D warnings
```

---

## 4. Git Branch & Pull Request Workflow

1. **Create a Feature Branch**:
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/bug-description
   ```

2. **Commit Your Changes**:
   Follow conventional commit messages (e.g., `feat(client): add multi-monitor selector UI`, `fix(security): resolve handshake timeout`).

3. **Push to Your Branch & Open a PR**:
   ```bash
   git push -u origin feature/your-feature-name
   ```
   Open a Pull Request on GitHub and request a review from project maintainers.

---

## 5. Coding Standards & Governance

* Refer to [`CODING_STANDARDS.md`](./CODING_STANDARDS.md) for C++, Rust, and QML style guidelines.
* Refer to [`SECURITY.md`](./SECURITY.md) for security reporting and cryptographic rules.
