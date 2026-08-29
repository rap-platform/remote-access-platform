# Contributing to Remote Access Platform

Thank you for contributing! To maintain enterprise-grade software quality, security, and repository stability, all contributors must adhere to the following branching, committing, and review standards.

---

## 1. Branch Protection & Branch Naming Standards

> 🛑 **IMPORTANT**: Direct pushes to `main` are strictly prohibited via GitHub Branch Protection. All changes must be introduced via a Pull Request (PR).

### Branch Naming Convention

All branches created by developers must follow the structured `<category>/<short-description>` format:

| Category | Description | Example |
|---|---|---|
| `feature/` | New functionality or UI additions | `feature/multi-monitor-selector` |
| `bugfix/` | Fixing a non-critical bug or issue | `bugfix/android-rotation-crash` |
| `hotfix/` | Emergency fix for critical security or production build issues | `hotfix/tls-handshake-timeout` |
| `refactor/` | Code restructuring without feature changes | `refactor/relay-buffer-pool` |
| `docs/` | Documentation additions or updates | `docs/api-gateway-spec` |
| `test/` | Adding or updating unit/integration tests | `test/file-transfer-fuzzing` |

---

## 2. Conventional Commit Messages

Commit messages must follow the **Conventional Commits** standard format:

```
<type>(<scope>): <short descriptive summary in imperative mood>
```

### Allowed Types:
* `feat`: A new feature for the user or system.
* `fix`: A bug fix.
* `docs`: Documentation only changes.
* `refactor`: A code change that neither fixes a bug nor adds a feature.
* `test`: Adding missing tests or correcting existing tests.
* `ci`: Changes to CI build scripts or Docker containers.

### Examples:
```bash
git commit -m "feat(client): add multi-monitor selection dropdown to Qt viewer"
git commit -m "fix(security): resolve ECDH key exchange nonce reuse vulnerability"
git commit -m "docs(roadmap): update sprint 1 backlog items"
```

---

## 3. Pull Request (PR) & Code Review Guidelines

1. **Keep PRs Focused**: Each Pull Request should address a single feature or bug. Avoid mixing unrelated changes.
2. **Self-Review Checklist**:
   - [ ] Code compiles cleanly with zero compiler warnings (`-Werror`).
   - [ ] All C++ unit tests pass (`ctest --test-dir build`).
   - [ ] All Rust unit tests pass (`cargo test --workspace`).
   - [ ] Code formatted with `clang-format` and `cargo fmt`.
3. **PR Approval**:
   - All PRs require **at least 1 code review approval** from a repository maintainer before merging.
   - Merging should use **Squash and Merge** or **Rebase and Merge** to keep the `main` git history clean and linear.

---

## 4. Development Environment & Build Commands

### C++ & Qt6 Desktop Client

```bash
# Configure build tree
cmake -B build -S . -G Ninja -DCMAKE_BUILD_TYPE=Debug -DENABLE_TESTING=ON

# Build all binaries
cmake --build build

# Execute test suite
ctest --test-dir build --output-on-failure
```

### Rust Microservices

```bash
# Build workspace
cargo build --workspace

# Run tests & linters
cargo test --workspace
cargo clippy --workspace --all-targets -- -D warnings
```
