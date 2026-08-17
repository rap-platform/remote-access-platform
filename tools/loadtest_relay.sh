#!/usr/bin/env bash
set -euo pipefail

echo "=== Remote Access Platform — Stateless Relay Load Benchmark ==="
cargo test -p rap-relay --test test_relay_benchmark -- --nocapture
echo "=== Relay High-Throughput Load Benchmark Completed Successfully! ==="
