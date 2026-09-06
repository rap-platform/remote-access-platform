# 📦 Implementation Plan: Windows & Linux Packaging & Installer System

This plan outlines the architecture, directory structure, environment configurations, and build/packaging scripts required to create standalone Windows installers (Inno Setup / `windeployqt`) and Linux packages (`AppImage` / `linuxdeploy`) for **Remote Access Platform** (`rap-client` and `rap-agent`).

---

## 📐 Architecture & Reference Mapping

Modeled directly after the **SharkView SCADA Platform** build and packaging workflow (`SharkView/Installer` & `SharkView/build-scripts`), adapted for `remote-access-platform`:

```
remote-access-platform/
├── .env                             # Local developer environment path overrides
├── .env.example                     # Reference template for Qt 6, MSVC, ISCC & Linux tool paths
├── VERSION                          # Centralized version file (AppVersion=0.3.0)
├── build-scripts/
│   ├── build_msvc.ps1               # PowerShell script to configure & build C++ targets (Ninja + MSVC 2022)
│   ├── deploy_msvc.ps1              # PowerShell script to aggregate binaries, QML assets & run windeployqt
│   └── package-appimage.sh          # Linux Bash script with auto-download of linuxdeploy & AppImage bundling
└── Installer/
    └── Windows/
        ├── rap-client/
        │   └── RemoteAccessPlatform.iss  # Inno Setup script for Desktop Client & Host Agent Service
        └── build_installers.bat     # Windows batch runner to invoke ISCC compiler with .env configuration
```

---

## 🛠️ Proposed Changes

### 1. Root Configuration & Version Control

#### [NEW] [.env.example](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/.env.example)
- Environment variable template defining local paths for Qt 6, CMake, Ninja, CTest, OpenSSL, Inno Setup Compiler (`ISCC_PATH`), and Linux `qmake`/`cmake`.

#### [NEW] [.env](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/.env)
- Developer-specific active environment file pre-configured for local machine paths (`QT_MSVC_PATH=C:\Qt_my\6.11.1\msvc2022_64`, `ISCC_PATH=C:\Program Files (x86)\Inno Setup 6\ISCC.exe`).

#### [NEW] [VERSION](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/VERSION)
- Single source of truth for versioning: `AppVersion=0.3.0`.

---

### 2. Automated Build & Deployment Scripts (`build-scripts/`)

#### [NEW] [build_msvc.ps1](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/build-scripts/build_msvc.ps1)
- **Purpose**: Powershell build runner for Windows (MSVC 2022 64-bit + Ninja).
- **Features**:
  - Reads `.env` for `QT_CMAKE_PATH`, `QT_NINJA_PATH`, `QT_MSVC_PATH`, `OPENSSL_ROOT_DIR`.
  - Configures CMake targeting build directory `build/Desktop_Qt_6_11_1_MSVC2022_64bit_Release`.
  - Locates `vcvars64.bat` to initialize MSVC compiler environment.
  - Builds `rap-client`, `rap-agent`, and all library dependencies (`libs/protocol`, `libs/capture`, `libs/security`, `libs/file_transfer`, `libs/input`).

#### [NEW] [deploy_msvc.ps1](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/build-scripts/deploy_msvc.ps1)
- **Purpose**: Windows deployment bundler.
- **Features**:
  - Aggregates compiled executables (`rap-client.exe`, `rap-agent.exe`) and DLLs into `deploy_windows/bin`.
  - Copies QML UI files (`apps/client/qml/*`) to `deploy_windows/qml`.
  - Runs `windeployqt.exe` with `--qmldir apps/client/qml` to automatically pull all Qt Quick, Qt GraphicalEffects, and runtime dependencies.

#### [NEW] [package-appimage.sh](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/build-scripts/package-appimage.sh)
- **Purpose**: Linux standalone AppImage packager with auto-dependency fetching.
- **Features**:
  - Reads `.env` for `LINUX_CMAKE_PATH` and `LINUX_QMAKE_PATH`.
  - Automatically checks for `linuxdeploy-x86_64.AppImage` and `linuxdeploy-plugin-qt-x86_64.AppImage`; downloads latest GitHub release binaries via `wget`/`curl` if not found.
  - Sets `QML_SOURCES_PATHS` pointing to `apps/client/qml`.
  - Builds project with CMake into `build/AppDir`.
  - Uses `linuxdeploy` and `linuxdeploy-plugin-qt` to bundle shared libraries (`.so`), Qt QML runtime, and generate `RemoteAccessPlatform-0.3.0-x86_64.AppImage`.

---

### 3. Windows Inno Setup Compiler Automation (`Installer/`)

#### [NEW] [RemoteAccessPlatform.iss](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/Installer/Windows/rap-client/RemoteAccessPlatform.iss)
- **Purpose**: Inno Setup installer script for Windows distribution.
- **Features**:
  - Installs `rap-client.exe` (Viewer UI) and `rap-agent.exe` (Host Agent Service).
  - Registers Start Menu shortcuts and optional Desktop shortcut.
  - Installs desktop agent as a Windows background service if requested.
  - Bundles Qt runtime libraries, QML modules, libsodium, and dependencies from `deploy_windows`.
  - Output filename: `RemoteAccessPlatform-Setup-V0.3.0.exe`.

#### [NEW] [build_installers.bat](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/Installer/Windows/build_installers.bat)
- **Purpose**: Batch script to automate running Inno Setup.
- **Features**:
  - Reads `ISCC_PATH` from `.env` (configured for `C:\Program Files (x86)\Inno Setup 6\ISCC.exe` with `C:\Progra~2\Inno Setup 6\ISCC.exe` short-path fallback).
  - Reads version from `VERSION` file.
  - Compiles `RemoteAccessPlatform.iss` via `ISCC.exe /DMyAppVersion="%APP_VERSION%"`.
  - Displays output directory result (`Installer/Windows/rap-client/Output`).

---

## 🎯 Confirmed Technical Decisions

> [!IMPORTANT]
> 1. **Inno Setup**: Confirmed available at `C:\Program Files (x86)\Inno Setup 6\ISCC.exe`.
> 2. **AppImage Auto-Download**: Enabled. `package-appimage.sh` will auto-download `linuxdeploy` & `linuxdeploy-plugin-qt` if missing.
> 3. **Execution Directive**: Implementation is paused as requested. The plan is stored for review and ready for approval.

---

## 🧪 Verification Plan

### Manual Verification (User-Driven)
1. **Local Build & Windows Deployment**:
   - Run `powershell -ExecutionPolicy Bypass -File build-scripts/deploy_msvc.ps1`.
   - Verify `deploy_windows/bin/rap-client.exe` launches standalone without needing system PATH Qt DLLs.
2. **Windows Installer Generation**:
   - Run `Installer\Windows\build_installers.bat`.
   - Check that `Installer\Windows\rap-client\Output\RemoteAccessPlatform-Setup-V0.3.0.exe` is generated.
3. **Linux AppImage Packaging**:
   - Run `bash build-scripts/package-appimage.sh`.
   - Verify `dist/RemoteAccessPlatform-0.3.0-x86_64.AppImage` is created and executable.
