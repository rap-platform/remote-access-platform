# Third-Party Open Source Software Notice & License Audit Report

This application incorporates components from the following open-source projects:

| Component | License | Linking Method | Notes & Compliance |
|---|---|---|---|
| **Qt 6 Framework (Qt Quick, QML, QtCore, QtGui, QtNetwork)** | `LGPLv3 / GPLv3` | Dynamic Linking (.so / .dll / .dylib) | Dynamically linked per LGPLv3 Section 4 rules. User re-linking permitted. |
| **Axum Web Framework & Tokio Async Runtime** | `MIT` | Rust Static Crate Dependency | Permissive MIT License. |
| **Sodium / libsodium Crypto Engine** | `ISC License` | Native Library Dependency | XChaCha20-Poly1305 and X25519 authenticated encryption. |
| **Serde & Serde JSON** | `MIT / Apache-2.0` | Rust Static Crate Dependency | Permissive dual license. |
| **SHA2 & RustCrypto** | `MIT / Apache-2.0` | Rust Static Crate Dependency | Permissive dual license. |
| **X11 & XTest Client Libraries (libX11, libXtst)** | `MIT / X11 License` | Dynamic Native Link | Linux synthetic input injection and display capture. |

---
## LGPLv3 Compliance Notice

The Remote Access Platform desktop viewer (`rap-client`) dynamically links against the **Qt 6 Framework** under the terms of the GNU Lesser General Public License version 3 (LGPLv3).

### User Re-Linking Rights & Instructions:
1. End users have the right to modify or swap out the shared Qt 6 runtime libraries (`libQt6Core.so`, `libQt6Gui.so`, `libQt6Quick.so`, `libQt6Qml.so`).
2. To replace the installed Qt 6 libraries with a custom build, update your system `LD_LIBRARY_PATH` (Linux), `DYLD_LIBRARY_PATH` (macOS), or placing modified DLLs in the executable directory (Windows).
3. No static Qt object files are embedded inside the proprietary application binary.

### Source Code & License Requests:
Qt source code can be obtained directly from [https://download.qt.io/official_releases/qt/](https://download.qt.io/official_releases/qt/).
