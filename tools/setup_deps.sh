#!/usr/bin/env bash
# Prerequisites Setup & Dependency Installer Script
set -e

echo "=== Remote Access Platform - Prerequisites & Dependency Setup ==="

OS_TYPE="$(uname -s)"

case "${OS_TYPE}" in
    Linux*)
        echo "[+] Detected Linux system"
        if command -v apt-get &> /dev/null; then
            echo "[+] Updating apt package index..."
            sudo apt-get update -y
            echo "[+] Installing required C++, CMake, Qt6, Static Analysis (cppcheck), and toolchain dependencies..."
            sudo apt-get install -y \
                build-essential \
                cmake \
                ninja-build \
                g++ \
                clang \
                clang-format \
                clang-tidy \
                cppcheck \
                qt6-base-dev \
                qt6-declarative-dev \
                qt6-tools-dev \
                qt6-quick-tests \
                libgl1-mesa-dev \
                libxkbcommon-dev \
                protobuf-compiler
        else
            echo "[!] Package manager not supported automatically. Please install dependencies manually."
        fi
        ;;
    Darwin*)
        echo "[+] Detected macOS system"
        if command -v brew &> /dev/null; then
            echo "[+] Installing dependencies via Homebrew..."
            brew install cmake ninja qt6 llvm cppcheck protobuf
        else
            echo "[!] Homebrew not found. Please install Homebrew or dependencies manually."
        fi
        ;;
    MINGW*|MSYS*|CYGWIN*)
        echo "[+] Detected Windows environment"
        echo "[!] Please ensure MSVC / MinGW, CMake, Ninja, Rust, cppcheck, and Qt6 are installed."
        ;;
    *)
        echo "[!] Unknown operating system: ${OS_TYPE}"
        ;;
esac

# Check Rust Toolchain
if ! command -v rustc &> /dev/null; then
    echo "[+] Installing Rust toolchain via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "[+] Rust toolchain is installed: $(rustc --version)"
fi

echo "[+] Adding rustfmt and clippy components..."
rustup component add rustfmt clippy

echo "=== Prerequisites Setup Complete! ==="
