#!/usr/bin/env bash
# Single Master Script to Build, Test, Package, Deploy, and Run the Remote Access Platform
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${SCRIPT_DIR}/tools/pipeline.sh" "$@"
