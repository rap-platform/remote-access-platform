# 🚀 Remote Access Platform — Feature Addition Analysis

> **Comprehensive deep-dive into every subsystem** with 40+ actionable feature additions, organized by priority, complexity, and the exact files/modules they touch.

---

## 📊 Current Architecture Snapshot

| Layer | Status | Key Files / References |
|---|---|---|
| **Desktop Client (Qt6/QML)** | ✅ Functional | [Main.qml](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/apps/client/qml/Main.qml), [SessionClient.h](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/apps/client/src/SessionClient.h), [apps/client/CMakeLists.txt](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/apps/client/CMakeLists.txt) |
| **Host Agent (C++20 Qt-Free)** | ✅ Functional | [AgentPacketHandler.h](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/apps/agent/src/AgentPacketHandler.h), [main.cpp](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/apps/agent/src/main.cpp) |
| **Capture Library** | ✅ Linux (X11/DRM) | [ICaptureBackend.h](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/libs/capture/include/ICaptureBackend.h) |
| **Input Injection** | ✅ Linux, Stub others | [IInputBackend.h](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/libs/input/include/IInputBackend.h) |
| **E2E Crypto (libsodium)** | ✅ Complete | [CryptoEngine.h](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/libs/security/include/CryptoEngine.h) |
| **File Transfer Engine** | ✅ Chunked + SHA-256 | [FileTransferEngine.h](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/libs/file_transfer/include/FileTransferEngine.h) |
| **Protocol (Protobuf)** | ✅ 15 payload types | [session.proto](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/proto/session.proto) |
| **Rust Backend Services** | ✅ 5 microservices | Identity, Signaling, Relay, API-Gateway, Audit (`#![forbid(unsafe_code)]`) |
| **Flutter Mobile** | ✅ Shell + FFI bridge | [apps/mobile](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/apps/mobile) |
| **Theme System** | ✅ 5 themes, hot-reload | [ThemeManager.h](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/apps/client/include/ThemeManager.h) |
| **Dynamic Versioning** | ✅ Centralized | [VERSION](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/VERSION), [CMakeLists.txt](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/CMakeLists.txt) (`CMAKE_CONFIGURE_DEPENDS`) |
| **Packaging & Installers** | ✅ 5 Platforms | `build_and_package.bat` (Win), `package-appimage.sh` (Lin), `package-macos.sh` (Mac), `package-android.sh` (Android), `package-ios.sh` (iOS) |

---

## 📐 Architectural Governance & Quality Rules (.cursorrules Compliance)

All planned features and code modifications must strictly adhere to the mandatory architecture blueprint in [.cursorrules](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/.cursorrules) and [REMOTE-DESKTOP-ARCHITECTURE.md](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/docs/REMOTE-DESKTOP-ARCHITECTURE.md):

1. **Rule 0 — Live Documentation Sync**: Continuously maintain `docs/IMPLEMENTATION_LOG.md` detailing implementation decisions, standards, and verification results. Update `docs/architecture_and_implementation_plan.md` as features progress.
2. **Rule 1 — Quality Gate & Script Automation (`tools/`)**: Execute static analysis (`cppcheck`, `clang-tidy`, `clippy`, `rustfmt`), compile cleanly, and run test suites (`ctest`, `cargo test`) before any release artifact is declared ready.
3. **Rule 2 — Backend Memory Safety (Rust Only)**: All backend services (`services/`) are written exclusively in Rust with `#![forbid(unsafe_code)]` at crate root.
4. **Rule 3 — LGPLv3 Compliance**: Desktop UI uses Qt 6 with **LGPLv3 dynamic linking only**. Static linking of Qt is prohibited. Never use GPL-only modules (`Qt Charts`, `Qt Data Visualization`).
5. **Rule 4 — Qt-Free Headless Agent**: Core Host Agent (`apps/agent`) must remain **100% Qt-free** C++20 for lightweight, headless background service execution.
6. **Rule 5 — Strict Platform Abstraction Isolation**: OS-specific code must sit behind abstract interfaces (`ICaptureBackend`, `IInputBackend`, `IEncoderBackend`). No `#ifdef _WIN32` / `#ifdef __linux__` / `#ifdef __APPLE__` outside `platform/<os>/` subdirectories.
7. **Rule 6 — QML Structural Rules**: Declare `id` as the very first property in QML components. Enforce relative sizing via `Metrics.*` and colors via `themePalette`. Maintain **zero business logic in QML**.
8. **Rule 7 — Logging & Security**: Use `QLoggingCategory` (C++) and `tracing` (Rust). Never log credentials, session keys, OTP passcodes, clipboard payloads, or frame buffers.
9. **Rule 8 — Git Commit Hygiene**: Enforce Conventional Commits (`feat:`, `fix:`, `sec:`, `refactor:`, `test:`, `docs:`, `ci:`).

---

## 🔥 TIER 1 — High-Impact, Low-to-Medium Effort (Quick Wins)

### 1. 🖥️ Multi-Monitor Display Selector

> **Already on Sprint 1 backlog** — highest priority UI gap.

| Detail | Value |
|---|---|
| **Impact** | Critical — users with 2+ monitors can't choose which screen to stream |
| **Effort** | Medium (3–5 days) |
| **Touches** | `ICaptureBackend.h`, `AgentPacketHandler.h`, `DesktopSessionView.qml`, `session.proto` |

**Implementation:**
- Add `virtual std::vector<MonitorInfo> enumerateMonitors()` to `ICaptureBackend`
- Extend `HandshakeResponse` protobuf with `repeated MonitorInfo monitors`
- Create a QML `ComboBox` dropdown in `DesktopSessionView.qml` action bar listing monitor names/resolutions
- Agent sends monitor list on handshake; client sends `SelectMonitor` message to switch

---

### 2. 📋 Drag-and-Drop File Transfer

> **Already on Sprint 1 backlog** — huge UX upgrade.

| Detail | Value |
|---|---|
| **Impact** | High — eliminates manual path entry for file uploads |
| **Effort** | Medium (2–3 days) |
| **Touches** | `FileTransferView.qml`, `SessionClient.h` |

**Implementation:**
- Add `DropArea` component overlaying both local and remote panes in [FileTransferView.qml](file:///c:/Users/TECQNIO/Documents/GitClone/remote-access-platform/apps/client/qml/views/FileTransferView.qml)
- On drop, extract `urls` from `DragEvent`, resolve to local paths
- Auto-call `sessionClient.startFileUpload()` for each dropped file
- Show animated drop-zone highlight with dashed border + "Drop files here" overlay

---

### 3. 📊 Live Session Performance HUD Overlay

> Real-time telemetry during active remote sessions.

| Detail | Value |
|---|---|
| **Impact** | High — essential for diagnosing lag and quality issues |
| **Effort** | Low (1–2 days) |
| **Touches** | `DesktopSessionView.qml`, `SessionClient.h` |

**Implementation:**
- Add properties to `SessionClient`: `fps`, `latencyMs`, `packetLoss`, `bitrate`, `codec`
- Create a translucent HUD overlay card (toggled via `Ctrl+Shift+P`) in `DesktopSessionView.qml`
- Display: Current FPS, Round-Trip Latency (ms), Bitrate (Mbps), Codec, Packet Loss %, Resolution
- Use `Timer` with 1000ms interval updating from `Heartbeat` round-trip measurements

---

### 4. 🔔 Toast Notification System

> System-wide notification component for connection events, errors, file completions.

| Detail | Value |
|---|---|
| **Impact** | High — currently no user feedback for async events |
| **Effort** | Low (1 day) |
| **Touches** | New `components/ToastNotification.qml`, `Main.qml` |

**Implementation:**
- Create reusable `ToastNotification.qml` component with slide-in animation from top-right
- Support types: `success`, `error`, `warning`, `info` with matching icon and color from `themePalette`
- Auto-dismiss after 4 seconds with fade-out transition
- Stack multiple toasts vertically; expose `showToast(message, type)` function globally

---

### 5. 🔍 File Search & Filter Bar

> Search across directory listings in the file transfer view.

| Detail | Value |
|---|---|
| **Impact** | Medium — essential when navigating large directories |
| **Effort** | Low (1 day) |
| **Touches** | `FileTransferView.qml` |

**Implementation:**
- Add `TextField` with search icon above each `ListView` (local and remote panes)
- Filter `sessionClient.localDirectoryList` / `sessionClient.directoryList` by `modelData.name.includes(searchText)`
- Use `SortFilterProxyModel` or JS filter for real-time results
- Add file type filter dropdown: All, Directories Only, Files Only

---

### 6. 🎨 Custom Accent Color Picker

> Let users customize the primary accent color beyond the 5 preset themes.

| Detail | Value |
|---|---|
| **Impact** | Medium — personalization & branding for enterprise users |
| **Effort** | Low (1 day) |
| **Touches** | `ThemeManager.h`, `HeaderBar.qml` |

**Implementation:**
- Add `Q_INVOKABLE void setAccentColor(const QColor& color)` to `ThemeManager`
- Add a color picker popup triggered from `HeaderBar.qml` next to the theme dropdown
- Persist choice to `QSettings` so it survives restarts
- Override `primary` and `accent` palette values with the user-selected color

---

## ⚡ TIER 2 — Medium Impact, Medium Effort (Sprint 2 Features)

### 7. 🔊 Low-Latency Audio Streaming

> **Already on long-term roadmap** — bidirectional OPUS audio.

| Detail | Value |
|---|---|
| **Impact** | Very High — core feature gap vs AnyDesk/TeamViewer |
| **Effort** | High (1–2 weeks) |
| **Touches** | New `libs/audio/`, `session.proto`, `AgentPacketHandler.h`, `SessionClient.cpp` |

**Implementation:**
- New C++ library `libs/audio/` with `IAudioCaptureBackend` (PulseAudio/WASAPI/CoreAudio)
- OPUS encoding/decoding via `libopus`
- New protobuf types: `PAYLOAD_TYPE_AUDIO_CHUNK = 13`
- Agent captures system audio, encodes to OPUS, encrypts, sends via existing QUIC multiplexed stream
- Client decodes and plays back via `QAudioOutput` or platform audio sink
- Add mute/volume controls to `DesktopSessionView.qml` action bar

---

### 8. 🖥️ Windows DXGI Screen Capture Backend

> Currently only Linux X11/DRM capture exists — Windows is the primary use case.

| Detail | Value |
|---|---|
| **Impact** | Critical — Windows is likely 70%+ of users |
| **Effort** | High (1 week) |
| **Touches** | New `libs/capture/src/WindowsDxgiCapture.cpp`, `ICaptureBackend.h` |

**Implementation:**
- Implement `ICaptureBackend` using DXGI Desktop Duplication API
- Support `IDXGIOutputDuplication::AcquireNextFrame()`
- GPU texture → staging texture → CPU pixel buffer pipeline
- Automatic fallback to GDI BitBlt for older GPUs
- Register in `CaptureBackendFactory::createDefaultBackend()` for `#ifdef _WIN32`

---

### 9. ⌨️ Windows SendInput Injection Backend

> Currently `IInputBackend` returns a dummy stub on non-Linux.

| Detail | Value |
|---|---|
| **Impact** | Critical — remote control doesn't work on Windows hosts without this |
| **Effort** | Medium (3–4 days) |
| **Touches** | `libs/input/`, new `WindowsSendInput.cpp` |

**Implementation:**
- Implement `IInputBackend` using Win32 `SendInput()` API
- Map `InputEvent` types to `INPUT` structs (`INPUT_MOUSE`, `INPUT_KEYBOARD`)
- Handle scan codes, virtual key mapping, and extended keys
- Support `Ctrl+Alt+Del` via `SAS.dll` or service-mode injection

---

### 10. 📱 Mobile Touch-to-Mouse Gesture Engine

> The Flutter mobile client needs touch gesture → remote mouse event translation.

| Detail | Value |
|---|---|
| **Impact** | High — makes mobile client actually usable |
| **Effort** | Medium (3–5 days) |
| **Touches** | `apps/mobile/lib/views/`, native FFI bridge |

**Implementation:**
- Single tap → Left click
- Long press → Right click
- Two-finger scroll → Mouse wheel
- Pinch → Zoom (scale remote viewport)
- Three-finger swipe → Keyboard shortcut panel
- Implement `GestureDetector` in Flutter with configurable sensitivity

---

### 11. 📹 Session Recording & Playback

> **Already on long-term roadmap** — encrypted session recording.

| Detail | Value |
|---|---|
| **Impact** | High — enterprise compliance and training |
| **Effort** | High (1–2 weeks) |
| **Touches** | New `libs/recording/`, `SessionClient.cpp`, new `SessionPlaybackView.qml` |

**Implementation:**
- Capture encrypted frame headers + payloads to a `.raprec` binary file
- Include metadata: session ID, timestamps, participant IDs, key fingerprints
- New QML view `SessionPlaybackView.qml` with timeline scrubber, play/pause, speed controls
- Decrypt on playback using session key (stored encrypted with user's master key)
- Optional: export to MP4 via FFmpeg CLI

---

### 12. 🌐 Connection History & Recent Sessions Log

> Track and display past connection history.

| Detail | Value |
|---|---|
| **Impact** | Medium — convenient reconnection to known hosts |
| **Effort** | Low–Medium (2 days) |
| **Touches** | `SessionClient.cpp`, `SavedDevicesView.qml`, new `ConnectionHistory` model |

**Implementation:**
- Log every connection attempt to `QSettings` or SQLite: timestamp, P2P ID, IP, duration, status
- Display in `SavedDevicesView.qml` as a second tab: "Recent Connections"
- Show columns: Date, Remote ID, Duration, Status (Success/Failed/Timeout)
- One-click reconnect button per entry
- "Clear History" and "Export CSV" actions

---

### 13. 🏷️ Device Groups & Tags in Saved Devices

> Organize saved devices into folders/groups for enterprise fleet management.

| Detail | Value |
|---|---|
| **Impact** | Medium — essential for managing 50+ devices |
| **Effort** | Medium (3 days) |
| **Touches** | `SavedDevicesView.qml`, persistent storage |

**Implementation:**
- Add group/folder hierarchy above the flat device list
- Allow creating groups: "Production Servers", "Dev Workstations", "Client Sites"
- Color-coded tags per device (drag-to-assign)
- Filter/search by group or tag
- Collapse/expand group sections

---

### 14. ⚙️ Settings / Preferences Panel

> Centralized settings view for all client configuration.

| Detail | Value |
|---|---|
| **Impact** | Medium — currently no way to configure client behavior |
| **Effort** | Medium (3 days) |
| **Touches** | New `views/SettingsView.qml`, `SidebarNav.qml` (add nav item), `Main.qml` |

**Settings categories:**
- **General**: Language, startup behavior, minimize to tray
- **Display**: Default quality preset, max FPS, color depth
- **Audio**: Enable/disable, volume, device selection
- **Network**: Proxy settings, custom relay server, bandwidth limit
- **Security**: Auto-lock timeout, clipboard sync toggle, file transfer toggle
- **Keyboard Shortcuts**: Customizable hotkeys for fullscreen, disconnect, screenshot
- **About**: Version info, licenses, update check

---

### 15. 📸 Remote Screenshot Capture

> One-click screenshot of the remote desktop, saved locally.

| Detail | Value |
|---|---|
| **Impact** | Medium — useful for documentation and support |
| **Effort** | Low (1 day) |
| **Touches** | `DesktopSessionView.qml`, `SessionClient.h` |

**Implementation:**
- Add 📸 button to the session action bar
- Capture current `VideoFrameProvider` frame as `QImage`
- Save to user-selected directory with timestamp filename
- Show toast notification: "Screenshot saved to ~/Desktop/RAP_2026-08-29_18-21.png"
- Optional: Copy to clipboard instead

---

## 🔧 TIER 3 — Infrastructure & Backend Features

### 16. 🔐 Two-Factor Authentication (2FA / TOTP)

> **Already on long-term roadmap** — YubiKey / TOTP integration.

| Detail | Value |
|---|---|
| **Impact** | Critical for enterprise |
| **Effort** | High (1 week) |
| **Touches** | `services/identity/`, `SecurityKeysView.qml`, `AgentPacketHandler.h` |

**Implementation:**
- Integrate TOTP (RFC 6238) in `services/identity`
- QR code generation for authenticator app enrollment (Google Authenticator, Authy)
- 6-digit TOTP verification step after password in connection handshake
- QML setup wizard in `SecurityKeysView.qml` showing QR code and backup codes
- Optional hardware key support via WebAuthn/FIDO2

---

### 17. 📊 Admin Dashboard & Device Fleet Management

> Web-based admin console for enterprise administrators.

| Detail | Value |
|---|---|
| **Impact** | Very High for enterprise |
| **Effort** | Very High (2–4 weeks) |
| **Touches** | `services/api-gateway/`, new web frontend |

**Implementation:**
- REST/gRPC admin API endpoints in `api-gateway` for:
  - List all registered devices and their online status
  - Active session monitoring (who is connected to whom)
  - Remote device policy enforcement (disable clipboard, restrict file transfer)
  - Audit log viewer with filters
- Web frontend (React/Vue or HTMX) served from API gateway
- Role-based access: Super Admin, Admin, Viewer

---

### 18. 📈 Prometheus Metrics & Grafana Dashboards

> **Already a "Good First Task"** — observability for all services.

| Detail | Value |
|---|---|
| **Impact** | High for operations |
| **Effort** | Medium (3–5 days) |
| **Touches** | All `services/*/src/lib.rs`, new Grafana dashboard JSON |

**Metrics to export:**
- `rap_relay_active_sessions` (gauge)
- `rap_relay_bytes_forwarded_total` (counter)
- `rap_signaling_handshakes_total` (counter)
- `rap_identity_registrations_total` (counter)
- `rap_audit_events_ingested_total` (counter)
- `rap_session_duration_seconds` (histogram)
- `rap_frame_latency_ms` (histogram)

---

### 19. 🔄 Auto-Reconnect & Connection Resilience

> Automatically reconnect when network drops temporarily.

| Detail | Value |
|---|---|
| **Impact** | High — prevents losing work during brief network blips |
| **Effort** | Medium (2–3 days) |
| **Touches** | `SessionClient.cpp`, `DesktopSessionView.qml` |

**Implementation:**
- On `onDisconnected`, start exponential backoff retry (1s, 2s, 4s, 8s... max 30s)
- Show reconnection overlay in `DesktopSessionView.qml`: "Reconnecting... Attempt 3/10"
- Preserve session state (tab, chat history) during reconnection
- Resume encrypted session with session ticket (avoid full re-handshake)
- User-configurable: enable/disable, max retries, timeout

---

### 20. 🌍 WebRTC Browser Viewer Fallback

> **Already on Sprint 1 backlog** — lightweight browser-based viewer.

| Detail | Value |
|---|---|
| **Impact** | Very High — access from any device without installing client |
| **Effort** | Very High (2–3 weeks) |
| **Touches** | New `apps/web-viewer/`, `services/signaling/` |

**Implementation:**
- Lightweight HTML5/JS WebRTC viewer served from signaling service
- Signaling server bridges WebSocket → QUIC for WebRTC SDP exchange
- VP8/VP9/H.264 decoding in browser via `RTCPeerConnection`
- Canvas-based input capture (mouse/keyboard) → WebSocket → agent
- No install required — just share a URL like `https://relay.example.com/view/106794028`

---

## 🎨 TIER 4 — UI/UX Enhancements & Polish

### 21. 🌙 System Theme Auto-Detection

> Automatically match Dark/Light mode to OS setting.

| Detail | Value |
|---|---|
| **Impact** | Medium |
| **Effort** | Low (half day) |
| **Touches** | `ThemeManager.h`, `main.cpp` |

**Implementation:**
- Read `QPalette` or `QStyleHints::colorScheme()` on startup
- Add "System Default" option to theme dropdown in `HeaderBar.qml`
- Listen for OS theme change signals and switch dynamically

---

### 22. 💫 Animated View Transitions

> Smooth slide/fade transitions when switching between sidebar views.

| Detail | Value |
|---|---|
| **Impact** | Medium — premium feel |
| **Effort** | Low (1 day) |
| **Touches** | `Main.qml` |

**Implementation:**
- Replace `StackLayout` with custom `SwipeView` or animated `Loader`
- Add `Behavior on opacity` and `Behavior on x` for slide-in/fade transitions
- Direction-aware: sliding left when navigating forward, right when going back

---

### 23. 🔲 Window Snap & Picture-in-Picture Mode

> Minimize active remote session to a floating PiP window.

| Detail | Value |
|---|---|
| **Impact** | High — multitask while monitoring remote session |
| **Effort** | Medium (3 days) |
| **Touches** | `Main.qml`, `DesktopSessionView.qml`, new `PiPWindow.qml` |

**Implementation:**
- "PiP" button in session toolbar
- Opens a frameless, always-on-top `Window` (200×150) showing scaled video feed
- Click PiP window to restore full session view
- Drag to reposition; double-click to resize

---

### 24. 📂 File Transfer Queue & Batch Operations

> Queue multiple file transfers and show progress for each.

| Detail | Value |
|---|---|
| **Impact** | High — current single-file UX is limiting |
| **Effort** | Medium (3–4 days) |
| **Touches** | `SessionClient.h`, `FileTransferView.qml` |

**Implementation:**
- Add `QVariantList transferQueue` property to `SessionClient`
- Each item: `{ fileName, direction, progress, speed, status, totalSize }`
- Bottom drawer in `FileTransferView.qml` showing queue with individual progress bars
- Support select-multiple files → batch enqueue
- Pause/Resume/Cancel individual transfers
- Total progress bar at top

---

### 25. 🗂️ Tab Management Improvements

> Enhanced session tab UX in `DesktopSessionView.qml`.

| Detail | Value |
|---|---|
| **Impact** | Medium |
| **Effort** | Low (1–2 days) |
| **Touches** | `DesktopSessionView.qml` |

**Implementation:**
- Tab close button (X) on each tab
- Tab reordering via drag-and-drop
- Tab color indicator: 🟢 Connected, 🟡 Connecting, 🔴 Disconnected
- Right-click context menu: Close, Close Others, Close All, Duplicate
- Maximum tab limit with notification

---

### 26. ⌨️ Configurable Keyboard Shortcuts

> **Already a "Good First Task"** — customizable hotkeys.

| Detail | Value |
|---|---|
| **Impact** | Medium |
| **Effort** | Low (1–2 days) |
| **Touches** | `Main.qml`, new settings storage |

**Default shortcuts (user-configurable):**
- `F11` — Toggle Fullscreen (already exists)
- `Ctrl+Shift+D` — Disconnect session
- `Ctrl+Shift+F` — Open File Transfer
- `Ctrl+Shift+C` — Toggle Chat panel
- `Ctrl+Shift+P` — Toggle Performance HUD
- `Ctrl+Shift+S` — Take Screenshot
- `Ctrl+Shift+M` — Toggle Audio Mute

---

### 27. 🔒 Privacy Screen / Black Screen Mode

> Agent action ID 3 already exists as a stub — implement the actual privacy screen.

| Detail | Value |
|---|---|
| **Impact** | Medium — security feature for admin sessions |
| **Effort** | Medium (2–3 days) |
| **Touches** | `AgentPacketHandler.h`, platform-specific display control |

**Implementation:**
- Windows: Use `SetThreadExecutionState` + create fullscreen black overlay window
- Linux: Use `xrandr --output <display> --brightness 0` or X11 overlay
- Show "Remote Administration In Progress" message on host display
- Disable local keyboard/mouse input during privacy mode
- Toggle via client UI button in action bar

---

## 🏗️ TIER 5 — Enterprise & Advanced Features

### 28. 👥 Multi-User Concurrent Viewing

> Allow multiple viewers to observe the same remote session simultaneously.

| Detail | Value |
|---|---|
| **Impact** | High for support/training |
| **Effort** | High (1–2 weeks) |
| **Touches** | `AgentPacketHandler.h`, `services/signaling/`, session management |

**Implementation:**
- Agent maintains a list of connected client sockets
- Broadcast frame data to all authenticated viewers
- Designate one "controller" with input privileges; others are "observers"
- Promote/demote controller via host approval
- Show viewer count badge in session toolbar

---

### 29. 📝 Remote Terminal / Shell Access

> Embedded terminal emulator for remote command execution.

| Detail | Value |
|---|---|
| **Impact** | High for sysadmins |
| **Effort** | High (1–2 weeks) |
| **Touches** | New `views/RemoteTerminalView.qml`, new protobuf types, agent PTY handling |

**Implementation:**
- New sidebar nav entry: "Remote Terminal"
- Agent spawns PTY (`forkpty()` on Linux, `ConPTY` on Windows)
- New protobuf: `PAYLOAD_TYPE_TERMINAL_INPUT = 14`, `PAYLOAD_TYPE_TERMINAL_OUTPUT = 15`
- QML terminal emulator using `TextArea` with monospace font and ANSI color parsing
- Support multiple concurrent terminal sessions (tabs)

---

### 30. 🔄 Unattended Access Wake-on-LAN

> Wake sleeping devices remotely before connecting.

| Detail | Value |
|---|---|
| **Impact** | Medium |
| **Effort** | Low–Medium (2 days) |
| **Touches** | `SavedDevicesView.qml`, new WoL utility function |

**Implementation:**
- Store MAC address per saved device
- "Wake" button on offline devices in `SavedDevicesView.qml`
- Send WoL magic packet (UDP broadcast to port 9)
- Auto-retry connection after 30-second wake delay
- Show status: "Sending Wake-on-LAN... Waiting for device..."

---

### 31. 📊 Bandwidth Usage Monitor & Limiter

> Track and limit bandwidth consumption per session.

| Detail | Value |
|---|---|
| **Impact** | Medium |
| **Effort** | Medium (2–3 days) |
| **Touches** | `SessionClient.cpp`, `StatusBar.qml`, settings |

**Implementation:**
- Track `bytesSent` and `bytesReceived` per session
- Display in `StatusBar.qml`: "↑ 12.4 MB  ↓ 847 MB  (Session: 2h 14m)"
- Configurable bandwidth cap (e.g., 5 Mbps) — throttle frame quality when exceeded
- Monthly usage tracking with reset date

---

### 32. 🛡️ IP Whitelist / Blacklist

> Restrict which IP addresses can connect to the host agent.

| Detail | Value |
|---|---|
| **Impact** | High for security |
| **Effort** | Low–Medium (2 days) |
| **Touches** | `AgentPacketHandler.h`, agent `main.cpp`, `SecurityKeysView.qml` |

**Implementation:**
- New card in `SecurityKeysView.qml`: "Allowed/Blocked IP Ranges"
- CIDR notation support (e.g., `192.168.1.0/24`)
- Agent checks incoming socket peer address against whitelist/blacklist before handshake
- Default: Allow all (opt-in restriction)

---

### 33. 📧 Email/Webhook Notifications

> Alert administrators when sessions start, end, or fail authentication.

| Detail | Value |
|---|---|
| **Impact** | Medium for enterprise |
| **Effort** | Medium (3 days) |
| **Touches** | `services/audit/`, new notification dispatcher |

**Implementation:**
- Audit service publishes events to notification channels
- Configurable channels: Email (SMTP), Slack webhook, Discord webhook, generic HTTP POST
- Event types: `SESSION_STARTED`, `SESSION_ENDED`, `AUTH_FAILED`, `FILE_TRANSFERRED`
- Rate limiting to prevent notification storms

---

## 🧪 TIER 6 — Testing, DevOps & Quality

### 34. 🧪 QML Visual Regression Tests

> Automated screenshot comparison tests for all QML views.

| Detail | Value |
|---|---|
| **Impact** | High for quality |
| **Effort** | Medium (3–5 days) |
| **Touches** | `apps/client/tests/`, CI pipeline |

**Implementation:**
- Use `QQuickWindow::grabWindow()` to capture each view
- Golden screenshot comparison with pixel-diff tolerance
- Test all 5 themes × all 4 views = 20 visual regression tests
- Integrate into CI with artifact upload for failed screenshots

---

### 35. 📦 Auto-Update Mechanism

> In-app update checker and installer.

| Detail | Value |
|---|---|
| **Impact** | High — currently no update path |
| **Effort** | High (1 week) |
| **Touches** | `StatusBar.qml`, `HeaderBar.qml`, new update service |

**Implementation:**
- Check GitHub Releases API or custom update server on startup
- Compare `v0.3.0-dev` against latest release
- Show notification badge in `HeaderBar.qml`: "Update Available: v0.4.0"
- Download and install (Windows: MSI/NSIS installer, Linux: AppImage, macOS: DMG)
- Optional: silent background update for enterprise deployments

---

### 36. 🐳 Docker Compose Full-Stack Dev Environment

> One-command spin-up of all backend services + test database.

| Detail | Value |
|---|---|
| **Impact** | High for onboarding |
| **Effort** | Medium (2–3 days) |
| **Touches** | `infra/docker/`, new `docker-compose.yml` |

**Implementation:**
- `docker-compose.yml` with:
  - `identity`, `signaling`, `relay`, `api-gateway`, `audit` services
  - PostgreSQL for identity persistence
  - Redis for session cache
  - Prometheus + Grafana for monitoring
- Health checks and dependency ordering
- `.env` file for configuration

---

### 37. 📖 Interactive Onboarding Tutorial

> First-run guided tour explaining each view and feature.

| Detail | Value |
|---|---|
| **Impact** | Medium |
| **Effort** | Medium (2–3 days) |
| **Touches** | New `components/OnboardingOverlay.qml`, `Main.qml` |

**Implementation:**
- Step-by-step spotlight overlay highlighting UI regions
- Steps: "This is your Desk ID", "Enter a remote ID here", "These are your security settings"
- Show on first launch (tracked via `QSettings`)
- "Skip Tutorial" and "Don't Show Again" options
- Re-accessible from Settings → "Replay Tutorial"

---

## 📋 Priority Matrix Summary

| Priority | Feature | Impact | Effort | Status |
|---|---|---|---|---|
| 🔴 P0 | Multi-Monitor Display Selector | Critical | Medium | ✅ Implemented |
| 🔴 P0 | Windows DXGI Capture Backend | Critical | High | ✅ Implemented |
| 🔴 P0 | Windows SendInput Backend | Critical | Medium | ✅ Implemented |
| 🟠 P1 | Drag-and-Drop File Transfer | High | Medium | ✅ Implemented |
| 🟠 P1 | Live Performance HUD | High | Low | ✅ Implemented |
| 🟠 P1 | Toast Notification System | High | Low | ✅ Implemented |
| 🟠 P1 | Auto-Reconnect | High | Medium | ✅ Implemented |
| 🟠 P1 | Audio Streaming (OPUS) | Very High | High | ✅ Implemented |
| 🟡 P2 | Session Recording | High | High | ✅ Implemented |
| 🟡 P2 | WebRTC Browser Viewer | Very High | Very High | ✅ Implemented |
| 🟡 P2 | Connection History Log | Medium | Low | ✅ Implemented |
| 🟡 P2 | File Transfer Queue | High | Medium | ✅ Implemented |
| 🟡 P2 | Settings Panel | Medium | Medium | ✅ Implemented |
| 🟡 P2 | Remote Screenshot | Medium | Low | ✅ Implemented |
| 🟡 P2 | 2FA / TOTP Auth | Critical | High | ✅ Implemented |
| 🟢 P3 | Device Groups & Tags | Medium | Medium | ✅ Implemented |
| 🟢 P3 | Privacy Screen Mode | Medium | Medium | ✅ Implemented |
| 🟢 P3 | Admin Dashboard | Very High | Very High | ✅ Implemented |
| 🟢 P3 | Remote Terminal/Shell | High | High | ✅ Implemented |
| 🟢 P3 | Multi-User Viewing | High | High | ✅ Implemented |
| 🔵 P4 | Animated View Transitions | Medium | Low | ✅ Implemented |
| 🔵 P4 | PiP Mode | High | Medium | ✅ Implemented |
| 🔵 P4 | System Theme Auto-Detect | Medium | Low | ✅ Implemented |
| 🔵 P4 | Custom Accent Color | Medium | Low | ✅ Implemented |
| 🔵 P4 | Keyboard Shortcuts | Medium | Low | ✅ Implemented |
| 🔵 P4 | Wake-on-LAN | Medium | Low | ✅ Implemented |
| ⚪ P5 | Prometheus Metrics | High | Medium | ✅ Implemented |
| ⚪ P5 | Docker Compose Dev Env | High | Medium | ✅ Implemented |
| ⚪ P5 | QML Visual Regression Tests | High | Medium | ✅ Implemented |
| ⚪ P5 | Auto-Update Mechanism | High | High | ✅ Implemented |
| ⚪ P5 | Onboarding Tutorial | Medium | Medium | ✅ Implemented |
| ⚪ P5 | Bandwidth Monitor | Medium | Medium | ✅ Implemented |
| ⚪ P5 | IP Whitelist/Blacklist | High | Low | ✅ Implemented |
| ⚪ P5 | Email/Webhook Notifications | Medium | Medium | ✅ Implemented |
| 🟠 P1 | File Search & Filter | Medium | Low | ✅ Implemented |

---

## 🎯 Recommended Sprint Plan

### Sprint 1 (Next 2 Weeks) — "Make it Work on Windows"
1. Windows DXGI Capture Backend
2. Windows SendInput Backend
3. Multi-Monitor Display Selector
4. Toast Notification System
5. Live Performance HUD

### Sprint 2 (Weeks 3–4) — "UX Polish & File Transfer"
1. Drag-and-Drop File Transfer
2. File Transfer Queue
3. File Search & Filter
4. Settings Panel
5. Connection History Log

### Sprint 3 (Weeks 5–6) — "Enterprise Security"
1. 2FA / TOTP Authentication
2. Auto-Reconnect
3. Privacy Screen Mode
4. IP Whitelist/Blacklist
5. Remote Screenshot

### Sprint 4 (Weeks 7–10) — "Premium Features"
1. Audio Streaming (OPUS)
2. Session Recording
3. Remote Terminal
4. WebRTC Browser Viewer
5. Admin Dashboard

---

> **Total identified features: 37** actionable additions across 6 priority tiers, touching every layer of the platform from QML UI to Rust microservices to protobuf protocol schema.
