# Remote Access Platform Windows Installer Instructions

This directory contains the packaging configuration files and build automation scripts to create standalone Windows installers for the **Remote Access Platform** (`rap-client` Desktop Viewer and `rap-agent` Host Service).

---

## 📁 Folder Structure

- `rap-client/`
  - `RemoteAccessPlatform.iss`: Inno Setup script configuring application metadata, file installation, Start Menu shortcuts, optional desktop icon, autostart service registry entries, and compression parameters.
  - `Output/`: *(Gitignored)* Directory containing compiled setup installer executables (`RemoteAccessPlatform-Setup-V0.3.0.exe`), SHA-256/MD5 checksums, and `.zip` release archives.
- `rap-client-build/`: *(Gitignored)* Local staging folder holding compiled executables (`rap-client.exe`, `rap-agent.exe`), Qt runtime DLLs, and QML resources processed by `windeployqt`.
- `build_and_package.bat`: Master automated script that compiles C++ binaries, stages files into `rap-client-build/`, runs `windeployqt`, builds the Inno Setup installer, and generates release checksums.
- `build_installers.bat`: Batch script to run *only* the Inno Setup compiler on `RemoteAccessPlatform.iss`.

---

## 🛠️ Prerequisites

To package the application for standalone Windows distribution, ensure the following tools are present:
1. **CMake** (v3.22+).
2. **Inno Setup 6** (installed to `C:\Program Files (x86)\Inno Setup 6\ISCC.exe`).
3. **Qt 6.11.1 MSVC2022 64-bit** development environment.
4. Local `.env` file containing optional tool path overrides (`ISCC_PATH`, `QT_MSVC_PATH`, `QT_CMAKE_PATH`).

---

## 🚀 Packaging Steps (Automated)

Run the master packaging script from command prompt:

```cmd
build_and_package.bat 0.3.0
```

### What the script executes automatically:
1. **Reads Centralized Versioning**: Reads `VERSION` file (`AppVersion=0.3.0`) or uses the version string passed as argument.
2. **Compiles C++ Binaries**: Invokes `build-scripts/build_msvc.ps1` with Ninja & MSVC 2022.
3. **Stages & Deploys Qt Runtime**: Populates `rap-client-build/` with binaries, QML files, and Qt DLL dependencies using `windeployqt`.
4. **Compiles Installer**: Invokes `ISCC.exe` on `RemoteAccessPlatform.iss` (sourcing from `rap-client-build/`), generating:
   `rap-client\Output\version-0.3.0\RemoteAccessPlatform-Setup-V0.3.0.exe`
5. **Generates Checksums & Zip Release**: Computes SHA-256 and MD5 hashes using `certutil` and creates a compressed release `.zip` bundle.

---

## 🛠️ Packaging Steps (Manual)

If performing steps manually:
1. Compile binaries using MSVC Release mode (`cmake --build build --config Release`).
2. Run deployment bundler:
   ```powershell
   powershell -ExecutionPolicy Bypass -File build-scripts\deploy_msvc.ps1
   ```
3. Compile the Inno Setup installer script:
   ```cmd
   Installer\Windows\build_installers.bat 0.3.0
   ```
