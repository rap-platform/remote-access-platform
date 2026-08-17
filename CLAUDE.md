# Claude Agent Workspace Instructions

Source of Truth: `REMOTE-DESKTOP-ARCHITECTURE.md` (v4.0) and `AGENT_RULES.md`.

## Core Constraints
- **Backend**: Rust ONLY (`services/`). `#![forbid(unsafe_code)]` at crate root.
- **Client UI**: Qt 6 (LGPLv3 dynamic linking only) + QML (`apps/client/`).
- **Client/Agent Core**: C++20 (`apps/client/src/core/`, `apps/agent/`).
- **Agent**: MUST remain Qt-free.
- **Cross-Platform**: Windows, Linux, macOS. NO platform `#ifdef` macros in `apps/` outside `platform/<os>/`.
- **QML Rules**:
  - `id` declared as first property.
  - Relative sizing only (`Metrics.*`, `anchors`, `Layout.*`). No hardcoded pixel dimensions.
  - Colors from `Palette.*`. No raw hex codes outside `qml/theme/`.
  - Zero business logic in QML.
- **Logging**: `QLoggingCategory` (C++) and `tracing` (Rust). Never log credentials, keys, or frame data.
- **Commits**: Conventional Commits (`feat:`, `fix:`, `sec:`, `refactor:`, `test:`).
