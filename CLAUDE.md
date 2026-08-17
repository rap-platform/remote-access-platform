# Claude Agent Workspace Instructions

Source of Truth: `docs/REMOTE-DESKTOP-ARCHITECTURE.md` (v4.0) and `AGENT_RULES.md`.

## Core Constraints
- **Live Implementation Log & Plan Sync**: Maintain `docs/IMPLEMENTATION_LOG.md` detailing what, how, why, standards followed, and test results. Update `docs/architecture_and_implementation_plan.md` as milestones/features/scripts are added or completed.
- **Quality Gate Pipeline**: Run static analysis (`cppcheck`, `clang-tidy`, `clippy`, `rustfmt`), compile, and execute unit/integration tests before any build is marked ready.
- **Automated Tools**: Utilize `tools/build.sh`, `tools/test.sh`, `tools/lint.sh`, `tools/setup_deps.sh`.
- **Backend**: Rust ONLY (`services/`). `#![forbid(unsafe_code)]` at crate root.
- **Client UI**: Qt 6 (LGPLv3 dynamic linking only) + QML (`apps/client/`).
- **Client/Agent Core**: C++20 (`apps/client/src/core/`, `apps/agent/`).
- **Agent**: MUST remain Qt-free.
- **Cross-Platform**: Windows, Linux, macOS. NO platform `#ifdef` macros in `apps/` outside `platform/<os>/`.
- **QML Rules**: `id` first, relative sizing (`Metrics.*`), colors (`Palette.*`), zero business logic in QML.
- **Logging**: `QLoggingCategory` (C++) and `tracing` (Rust). Never log credentials, keys, or frame data.
- **Commits**: Conventional Commits (`feat:`, `fix:`, `sec:`, `refactor:`, `test:`, `docs:`, `ci:`).
