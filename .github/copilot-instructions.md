# GitHub Copilot Custom Instructions

Source of Truth: `docs/REMOTE-DESKTOP-ARCHITECTURE.md` (v4.0) and `AGENT_RULES.md`.

- Continuously maintain `docs/IMPLEMENTATION_LOG.md` and sync `docs/architecture_and_implementation_plan.md` whenever features or milestones are completed or updated.
- Enforce the Quality Gate Pipeline: run static analysis (`cppcheck`, `clang-tidy`, `clippy`, `rustfmt`), compile, and run tests via `tools/build.sh`.
- Backend code must be in Rust (`services/`) with `#![forbid(unsafe_code)]` at crate root.
- Desktop UI code must use Qt 6 (LGPLv3 dynamic linking) + QML. Never statically link Qt. Avoid GPL-only modules (`Qt Charts`).
- Host agent must be built in C++20 and remain strictly Qt-free.
- Do not use platform `#ifdef` macros (`_WIN32`, `__linux__`, `__APPLE__`) outside `platform/<os>/` directories.
- QML elements must declare `id` first, use relative sizing, consume `Palette.*` tokens, and contain no business logic.
- Use `QLoggingCategory` (C++) and `tracing` (Rust) for logging. Never log secrets or frame content.
- Commit messages follow Conventional Commits standard (`feat:`, `fix:`, `sec:`, `refactor:`, `test:`, `docs:`, `ci:`).
