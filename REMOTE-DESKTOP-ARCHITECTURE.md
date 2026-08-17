# Remote Access Platform — Architecture, Standards & Security Blueprint
**Version 4.0 — Working Document to Build Against**

Changelog from v1→v2: backend consolidated to **Rust only** (no Go); explicit
**cross-platform** requirement threaded through every layer; full **testing
pyramid** (unit / integration / UI automation) planned from day one; QML
structural rules (`id`, relative `width`/`height`) and **centralized
theming/design-token system**; expanded Qt/QML/C++ industry-standard
references with links to well-known open-source Qt projects used as style
references.

Changelog v2→v3: **all UI automation switched to free/open-source tooling**
(accessibility-tree drivers + Robot Framework, no Squish) — §6.3/6.4; **Qt
commercial license dropped**, full **LGPLv3 compliance plan** added
including the module-license audit table and the embedded "Installation
Information" trap and its mitigation — §11.

Changelog v3→v4: added **§7 QML Hot Reload** (self-built `HotReloadManager`,
compiled out of Release builds, plus Qt Creator's free built-in preview as a
complement) and **§8 Centralized Logging Architecture** (`QLoggingCategory`
on the C++ side / `tracing` on the Rust side, single message-handler sink,
runtime-toggleable categories, explicit separation from tamper-evident audit
logging). Sections renumbered 7→13 accordingly.

---

## 0. Purpose & Scope

This document defines the target architecture, repository layout, coding
standards, testing strategy, and security/compliance posture for a
commercial-grade, **cross-platform** remote desktop / device management
platform (AnyDesk/RustDesk/MeshCentral-class). Treat it as a living spec.

**Non-negotiable constraints:**
- No AnyDesk protocol reverse engineering or code reuse.
- No AGPL/GPL code copied into the product — study RustDesk/Sunshine architecture only, never their code.
- Own wire protocol, own crypto handshake built on vetted primitives — never invented crypto.
- Security, testing, and licensing hygiene designed in from commit #1.
- **Cross-platform from the start**: Windows, Linux, macOS for client/agent; Linux (containerized) for backend; architecture must not assume a single OS anywhere in the stack.

---

## 1. Technology Stack Decisions

| Layer | Choice | Rationale |
|---|---|---|
| Desktop client UI | Qt 6 (LGPLv3, dynamic linking only — no commercial license, see §11) + QML/Qt Quick | Cross-platform (Windows/Linux/macOS) from one codebase; your existing expertise |
| Client/Agent core | C++20 | Performance, GStreamer interop, native OS API access on all three platforms |
| **Backend — ALL services** | **Rust** | Single language across identity, signaling, relay, API, audit. Memory safety across the *entire* attacker-facing surface, not just the relay. Simpler ops (one toolchain, one dependency-audit pipeline, one team skill set) than splitting Go/Rust. See §1.1. |
| Video pipeline | GStreamer / FFmpeg | Cross-platform hardware codec abstraction (VAAPI/NVENC/QSV on Linux/Windows, VideoToolbox on macOS) |
| Transport | QUIC (`quinn` on the Rust side, `msquic`/`quiche` bindings on the C++ side) with TLS 1.3 TCP fallback | NAT-friendly, built-in stream multiplexing + encryption |
| Crypto | libsodium (C++ side) / `RustCrypto` or `ring`/`sodiumoxide` (Rust side) — same underlying primitives (X25519, XChaCha20-Poly1305, Ed25519) on both | Avoid hand-rolled crypto entirely; primitive parity between client and backend avoids interop bugs |
| DB | PostgreSQL (system of record) + Redis (presence/session cache) | Standard, well audited, cross-platform-deployable |
| Build | CMake + Ninja (C++, cross-platform toolchains via `vcpkg`/`Conan`), Cargo (Rust) | Reproducible cross-platform builds |
| CI | GitHub Actions (or GitLab CI) with **matrix builds**: `windows-latest`, `ubuntu-latest`, `macos-latest` for every client/agent change | Cross-platform regressions caught on every PR, not at release time |

### 1.1 Why Rust for the entire backend (not Go)

Since the platform's core value proposition is *security* (session
confidentiality, device identity, relay trust), a single memory-safe
language across identity/signaling/relay/API/audit removes an entire class
of CVEs (buffer overflow, use-after-free, data races) from 100% of the
backend attack surface, not just the relay hot path. Trade-offs accepted
knowingly:

- Slower initial development velocity than Go for CRUD-style API/admin work — mitigated by using mature Rust web frameworks (`axum` or `actix-web`) and code generation from the shared `proto/` schema.
- Smaller hiring pool than Go — mitigated by keeping service boundaries clean (§3) so onboarding one service doesn't require understanding the whole backend.
- `#![forbid(unsafe_code)]` at the crate root for every service by default; `unsafe` only permitted in a narrowly scoped, separately audited crate with a documented safety invariant per block (e.g., an FFI shim to a syscall).

### 1.2 Cross-platform strategy (explicit, not incidental)

| Component | Windows | Linux | macOS |
|---|---|---|---|
| Client UI | Qt6/QML | Qt6/QML | Qt6/QML (same QML tree, no platform-specific QML files except where OS look-and-feel truly requires it) |
| Screen capture | DXGI Desktop Duplication | X11 (XShm/XComposite) + Wayland (PipeWire + xdg-desktop-portal) | ScreenCaptureKit |
| Input injection | `SendInput` | XTest (X11) / `uinput` (Wayland, needs privileged helper) | `CGEvent` |
| Hardware encode | NVENC / QSV / MediaFoundation | VAAPI / NVENC | VideoToolbox |
| Agent privilege model | Windows Service + user-session helper | systemd service + privileged input helper over local socket | LaunchDaemon + privileged helper (Accessibility/Screen Recording entitlements) |
| Packaging | MSI/MSIX, signed | AppImage/deb/rpm, signed | signed + notarized .pkg/.dmg |
| Backend deployment | N/A (Linux containers only) | Docker/Kubernetes | N/A |

**Architectural rule enforcing this:** every platform-specific implementation
sits behind an interface defined once in `libs/` (`ICaptureBackend`,
`IInputBackend`, `IEncoderBackend`). Application code (`apps/client`,
`apps/agent`) never contains `#ifdef _WIN32` style branching outside the
`platform/<os>/` subfolders — this is a **CI-enforced** rule (see §4.1
static analysis) so cross-platform support doesn't erode over time.

---

## 2. High-Level System Architecture

```
                         ┌─────────────────────────────┐
                         │        Control Plane        │
                         │      (Rust microservices)    │
                         │                              │
                         │  Identity/Registry           │
                         │  Signaling (WebSocket/QUIC)  │
                         │  Auth (OIDC/SSO/MFA)         │
                         │  Policy/RBAC                 │
                         │  Audit Log Service           │
                         └──────────────┬───────────────┘
                                        │
                         ┌──────────────┴───────────────┐
                         │        Data Plane             │
                         │  STUN / TURN-style Relay      │
                         │  (Rust, stateless, horiz.     │
                         │   scalable, never decrypts)   │
                         └──────────────┬───────────────┘
                                        │
              ┌─────────────────────────┴─────────────────────────┐
              │                                                    │
      ┌───────▼────────┐                                  ┌────────▼───────┐
      │  Client/Viewer  │◄──────── E2E Encrypted ─────────►│  Agent/Host    │
      │  Qt6/QML + C++  │        (X25519 + XChaCha20)       │  C++20 core    │
      │  Win/Linux/Mac  │                                    │  Win/Linux/Mac │
      └─────────────────┘                                  └────────────────┘
```

Key principle unchanged: **control plane and relay never see plaintext
session data.** Session keys are negotiated end-to-end between client and
agent; the backend only brokers connection metadata.

---

## 3. Repository Structure (Monorepo, Scalable, Cross-Platform)

```
remote-platform/
├── apps/
│   ├── client/                     # Qt6/QML viewer — builds on Win/Linux/Mac from one tree
│   │   ├── src/
│   │   │   ├── core/               # Non-UI C++ (session, crypto, transport) — platform-agnostic
│   │   │   ├── ui/                 # QML + view-model C++ glue
│   │   │   ├── devtools/           # HotReloadManager — compiled ONLY when ENABLE_HOT_RELOAD=ON, see §7
│   │   │   └── platform/           # win/, linux/, mac/ — ONLY place OS-specific code may live
│   │   ├── qml/
│   │   │   ├── views/              # Screens (one root component per file)
│   │   │   ├── components/         # Reusable, composable QML components
│   │   │   └── theme/              # Centralized design-token singletons — see §5
│   │   ├── tests/
│   │   │   ├── unit/               # C++ unit tests (Qt Test / GoogleTest)
│   │   │   ├── qml/                # QML unit tests (Qt Quick Test / qmltestrunner)
│   │   │   └── ui/                 # UI automation suite (FOSS accessibility-tree drivers — see §6.3)
│   │   └── CMakeLists.txt
│   │
│   └── agent/                      # Host/agent application
│       ├── src/
│       │   ├── capture/            # x11/, wayland/, win/, mac/
│       │   ├── encode/             # gstreamer/, vaapi/, nvenc/, videotoolbox/
│       │   ├── input/              # x11/, uinput/, win/, mac/
│       │   ├── clipboard/
│       │   ├── filesystem/
│       │   └── session/
│       ├── tests/
│       │   ├── unit/
│       │   └── integration/        # Real capture/encode pipeline run against a virtual display (Xvfb on Linux CI, similar harnesses on Win/Mac runners)
│       └── CMakeLists.txt
│
├── libs/                           # Shared C++ "SDK" — platform-agnostic, 100% unit-testable in isolation
│   ├── protocol/                   # Wire format, versioning (Protobuf/FlatBuffers schema-first)
│   ├── transport/                  # QUIC/TCP/UDP abstraction
│   ├── security/                   # Crypto wrappers over libsodium — no raw crypto calls elsewhere
│   ├── common/                     # Centralized logging (see §8), config, metrics, error types
│   └── testing/                    # Shared test fixtures/mocks/fakes
│
├── services/                       # Backend — Rust, all services
│   ├── identity/                   # Device identity, cert issuance
│   ├── signaling/                  # WebSocket/QUIC rendezvous
│   ├── relay/                      # Data-plane packet forwarding, never decrypts
│   ├── api-gateway/                # REST/GraphQL for admin/web UI
│   ├── audit/                      # Immutable audit log ingestion
│   ├── shared/                     # Shared Rust crates (auth middleware, error types, proto bindings)
│   └── tests/
│       ├── unit/                   # Per-crate `#[cfg(test)]`
│       └── integration/            # `tests/` dir per service, spins up real Postgres/Redis via testcontainers
│
├── proto/                          # Protobuf schema — single source of truth for wire + API contracts, codegen for both C++ and Rust
│
├── infra/
│   ├── terraform/
│   ├── k8s/
│   └── docker/
│
├── e2e/                            # Cross-service, cross-platform end-to-end test suite (see §6)
│   ├── scenarios/                  # e.g. "Linux agent ↔ Windows client over relay"
│   └── ci-matrix.yml
│
├── docs/
│   ├── architecture/               # ADRs (Architecture Decision Records)
│   ├── security/                   # Threat models, pentest reports
│   ├── testing-strategy.md         # Canonical copy of §6
│   └── protocol-spec.md
│
├── tools/                          # Codegen, linters, release scripts
├── .github/workflows/              # CI/CD — matrix across win/linux/mac for client & agent, linux for services
├── THIRD_PARTY_LICENSES.md
├── SECURITY.md
└── CODING_STANDARDS.md             # Canonical copy of §4
```

**Scalability rules:**
- `libs/` modules have zero circular dependencies; each compiles/tests standalone.
- `apps/client` and `apps/agent` only share `libs/protocol` and `libs/security` — never talk to each other's source directly.
- New platform support = new `platform/<os>/` folder implementing an existing interface — never a fork of the app.
- Every `services/*` crate exposes a trait-based interface for its storage/external dependencies so it can be unit-tested with fakes and integration-tested with real infra.

---

## 4. Coding Standards

### 4.1 C++ (Client + Agent + libs)

- **Standard:** C++20, `-Wall -Wextra -Wpedantic -Werror` (MSVC `/W4 /WX`) — same warning-clean bar on all three compilers (MSVC, GCC, Clang) in CI matrix.
- **Style base:** LLVM/Google style, enforced via `clang-format` (`.clang-format` checked in, CI-blocking).
- **Static analysis:** `clang-tidy` + `cppcheck` in CI; includes a **custom check** blocking `#ifdef _WIN32` / `#ifdef __linux__` / `#ifdef __APPLE__` outside `platform/` directories, to keep the cross-platform boundary enforced mechanically, not just by convention.
- **Line length: 100 columns.**
- **File length (soft CI-warning ceiling):** header ≤ 300 lines, `.cpp` ≤ 600 lines — split by responsibility if exceeded.
- **Function length: ≤ 60 lines.**
- **Class size:** ≤ 15 public methods soft ceiling.
- **Naming:** Classes/Types `PascalCase`; functions/vars `camelCase`; constants `kPascalCase`; private members trailing underscore `sessionId_`; files `snake_case.cpp/.h`.
- **No raw `new`/`delete`** — smart pointers or arena allocators in hot paths.
- **No raw crypto/socket syscalls outside `libs/security`/`libs/transport`.**
- **Error handling:** `std::expected<T, Error>` / `Result<T>` pattern — no exceptions crossing module boundaries in the agent.
- **All public headers Doxygen-documented.**
- **Reference projects for style/architecture patterns** (well-known, actively maintained, worth reading actual source from): Qt Creator itself (the IDE is a large, mature Qt/C++ codebase following Qt's own conventions), KDE Frameworks / Kirigami (large-scale QML architecture at scale), Mixxx (cross-platform Qt/QML audio app with a mature testing setup), Tiled (smaller, very readable cross-platform Qt app).

### 4.2 QML — structural rules (enforced, not optional)

These four rules are mandatory on every QML file in the project, checked by
`qmllint` custom rules plus code review:

1. **Every visual element declares an `id`.** Even if unused today, it keeps the tree referenceable for tests, dynamic styling, and future maintenance, and matches the official Qt convention that `id` is the first-declared property.
2. **`width` and `height` are always relative, never hardcoded pixel literals**, except inside the single centralized theme/token file (§5). Use:
   - `anchors.fill: parent` / `anchors.left/right/top/bottom` with margins from the theme spacing scale, or
   - `Layout.preferredWidth: parent.width * 0.4`-style relative sizing inside `RowLayout`/`ColumnLayout`/`GridLayout`, or
   - `implicitWidth`/`implicitHeight` computed from content, never a bare number like `width: 320`.
   This is what makes the UI scale correctly across a 1080p laptop, a 4K monitor, and a small embedded touch panel without per-resolution QML forks.
3. **Property order follows the official Qt QML Coding Conventions**: `id` first, then property declarations, then signal declarations, then JS functions, then attached/grouped properties, then child objects/states/transitions — each group separated by a blank line.
4. **No business logic in QML.** QML binds to C++ view-models (`QObject`-derived, `QML_ELEMENT`) exposed via context properties or singletons — QML only expresses layout, bindings, and simple presentation logic. Anything beyond ~10 lines of imperative JS moves to C++.

Additional standards:
- **Line length: 100 columns. File length: ≤ 250 lines** — decompose large screens into `components/`.
- **One component per file**, filename matches root component name (`PascalCase.qml`).
- Group properties as blocks (`anchors { left: parent.left; top: parent.top }`) rather than repeated dotted lines, per official convention.
- Private/internal properties grouped into a single `QtObject { id: d }` child rather than scattered top-level properties, per official convention.
- Format with `qmlformat`, lint with `qmllint` — both CI-blocking.
- **Primary reference:** the official [Qt QML Coding Conventions](https://doc.qt.io/qt-6/qml-codingconventions.html) and the community-maintained [Furkanzmc/QML-Coding-Guide](https://github.com/Furkanzmc/QML-Coding-Guide) (widely used as a supplementary practical guide covering binding performance, `Connections` pitfalls, and context-property costs beyond what the official docs cover).

### 4.3 Rust (all backend services)

- `rustfmt` + `clippy -D warnings` enforced in CI.
- `#![forbid(unsafe_code)]` at crate root for every service; `unsafe` only in a dedicated, separately reviewed crate with a documented safety invariant per block.
- **Line length: 100 columns. Function length: ≤ 60 lines. File length: ≤ 500 lines**, split into `handlers/`, `service/`, `repo/` layers.
- `cargo audit` (vulnerability advisories) and `cargo deny check licenses` run on every PR — merge-blocking.
- Explicit `Result<T, E>` everywhere; no `.unwrap()`/`.expect()` outside tests and `main()` startup — enforced via clippy lint config.
- Prefer `axum` for HTTP/WebSocket services (async, tower-based middleware, easy to unit-test handlers in isolation) and `quinn` for QUIC.

### 4.4 Cross-cutting

- **Commit convention:** Conventional Commits (`feat:`, `fix:`, `sec:`, `refactor:`, `test:`) — enables changelog automation and flags security/testing-relevant commits.
- **Coverage targets:** ≥ 80% line coverage on `libs/security`, `libs/protocol`, `libs/transport`, and every Rust `services/*` crate (highest-risk shared code); ≥ 60% elsewhere as a floor, not a ceiling.
- **ADRs required** for: wire protocol changes, crypto primitive changes, new third-party dependency in a privileged process, any new platform-specific code path.

---

## 5. Centralized Theming & Design Tokens (QML)

All visual constants — colors, font families/sizes/weights, spacing,
corner radii, elevation/shadow values, animation durations, and
breakpoint/resolution thresholds — live in **one centralized token module**,
never inline in feature QML. This is the standard pattern used across mature
Qt Quick projects (Qt Quick Controls' own Material/Universal styles use the
same singleton approach internally).

```
apps/client/qml/theme/
├── qmldir                  # declares the Theme module + `pragma Singleton` types
├── Tokens.qml              # pragma Singleton — raw design tokens (source of truth)
├── Palette.qml             # pragma Singleton — semantic colors, references Tokens, supports light/dark
├── Typography.qml          # pragma Singleton — font family/sizes/weights, scales with Screen.pixelDensity
└── Metrics.qml              # pragma Singleton — spacing scale, radii, breakpoints, relative sizing helpers
```

Example pattern (`Palette.qml`):

```qml
pragma Singleton
import QtQuick

QtObject {
    readonly property bool isDark: Tokens.currentTheme === Tokens.Theme.Dark

    readonly property color background: isDark ? Tokens.neutral900 : Tokens.neutral50
    readonly property color surface:    isDark ? Tokens.neutral800 : Tokens.neutral0
    readonly property color textPrimary: isDark ? Tokens.neutral0  : Tokens.neutral900
    readonly property color accent:      Tokens.brand500
    readonly property color danger:      Tokens.red500
    readonly property color success:     Tokens.green500
}
```

`Metrics.qml` centralizes relative-sizing helpers so no feature file computes
scaling math itself:

```qml
pragma Singleton
import QtQuick

QtObject {
    // Base design resolution the mockups were built at
    readonly property real baseWidth: 1440
    readonly property real baseHeight: 900

    // Call from any Window: Metrics.scale(Screen.width, Screen.height)
    function scale(actualWidth, actualHeight) {
        return Math.min(actualWidth / baseWidth, actualHeight / baseHeight)
    }

    readonly property int spacingXs: 4
    readonly property int spacingSm: 8
    readonly property int spacingMd: 16
    readonly property int spacingLg: 24
    readonly property int spacingXl: 32
    readonly property int radiusSm: 4
    readonly property int radiusMd: 8
}
```

Rules enforced by review + `qmllint` custom checks:
- **No hex color literals, no bare font sizes/pixel values outside `theme/`.** A feature file writes `color: Palette.background`, `font.pixelSize: Typography.bodySize`, `spacing: Metrics.spacingMd` — never `"#1e1e1e"` or `font.pixelSize: 14`.
- Light/dark (and any future high-contrast/branding) themes are a **single property flip** (`Tokens.currentTheme`) — no feature QML re-implements theme switching.
- Resolution/DPI scaling goes through `Metrics.scale()` uniformly — this is what keeps the same QML tree correct on a 1080p desktop monitor, a 4K display, and a small embedded panel without per-resolution forks, directly addressing the "scale across resolutions" requirement.
- This mirrors the pattern used in Qt Quick Controls' own Material style (`Material.theme`, `Material.accent` as attached properties resolved through a central style object) and the "singleton style object" pattern documented in Qt's own Qt Quick Controls customization guide and widely adopted in production apps (e.g., Ultimaker Cura's `theme.json`-driven `UM.Theme.getColor()` pattern is a well-known real-world reference for exactly this approach).

---

## 6. Testing Strategy — Planned From Day One

Testing is a first-class architectural concern, not an afterthought bolted
on before release. The pyramid below is set up starting at **M1**, before
feature code exists, so every subsequent milestone lands with tests, not
"tests to be added later."

### 6.1 Unit tests

| Layer | Framework | Scope |
|---|---|---|
| C++ (`libs/`, `apps/*/core`) | Qt Test (integrates natively with CMake/Qt build, good QObject/signal support) or GoogleTest for pure-logic code with no QObject dependency | Protocol serialization, crypto wrapper correctness (known-answer tests against libsodium test vectors), transport framing, capture/encode adapters (mocked backends) |
| QML | **Qt Quick Test** (`qmltestrunner`, `TestCase`/`SignalSpy` types) | Every reusable `components/` item and view-model binding — verify property bindings, signal emission, and that `Palette`/`Typography`/`Metrics` tokens are actually consumed (no hardcoded literals regression) |
| Rust services | Built-in `#[cfg(test)]` + `cargo test`, `mockall` for trait mocking | Handler logic, auth middleware, protocol codec round-trips, business rules — run against fakes/mocks, no real network/DB |

### 6.2 Integration tests

| Scope | Approach |
|---|---|
| Agent capture→encode→transport pipeline | Run against a real (virtual) display: `Xvfb` on Linux CI runners, equivalent virtual-display harnesses on Windows/macOS runners — validates the real GStreamer pipeline, not mocks |
| Rust services ↔ Postgres/Redis | `testcontainers-rs` spins up real Postgres/Redis in CI per test run — no mocked DB in integration tier |
| Client ↔ Agent protocol handshake | Loopback test: real client binary + real agent binary on localhost, full crypto handshake, asserts session key agreement and rejects tampered handshakes |
| Cross-service flows | `e2e/scenarios/` — e.g., signaling → NAT traversal attempt → relay fallback → session teardown, run as a docker-compose stack in CI |

### 6.3 UI automation — 100% free/open-source toolchain (no Squish, no paid tools)

Everything in this stack is FOSS. Two layers, both free:

**Layer 1 — in-process scripted interaction (fast, cheap, every commit):**
- **Qt Quick Test / `qmltestrunner`** (part of Qt itself, same license as Qt) driving real rendered scenes with `TestCase.mouseClick()`, `keyClick()`, `SignalSpy` — covers component-level and single-screen interaction without needing a second tool. This is already in the stack from §6.1; extend it to script full user flows (login → connect → accept/reject) inside a running `ApplicationWindow`, not just isolated components.
- Runs in every CI job, on all three OS runners, because it's free and fast — no licensing-driven "only run nightly" compromise needed.

**Layer 2 — black-box, OS-level UI automation (full app, cross-process, closer to what a real user does):**

Rather than a single commercial tool, use the **OS accessibility tree** as the
automation interface — genuinely free on every platform, and it has a second
payoff: it's the same tree WCAG 2.1 AA screen-reader support depends on
(§10), so building it out serves both testing and accessibility compliance
at once.

| Platform | Tool | License | Notes |
|---|---|---|---|
| Linux | **dogtail** (Python, drives apps via AT-SPI2) | GPLv2/LGPL, FOSS | Qt apps expose AT-SPI automatically via `QAccessible` when built with accessibility support enabled |
| Windows | **pywinauto** (drives apps via UI Automation/MSAA) | BSD, FOSS | Same `QAccessible` bridge exposes the tree via MSAA/UIA on Windows |
| macOS | **atomac / ATOMac** (drives apps via NSAccessibility) | FOSS | `QAccessible` bridges to NSAccessibility on macOS |
| Cross-platform orchestration alternative | **Appium** (Apache-2.0) + `WinAppDriver` (MIT, Microsoft, Windows) + Appium's Mac2Driver (Apache-2.0) | All FOSS | One test-writing API across OSes if the team prefers a single framework over three OS-native tools; Linux support in Appium is less mature, so pair it with dogtail on Linux if going this route |

**Precondition (already required by §10 anyway):** every interactive QML
element must have `Accessible.role`, `Accessible.name`, and
`Accessible.description` set. This is a hard requirement for both WCAG and
for the accessibility-tree automation approach to work reliably — track it
as a `qmllint`-style checklist item alongside the theme-token rules.

**Orchestration/reporting layer:** **Robot Framework** (Apache-2.0, FOSS) as
the top-level runner — it has ready-made libraries for Appium
(`robotframework-appiumlibrary`) and can also shell out to `dogtail`/
`pywinauto` scripts, giving one unified, human-readable test report across
C++ unit tests (via CTest), QML tests (`qmltestrunner`, wrapped in CTest),
Rust tests, and UI automation — all free, all CI-native.

UI automation suite structure lives in `apps/client/tests/ui/`, organized by
user flow (`connect_flow/`, `file_transfer_flow/`, `settings_flow/`), each
flow runnable independently and mapped 1:1 to a Robot Framework suite file.

### 6.4 Free/open-source tooling for the rest of the pyramid

To be explicit that *nothing* in the testing stack requires a paid license:

| Need | FOSS tool |
|---|---|
| C++ unit tests | Qt Test (ships with Qt) or GoogleTest (Apache-2.0) |
| C++ coverage | `gcov`/`lcov` (GPL, GNU toolchain) or `llvm-cov` (Apache-2.0) |
| Rust unit/integration test runner | `cargo test` (built-in) or `cargo nextest` (Apache-2.0/MIT, faster, better CI output) |
| Rust coverage | `cargo llvm-cov` or `cargo tarpaulin` (both FOSS) |
| Rust integration DB/infra | `testcontainers-rs` (Apache-2.0/MIT) |
| Fuzzing | `libFuzzer` (part of LLVM) / `cargo fuzz`, `AFL++` (Apache-2.0) |
| Load/perf testing (relay throughput) | `k6` (AGPL core/Apache extensions) or `locust` (MIT) |
| SAST | `clang-tidy`/`cppcheck` (both FOSS), `clippy` (built into Rust) |
| SCA / dependency licenses | `cargo deny`/`cargo audit` (FOSS), `OWASP Dependency-Check` (Apache-2.0) |
| CI | GitHub Actions (free tier covers this comfortably for a project this size) or self-hosted GitLab CI (FOSS) |

No commercial testing tool is required anywhere in this plan.

### 6.5 Test pyramid target ratio (guideline)

Roughly **70% unit / 20% integration / 10% UI automation** by test count —
UI automation is the most valuable for catching real regressions but the
slowest and most brittle, so it covers critical user journeys, not every
possible interaction.

### 6.6 CI enforcement

- Every PR: unit tests (all languages) + linting + static analysis, on the **full Windows/Linux/macOS matrix** for client/agent code. `qmltestrunner` scripted flow tests also run every PR since they're free and fast.
- Nightly: integration tests + Layer 2 accessibility-tree UI automation suite (dogtail/pywinauto/atomac or Appium) + fuzzing corpus run (see §9.3).
- Pre-release: full e2e scenario suite across the OS matrix, plus manual exploratory pass.
- Coverage reports published per PR; drops below the §4.4 thresholds block merge on the high-risk modules (`libs/security`, `libs/protocol`, `libs/transport`, identity/relay/signaling crates).

---

## 7. QML Hot Reload — Built In From Day One (Developer Experience)

Goal: change a `.qml` file, save it, and see the running app update in place
— without a full C++ rebuild/relink and without losing application state.
This is a debugging force-multiplier for a UI-heavy client and should exist
before the second screen is built, not retrofitted once the QML tree is
large.

### 7.1 Why this works cleanly in this architecture

The **"no business logic in QML"** rule (§4.2, rule 4) is what makes hot
reload safe here: application state (session state, connection state,
device lists) lives entirely in C++ view-models, which are **not**
destroyed on reload. Only the presentation layer — the QML tree itself — is
torn down and re-instantiated. If business logic ever leaked into QML
properties, a reload would silently reset it; keeping it out is a
prerequisite for reliable hot reload, not just a style preference.

### 7.2 Mechanism (self-built, FOSS, no external tool dependency)

```
apps/client/src/devtools/
├── HotReloadManager.h
└── HotReloadManager.cpp        # Compiled ONLY when ENABLE_HOT_RELOAD=ON
```

- `HotReloadManager` wraps a `QFileSystemWatcher` recursively registered on
  `apps/client/qml/` (walk the tree at startup and add every subdirectory,
  since `QFileSystemWatcher` doesn't recurse automatically).
- On a `fileChanged`/`directoryChanged` signal, **debounce** with a short
  single-shot `QTimer` (~150 ms) to coalesce editor-triggered multi-write
  saves into one reload.
- On the debounced trigger: call `QQmlApplicationEngine::clearComponentCache()`
  then re-create the root object from the current view's QML entry point,
  swapping it into the existing window rather than spawning a new one, so
  window position/size is preserved.
- On a QML syntax error during reload, **keep the previous working UI on
  screen** and print the error to the centralized logger (§8) rather than
  crashing or showing a blank window — a broken save shouldn't lose your
  place.

### 7.3 Build/ship boundary (security + hygiene)

- Gated by a **CMake option**, `ENABLE_HOT_RELOAD`, default **OFF**.
  Developer/Debug presets turn it **ON**; Release/packaging presets leave it
  **OFF** — the file-watching code is not merely disabled at runtime, it is
  **not compiled into shipped binaries at all**. A live file-watcher and
  component-cache-clearing code path has no place in a security product's
  production binary.
- CI verifies this: the Release build artifact is scanned to confirm no
  `HotReloadManager` symbols are present.

### 7.4 Complementary option — Qt Creator's built-in QML Preview

For day-to-day local editing (as opposed to running the full packaged app),
**Qt Creator's built-in "QML Preview" (`qmlpreview`)** is free (Qt Creator
itself is open source under GPLv3-with-exceptions/LGPL depending on
component) and requires zero project code — point it at a `.qml` file and it
live-updates as you type, including on a connected Android/embedded device
target via the same QML debug connection. Use this for rapid single-screen
iteration; use the in-app `HotReloadManager` (§7.2) for testing hot reload
against real C++ view-model state inside the actual running application —
the two are complementary, not competing.

### 7.5 Roadmap note — embedded/Yocto target preview

Once the embedded/Yocto agent milestone (M16) is underway, if a local
on-device UI is ever added (§11.1 already recommends keeping the embedded
agent Qt-free, but if that changes), the same `HotReloadManager` pattern can
be extended to watch for QML pushed over a network debug connection rather
than a local filesystem, mirroring how Qt Creator's device preview works —
not required for the desktop-only MVP, noted here so the pattern isn't
redesigned later.

---

## 8. Centralized Logging Architecture

One logging system, one place to configure it, easy to turn categories or
whole subsystems on/off — without rebuilding, and (for most cases) without
restarting. This is a `libs/common/logging/` module shared by every C++
target (`apps/client`, `apps/agent`, all of `libs/`), plus an equivalent
convention on the Rust side, so a support engineer or developer has exactly
one mental model for "how do I get more/less logging" regardless of which
part of the stack they're looking at.

### 8.1 Two separate concerns — do not conflate them

| | Diagnostic/Debug Logging (this section) | Audit Logging (§7.3 of the security section) |
|---|---|---|
| Purpose | Development/support troubleshooting | Compliance, security accountability |
| Volume | High, verbose, freely toggled | Low, deliberate, every event matters |
| Mutability | Fully toggle-able, can be off by default | Tamper-evident, never silently disabled |
| Content | Anything non-sensitive: state transitions, timings, protocol frame types | Connection attempts, auth events, file transfers, permission changes |
| Storage | Local rotating file / console / optional shipping to a log aggregator | Append-only store, separate from general logs |

These stay architecturally separate — the audit trail must never be
affected by a developer flipping a debug logging category on or off.

### 8.2 C++ side — centralize on `QLoggingCategory`

Don't invent a custom logging macro set; Qt already provides the right
primitive (`QLoggingCategory`) and it's the standard used across the Qt
ecosystem, so lean into it rather than around it:

```
libs/common/logging/
├── LogCategories.h      # One Q_DECLARE_LOGGING_CATEGORY per subsystem
├── LogCategories.cpp    # One Q_LOGGING_CATEGORY definition per subsystem
├── LogSink.h/.cpp        # Custom qInstallMessageHandler — single point that
│                         # decides destination(s): console, rotating file,
│                         # structured JSON, optional remote shipping
└── LoggingConfig.h/.cpp  # Runtime enable/disable API (see 8.4)
```

- Define one category per subsystem, matching the repo layout, e.g.
  `rap.transport`, `rap.capture`, `rap.encode`, `rap.security`,
  `rap.input`, `rap.clipboard`, `rap.ui` — each subsystem's code uses only
  its own category (`qCDebug(rapCapture) << ...`), never the generic
  default category, so filtering is meaningful.
- **A single `qInstallMessageHandler` in `LogSink.cpp`** is the only place
  that decides where log lines actually go. Every `qDebug`/`qCInfo`/etc.
  call anywhere in the codebase funnels through it — this is what makes
  "centralized" real rather than aspirational: no module opens its own log
  file or writes to `stdout` directly.
- Log line format is **structured (JSON lines)** in file/remote output —
  `{"ts": "...", "level": "debug", "category": "rap.transport", "session_id": "...", "msg": "...", ...extra fields}`
  — so it's directly ingestible by a log aggregator later without a
  reformatting step.
- `qCDebug` calls are **effectively free at runtime when a category is
  disabled** — Qt's logging macros short-circuit before evaluating
  arguments, so leaving verbose `qCDebug` calls scattered through hot paths
  doesn't cost meaningful performance when off. This means categories can be
  liberally added without a "but it'll slow things down" trade-off.
- The agent is headless (no `QGuiApplication`) but `QLoggingCategory` only
  needs `QtCore`, so the exact same mechanism applies there unchanged.

### 8.3 Rust side — `tracing`, same schema

- Use the **`tracing`** crate (Apache-2.0/MIT, FOSS) with `tracing-subscriber`
  across every `services/*` crate — it's the de facto standard for
  structured, level-and-target-filterable logging in the Rust ecosystem, the
  direct equivalent of `QLoggingCategory` categories via its `target`
  field.
- Configure the JSON output formatter to emit the **same field schema** as
  the C++ side (`ts`, `level`, `category`/`target`, `session_id`, `msg`,
  plus structured extra fields) so logs from the Rust backend and the C++
  client/agent can be correlated in one aggregator view by `session_id`
  without a translation layer.
- Filtering is via `tracing-subscriber`'s `EnvFilter`, driven by config file
  or `RUST_LOG`-style syntax (e.g. `identity=debug,relay=warn`), mirroring
  the per-category on/off model on the C++ side.

### 8.4 Runtime enable/disable — without a rebuild, mostly without a restart

- **Compile-time floor:** in Release builds, the lowest-severity categories
  (`qCDebug`-level) default to **off**, keeping shipped binaries quiet by
  default — this is a `QLoggingCategory` default filter rule baked into
  `LoggingConfig`, not something requiring a recompile to change.
- **Config-file/env-var control:** `LoggingConfig` reads a small
  `logging.ini`/env var (`QT_LOGGING_RULES` convention, or a project-owned
  equivalent) at startup to set the initial filter rules — the same pattern
  `EnvFilter`/`RUST_LOG` uses on the Rust side, kept consistent so the same
  mental model ("turn `transport` up to debug") applies on both sides of
  the stack.
- **Live runtime toggling (no restart):** `LoggingConfig` also watches its
  config file with the same debounced-`QFileSystemWatcher` pattern used for
  hot reload (§7.2) and calls `QLoggingCategory::setFilterRules()` again on
  change — so a support engineer troubleshooting a live session can raise
  `rap.transport` to debug, capture what's needed, and drop it back down,
  without restarting the app or losing the session.
- **Product-facing hook (optional, low effort given the above):** a
  "Collect diagnostics" action in the client settings UI can temporarily
  raise all categories to debug, capture N minutes of structured logs to a
  local file, then automatically revert — useful for support workflows
  without requiring a persistent "verbose mode" toggle nobody remembers to
  turn back off.

### 8.5 Log aggregation (optional infra, FOSS-only, consistent with §6.4)

If/when centralizing logs across the fleet of running agents and backend
services becomes useful (beyond local files), use a FOSS aggregation stack
rather than a paid SaaS: **Grafana Loki + Promtail** (Apache-2.0) or
**OpenSearch** (Apache-2.0) both ingest the JSON-lines schema above
directly. Not required for the LAN MVP; noted here so the log schema (§8.2,
§8.3) is chosen to be aggregator-ready from the start rather than needing a
reformat later.

### 8.6 Hard rule — never log secrets or session content

Regardless of category or level: credentials, session encryption keys,
clipboard content, file contents, and captured frame data are **never**
passed to the logging system, debug or otherwise. This is enforced the same
way as the "no raw crypto outside `libs/security`" rule (§4.1) — code
review checklist item, and `libs/security` types deliberately don't
implement a `Debug`/`operator<<` that would make an accidental
`qCDebug(rapSecurity) << sessionKey` even possible.

---
- Pre-release: full e2e scenario suite across the OS matrix, plus manual exploratory pass.
- Coverage reports published per PR; drops below the §4.4 thresholds block merge on the high-risk modules (`libs/security`, `libs/protocol`, `libs/transport`, identity/relay/signaling crates).

---

## 9. Security Architecture & OWASP Alignment

### 7.1 Frameworks to align against

- **OWASP ASVS v4/v5** — control checklist, target **Level 2** minimum platform-wide, **Level 3** for identity/crypto/relay services.
- **OWASP Top 10** — for the API gateway and any admin web UI.
- **OWASP IoT/Embedded Top 10** — for the future Yocto/embedded agent variant.
- **CWE/SANS Top 25** — mapped to clang-tidy/cppcheck/clippy rule sets.
- **NIST SSDF (SP 800-218)** — useful structure if pursuing US government/enterprise buyers later.

### 7.2 Threat modeling

- STRIDE-based threat model in `docs/security/threat-model.md`, written **before** the protocol spec and updated with every new channel.
- Explicit attacker classes: malicious relay operator, on-path network attacker, compromised viewer, compromised agent host, credential-stuffing against identity service.

### 7.3 Core security controls

| Concern | Control |
|---|---|
| Session confidentiality | End-to-end encryption; session keys never touch backend (X25519 ECDH + XChaCha20-Poly1305 AEAD) |
| Device identity | Ed25519 keypair generated on-device at first run; private key never leaves device (OS keystore/TPM/Secure Enclave-backed where available) |
| Session auth | Mutual auth — device cert **and** user credential/MFA before session key derivation |
| Replay protection | Monotonic sequence numbers + nonce per packet, reject on replay window violation |
| Transport | TLS 1.3 minimum control plane; QUIC (mandates TLS 1.3) data plane |
| Unattended access | Explicit opt-in, revocable, logged, ideally 2FA-gated to enable |
| Interactive access | Default accept/reject prompt on host — never silent |
| Input validation | All protocol messages schema-validated (protobuf) before reaching business logic |
| Privilege separation | Agent capture/encode run least-privilege; a minimal privileged helper handles uinput/driver-level ops over local IPC |
| Secrets management | No secrets in repo; Vault/cloud KMS in production, `.env` + pre-commit `git-secrets` hook in dev |
| Dependency hygiene (SCA) | `cargo audit`/`cargo deny`, OWASP Dependency-Check for C++/CMake deps, on every build |
| Fuzzing | libFuzzer/AFL++ on `libs/protocol` parser and `libs/transport` framing — highest ROI, parses untrusted network input |
| Audit logging | Structured, tamper-evident log of connection attempts, auth events, file transfers, permission changes — never session content or credentials |
| Update mechanism | Signed releases, auto-update over TLS with signature verification before install, on all three platforms |

### 7.4 Secure SDLC process

1. Threat model updated per feature.
2. Security-relevant PRs require a second reviewer with security context.
3. SAST + SCA on every PR, merge-blocking above defined severity.
4. Fuzzing corpus run nightly against protocol/transport parsers.
5. Annual third-party penetration test once handling real customer sessions.
6. Public `SECURITY.md` with coordinated disclosure process and PGP contact.

---

## 10. Certifications & Industry Standards to Plan For

| Standard | Relevance | When to pursue |
|---|---|---|
| **SOC 2 Type II** | Baseline B2B SaaS trust signal, covers control plane | Once you have paying customers and stable ops |
| **ISO/IEC 27001** | International complement to SOC 2 | Same timing |
| **GDPR / CCPA** | Device/user metadata, session logs, IPs are personal data | From day one for data-handling design |
| **FIPS 140-2/3 validated crypto module** | Required by US gov/regulated buyers | Only if targeting gov/defense/healthcare; keep crypto backend swappable behind `libs/security` |
| **IEC 62443** | Industrial control systems security | If pursuing the embedded/industrial agent variant |
| **Common Criteria (ISO 15408)** | High-assurance government procurement | Expensive, plan late |
| **WCAG 2.1 AA** | Accessibility, increasingly required in procurement | Build into Qt/QML UI from the start (keyboard nav, contrast, screen-reader labels via `Accessible.*` attached properties) — cheap now, expensive to retrofit |

Design decisions already made that support these later: never-decrypts relay
(GDPR data-minimization, SOC 2 confidentiality), swappable crypto backend
(future FIPS module swap without touching application code), structured
audit logging (SOC 2 monitoring, IEC 62443 accountability).

---

## 11. Licensing Strategy — Staying on LGPLv3 Qt (No Commercial License)

Decision: **Qt 6 under LGPLv3, dynamically linked, no commercial Qt
license.** This is entirely workable for a proprietary commercial product —
it's exactly what many closed-source commercial Qt apps do — but it comes
with concrete obligations that must be designed in, not discovered at
release time.

### 9.1 What LGPLv3 actually requires of you

1. **Dynamic linking only.** Qt libraries (`Qt6Core`, `Qt6Quick`, etc.) must
   ship as separate shared libraries (`.so`/`.dll`/`.dylib`) next to or
   findable by your executable — **never statically linked into a single
   binary.** This is a hard CMake/build-system rule: `BUILD_SHARED_LIBS` for
   any Qt-dependent target, verified in CI by checking the shared-library
   dependency list of the built binary on all three platforms.
2. **The end user must be able to replace/relink Qt with a modified
   version** and run your app against it. Practically this means: don't
   obfuscate/pack the Qt shared libraries in a way that prevents swapping
   them (e.g., avoid aggressive binary packers on the Qt `.dll`/`.so` files
   themselves), and don't statically bake Qt symbols into your app via LTO
   across the Qt boundary.
3. **Don't modify Qt source itself.** If you ever need to patch Qt, that
   patch becomes a derivative work of an LGPL library and must itself be
   released under LGPL — avoid this entirely by staying on unmodified
   upstream Qt (build from the official Qt open-source installer or
   unmodified source tarball, tracked by version in CI).
4. **Provide the license text and attribution.** Ship the LGPLv3 text, a
   notice of which Qt modules and version are used, and a link/reference to
   the Qt source (Qt's own source is already public, so this is just a
   notice, not a re-hosting obligation) — typically an "About" or
   "Licenses" screen in the client, and an entry in
   `THIRD_PARTY_LICENSES.md`.
5. **§4 "Installation Information" clause (the practical trap for
   commercial products):** LGPLv3 incorporates GPLv3 §4-style obligations —
   if your software runs on a **locked-down "User Product"** (a
   consumer/embedded device with secure boot or signing that prevents the
   user from installing a modified library), you may be required to provide
   the keys/information needed to install a modified Qt on that device.
   This is the clause most likely to conflict with a commercial embedded
   deployment.
   - **Mitigation already built into this architecture:** the Qt/QML
     dependency is confined to the **desktop viewer/client app**, which
     runs on general-purpose, unlocked Windows/Linux/macOS machines — LGPLv3
     relinking is trivially satisfiable there (the user can already replace
     any `.dll`/`.so` on their own PC).
   - The **agent** (including the future embedded/Yocto variant) is
     intentionally Qt-free — it's a headless capture/encode/input service
     with no GUI requirement, built purely on GStreamer/native OS APIs. This
     sidesteps the §4 "User Product" problem entirely for any locked-down
     hardware you ship the agent on, since Qt/LGPL obligations never apply
     to a device that doesn't contain Qt.
   - **Action item:** if a future requirement introduces a local on-device
     UI on locked embedded hardware (e.g., a touchscreen prompt on an
     industrial HMI), treat that as a trigger to re-evaluate — either keep
     that local UI Qt-free (a minimal native/LVGL-based prompt) or budget
     for a commercial Qt license specifically for that SKU, rather than
     letting Qt/QML creep into locked-down embedded products under LGPL.

### 9.2 Qt module license audit — not every Qt module is LGPL

This is the most common mistake teams make: assuming "Qt is LGPL" covers
every module. Some Qt add-ons are **GPLv3-or-commercial only**, not
available under LGPL at all. Audit every module before adding an `import` or
`find_package`:

| Module | License availability | Use in this project |
|---|---|---|
| Qt Core, Qt Gui, Qt Widgets, Qt Quick/QML, Qt Network, Qt Concurrent | LGPLv3 | ✅ Safe — core of the client |
| Qt Quick Controls 2, Qt Quick Layouts | LGPLv3 | ✅ Safe |
| Qt Multimedia | LGPLv3 | ✅ Safe if needed for audio |
| Qt Charts | **GPLv3 or commercial only — NOT available under LGPL** | ⚠️ Avoid; if you need connection-quality/bandwidth graphs in the UI, hand-roll them with `QPainter`/Qt Quick `Shapes`/Canvas, or use an MIT/Apache charting library instead |
| Qt Data Visualization | **GPLv3 or commercial only** | ⚠️ Avoid for the same reason |
| Qt Virtual Keyboard | **GPLv3 or commercial only** | ⚠️ Avoid; rely on OS-native virtual keyboards on touch platforms |
| Qt WebEngine | LGPLv3 (with Chromium's own licenses bundled) | Only if embedding web content is ever needed — adds significant binary size and its own patch-tracking burden; avoid unless there's a clear requirement |
| Qt for MCUs / Qt Quick Ultralite | **Commercial only** | ❌ Not usable under this plan — irrelevant anyway since the embedded target is Yocto Embedded Linux, not bare-metal MCU, so plain Qt6 LGPL (if a local UI were ever needed) or the Qt-free agent design (§11.1) applies instead |

**Process:** every new Qt module added to `CMakeLists.txt` requires a
one-line note in `THIRD_PARTY_LICENSES.md` confirming its license tier,
checked in code review — treat this the same as the Rust/C++ dependency
license gate (§11.3), just without an automated tool, since no mature
open-source CMake/Qt license-scanner exists — this is a manual review gate
until/unless the team decides to script one via Qt's own module license
metadata.

### 9.3 General dependency licensing

- **Product license:** proprietary/commercial EULA. AGPL/GPL code (RustDesk, Sunshine) is studied for architecture only, never copied.
- **Dependency policy:** prefer MIT/Apache-2.0/BSD; avoid AGPL entirely anywhere network-accessible (its network-use clause is the one most likely to force backend source disclosure).
- **Automated license tracking:** `cargo deny check licenses` (Rust, FOSS), a C++ dependency manifest cross-checked in CI (via `vcpkg`/`Conan` metadata + a license-checker script, both FOSS) — output feeds `THIRD_PARTY_LICENSES.md`, generated in CI, never hand-maintained. The Qt module tier table above (§11.2) is reviewed manually alongside this since it isn't automatable the same way.
- **Codec patents:** H.264/H.265 may require MPEG-LA/Access Advance licensing depending on jurisdiction/use case — budget before commercial launch, or prefer AV1/VP9 where hardware support allows (also avoids adding a proprietary codec license question on top of the Qt/LGPL question).

---

## 12. Milestones (Phase 1 → Production)

1. **M1 — Repo, CI, and testing skeleton**: monorepo structure (§3), clang-format/tidy, qmllint/qmlformat, rustfmt/clippy, **CI matrix across Windows/Linux/macOS**, `qmltestrunner`/Qt Test/`cargo test` harnesses wired up with one trivial passing test each — proves the testing pipeline before any feature code exists. `SECURITY.md`/`CODING_STANDARDS.md`/`docs/testing-strategy.md` committed.
2. **M2 — Theme/token system + centralized logging + hot reload**: `theme/Tokens.qml`, `Palette.qml`, `Typography.qml`, `Metrics.qml` singletons built and unit-tested (§5); `libs/common/logging/` (`QLoggingCategory` setup, message handler, `LoggingConfig`) built and wired into every target (§8); `HotReloadManager` behind `ENABLE_HOT_RELOAD` (§7) working against a placeholder screen — all three land **before** the first real feature screen is built, so every subsequent screen is developed with fast iteration, consistent tokens, and visible logging from its first commit.
3. **M3 — Protocol v0**: `libs/protocol` schema (protobuf) for HELLO/AUTH/FRAME/INPUT/PING, versioned, fuzz harness stub, unit tests for serialization round-trips.
4. **M4 — LAN MVP, cross-platform capture**: Linux agent (X11) ↔ Qt viewer over plain TCP first; Windows (DXGI) and macOS (ScreenCaptureKit) capture backends added behind the same `ICaptureBackend` interface before moving on — prove cross-platform early, not last.
5. **M5 — Security layer**: `libs/security` crypto wrapper, device identity generation, TLS/QUIC transport, mutual auth handshake — retrofit into M4 pipeline, with unit tests against known-answer crypto test vectors.
6. **M6 — Input + clipboard channels**: platform input backends, bidirectional clipboard, multiplexed QUIC streams; integration tests via virtual display.
7. **M7 — Threat model + first fuzzing pass** before any network exposure beyond LAN.
8. **M8 — Identity & signaling services** (Rust): device registration, presence, session tokens; unit + integration tests against real Postgres/Redis via testcontainers.
9. **M9 — NAT traversal**: STUN integration, direct P2P establishment; e2e scenario test added to `e2e/scenarios/`.
10. **M10 — Relay service** (Rust, stateless, never decrypts): fallback path; load-tested for throughput.
11. **M11 — Adaptive performance**: dirty-region detection, adaptive bitrate/FPS, hardware encoder selection per platform.
12. **M12 — First UI automation pass**: Layer 2 accessibility-tree automation (dogtail/pywinauto/atomac, orchestrated by Robot Framework) covering connect/accept/reject/disconnect flows across the OS matrix (§6.3) — introduced once core flows are stable, not deferred to pre-launch. This also forces `Accessible.*` properties onto every relevant control, satisfying WCAG progress at the same time.
13. **M13 — File transfer channel**, separate from video/input streams.
14. **M14 — Audit logging + admin API/web UI** (Rust, `axum`), RBAC groundwork — note this is the tamper-evident audit trail (§8.1), architecturally distinct from and in addition to the diagnostic logging already live since M2.
15. **M15 — Hardening pass**: SAST/SCA clean, fuzzing corpus mature, external pentest scheduled, full cross-platform e2e suite green, `THIRD_PARTY_LICENSES.md` finalized, WCAG pass on client UI.
16. **M16 — Embedded/Yocto agent variant**: DRM/KMS capture, V4L2 hardware encode, minimal-footprint build — differentiator vs. AnyDesk/RustDesk.

---

## 13. Immediate Next Actions

1. Stand up the empty monorepo with `.clang-format`, `.clang-tidy`, `qmllint`/`qmlformat` config, `rustfmt.toml`/`clippy.toml`, and a **3-OS CI matrix** running trivial passing tests in all three test frameworks (Qt Test, Qt Quick Test, `cargo test`) — validate the whole pipeline before writing feature code.
2. Build the `theme/` singleton module (§5) with a handful of tokens and a unit test asserting no other QML file in the (currently empty) tree contains a hex color literal — this becomes a permanent CI check, not a one-time cleanup.
3. Build `libs/common/logging/` (§8) and route every existing `qDebug`/`qWarning` call through the single `qInstallMessageHandler` sink from the first commit — retrofitting a centralized log sink onto an already-scattered set of ad-hoc log calls later is far more painful than starting centralized.
4. Wire up `HotReloadManager` behind `ENABLE_HOT_RELOAD` (§7) against a trivial placeholder screen, and confirm in CI that the Release build artifact contains no hot-reload symbols — prove the on/off boundary works before real screens depend on it.
5. Write the protocol v0 `.proto` schema — get review on it before implementation, since it's the contract everything else depends on.
6. Draft the STRIDE threat model for LAN MVP scope before M5.
7. Set up the CMake rule enforcing dynamic linking for every Qt-dependent target, and add the shared-library dependency check to CI (§11.1) so a static-link regression is caught immediately, not at release audit time.
8. Add the Qt module license tier table (§11.2) to code review checklist templates so a `Qt Charts`-class mistake can't slip into a PR unnoticed.
