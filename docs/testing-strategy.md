# Testing Strategy & Assurance Architecture

> **Project:** Enterprise Cross-Platform Remote Access Platform  
> **Source of Truth:** [`docs/REMOTE-DESKTOP-ARCHITECTURE.md`](./REMOTE-DESKTOP-ARCHITECTURE.md) (§6)

---

## 1. Testing Pyramid & Target Ratio

Target Ratio: **70% Unit Tests / 20% Integration Tests / 10% UI Automation**

```
           /\
          /  \      10% UI Automation (FOSS Accessibility Tree + Robot Framework)
         /----\
        /      \    20% Integration (Virtual Displays, Testcontainers Postgres/Redis)
       /--------\
      /          \  70% Unit (Qt Test, GoogleTest, qmltestrunner, cargo test)
     --------------
```

---

## 2. Test Framework Matrix (100% Free / Open Source)

| Tier | Component | Toolchain | Framework |
|---|---|---|---|
| **Unit (C++)** | `libs/`, `apps/*/core` | CMake + Ninja | **Qt Test** / **GoogleTest** |
| **Unit (QML)** | `apps/client/qml/` | `qmltestrunner` | **Qt Quick Test** (`TestCase`, `SignalSpy`) |
| **Unit (Rust)** | `services/*` | Cargo | **`cargo test`** / **`cargo nextest`** |
| **Integration** | Agent Pipeline | `Xvfb` (Linux) / Virtual Display | Hardware/Software Encode & Frame Capture Harness |
| **Integration** | Services & DB | `testcontainers-rs` | Real Postgres & Redis containers in CI |
| **UI Automation** | Client Application | FOSS Drivers + Robot Framework | **dogtail** (Linux AT-SPI2), **pywinauto** (Win UIA), **atomac** (Mac NSAccessibility) |
| **Fuzzing** | Protocol / Transport | LLVM | **libFuzzer** / **cargo fuzz** |

---

## 3. Code Coverage Targets

| Module | Line Coverage Floor | Policy |
|---|---|---|
| `libs/security` | **≥ 80%** | Merge-blocking in CI |
| `libs/protocol` | **≥ 80%** | Merge-blocking in CI |
| `libs/transport` | **≥ 80%** | Merge-blocking in CI |
| `services/*` (Rust backend) | **≥ 80%** | Merge-blocking in CI |
| General Client/Agent UI & Core | **≥ 60%** | CI warning / target floor |

---

## 4. Multi-OS CI Execution Matrix

- **Every PR**: Runs Unit Tests (C++, QML, Rust), static analysis, and code coverage checks on `windows-latest`, `ubuntu-latest`, and `macos-latest`.
- **Nightly**: Integration tests, FOSS accessibility-tree UI automation suite, and fuzzing corpus execution.
