#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

while true; do
  if /usr/bin/bash "$SCRIPT_DIR/run_all.sh"; then
    exit 0
  fi
  log "orchestrator failed; preserving checkpoints and retrying in 15 minutes"
  sleep 900
done
