# Software Coding Standards & Guidelines

> **Project:** Enterprise Cross-Platform Remote Access Platform  
> **Source of Truth:** [`docs/REMOTE-DESKTOP-ARCHITECTURE.md`](./docs/REMOTE-DESKTOP-ARCHITECTURE.md) (Version 4.0)

---

## 1. C++20 Standards

1. **Compiler Flags & Warnings**: All C++ targets must compile cleanly under `-Wall -Wextra -Wpedantic -Werror` (GCC/Clang) and `/W4 /WX` (MSVC).
2. **Formatting**: Enforced via `.clang-format` (LLVM base, 100 column limit, 4 spaces indent).
3. **Static Analysis**: `.clang-tidy` runs in CI. Zero tolerance for warnings.
4. **Platform Isolation Rule**: **NO `#ifdef _WIN32` / `#ifdef __linux__` / `#ifdef __APPLE__` in application code** outside `platform/<os>/` directories. Enforced by custom static analysis check.
5. **Memory Management**: No raw `new`/`delete`. Use smart pointers (`std::unique_ptr`, `std::shared_ptr`).
6. **Error Handling**: Use `std::expected<T, Error>` pattern. No raw C++ exceptions across module boundaries.

---

## 2. QML Standards

1. **Mandatory `id`**: Every element must declare an `id` as its first property.
2. **Relative Sizing**: No pixel literals (`width: 300`). Use `anchors.fill`, `Layout.preferredWidth`, or `Metrics.spacing*` tokens.
3. **Design Tokens**: Colors MUST use `Palette.*` singletons; fonts use `Typography.*`. Zero raw hex colors outside `qml/theme/`.
4. **Zero Business Logic**: QML is presentation only. All state resides in C++ view-models (`QObject` subclasses).

---

## 3. Rust Backend Standards

1. **Formatting & Lints**: `rustfmt` + `clippy -D warnings`.
2. **Safety**: `#![forbid(unsafe_code)]` mandatory at crate root.
3. **Dependency Auditing**: `cargo audit` and `cargo deny` enforced on every commit.
4. **Error Handling**: Explicit `Result<T, E>`. Zero `.unwrap()` or `.expect()` in production service code.

---

## 4. Git & Commit Conventions

Commits MUST follow the **Conventional Commits** specification:
- `feat:` New feature
- `fix:` Bug fix
- `sec:` Security remediation
- `refactor:` Code refactoring
- `test:` Test suites / harnesses
- `docs:` Documentation updates
- `ci:` Pipeline updates
