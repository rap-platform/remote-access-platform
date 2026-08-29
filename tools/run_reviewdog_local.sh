#!/usr/bin/env bash
set -e

# Add ~/.local/bin to PATH if needed
export PATH="$HOME/.local/bin:$PATH"

if ! command -v reviewdog &> /dev/null; then
    echo "❌ reviewdog is not installed. Installing to ~/.local/bin..."
    mkdir -p ~/.local/bin
    curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/master/install.sh | sh -s -- -b ~/.local/bin
fi

BASE_BRANCH="${1:-main}"

echo "🐶 Running Reviewdog locally against base branch '$BASE_BRANCH'..."

# Ensure C++ build compilation DB exists
if [ ! -f build/compile_commands.json ]; then
    echo "⚙️  Generating compile_commands.json..."
    cmake -B build -S . -DCMAKE_BUILD_TYPE=Debug -DENABLE_TESTING=ON -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
fi

echo ""
echo "=== 🔍 C++ clang-tidy Analysis ==="
FILES=$(find apps/ libs/ -name '*.cpp' 2>/dev/null)
clang-tidy -p build $FILES 2>&1 | reviewdog -efm="%f:%l:%c: %t%*[^:]: %m" -diff="git diff $BASE_BRANCH" -reporter=local -name="clang-tidy" || true

echo ""
echo "=== 🦀 Rust Clippy Analysis ==="
cargo clippy -q --message-format=short --workspace --all-targets 2>&1 | reviewdog -f=clippy -diff="git diff $BASE_BRANCH" -reporter=local -name="clippy" || true

echo ""
echo "✅ Local reviewdog run complete!"
