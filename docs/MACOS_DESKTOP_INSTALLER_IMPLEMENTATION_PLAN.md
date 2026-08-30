# 🍎 Implementation Plan: macOS Desktop Packaging & DMG Pipeline

This plan outlines the architecture, directory structure, toolchain configurations, and build/packaging scripts required to create release packages for the **macOS Desktop Client** (`rap-client`) and **Host Agent Service** (`rap-agent`), including standalone `.app` bundles and `.dmg` disk image installers.

---

## 📐 Architecture & Reference Mapping

Modeled directly after the **Remote Access Platform** cross-platform packaging architecture (`docs/INSTALLER_IMPLEMENTATION_PLAN.md` & `build-scripts/`):

```
remote-access-platform/
├── VERSION                                       # Centralized version source of truth (0.3.0)
├── .env.example                                  # Added MACOS_CMAKE_PATH & QT_MACOS_PATH overrides
├── docs/
│   └── MACOS_DESKTOP_INSTALLER_IMPLEMENTATION_PLAN.md # Persistent macOS desktop plan
├── build-scripts/
│   ├── package-macos.sh                          # Bash script for macOS to build rap-client.app & .dmg image
│   └── package-macos.ps1                         # PowerShell script for macOS/Windows hosts
└── apps/client/
    └── macos/                                    # macOS application bundle icons & Info.plist metadata
```

---

## 🛠️ Packaging Pipeline (`build-scripts/`)

#### 1. [package-macos.sh](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/build-scripts/package-macos.sh)
- **Purpose**: macOS Bash automated desktop packaging script.
- **Features**:
  - Reads `VERSION` file for `APP_VERSION` (0.3.0).
  - Configures and builds Release binaries (`rap-client`, `rap-agent`) using CMake.
  - Stages `rap-agent` binary inside `rap-client.app/Contents/MacOS/`.
  - Runs Qt `macdeployqt` to embed Qt 6 framework dependencies and QML modules (`apps/client/qml`).
  - Generates signed `RemoteAccessPlatform-0.3.0.dmg` disk image and `.zip` archive.
  - Calculates SHA-256 and MD5 checksums into `dist/desktop/macos/checksums.txt`.

#### 2. [package-macos.ps1](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/build-scripts/package-macos.ps1)
- **Purpose**: PowerShell automated runner for macOS (PowerShell Core) and Windows hosts.
- **Features**:
  - Automatically detects host OS. Displays graceful platform guidance when executed on Windows.
  - Compiles C++ release binaries, stages `.app` bundle, runs `macdeployqt`, and generates `.dmg` on macOS hosts.

---

## 🎯 Target Output Artifacts

| Platform | Output File | Destination | Description |
|---|---|---|---|
| **macOS** | `RemoteAccessPlatform-0.3.0.dmg` | `dist/desktop/macos/` | Standalone macOS Disk Image installer with Qt runtime |
| **macOS** | `RemoteAccessPlatform-0.3.0-macOS.zip` | `dist/desktop/macos/` | Compressed `.app` application bundle archive |
| **Checksums** | `checksums.txt` | `dist/desktop/macos/` | SHA-256 & MD5 hashes for all macOS desktop packages |

---

## 🧪 Verification Commands

### macOS Desktop Packaging (.dmg & .app bundle):
```bash
# Bash script:
bash build-scripts/package-macos.sh

# PowerShell Core script:
pwsh -File build-scripts/package-macos.ps1
```
