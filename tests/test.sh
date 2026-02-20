#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

bash -n "$ROOT_DIR/tmux-grip.tmux"
bash -n "$ROOT_DIR/scripts/tmux-grip"
bash "$ROOT_DIR/tests/test_add_full.sh"
bash "$ROOT_DIR/tests/test_stale_prune.sh"

echo "tmux-grip: tests passed"
