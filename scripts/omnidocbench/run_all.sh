#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

require_command curl
require_command flock

exec 9>"$STATE_ROOT/run-all.lock"
if ! flock -n 9; then
  log "another benchmark orchestrator holds the lock; exiting"
  exit 0
fi

vllm_pid=""
stop_vllm() {
  if [[ -n "$vllm_pid" ]] && kill -0 "$vllm_pid" 2>/dev/null; then
    kill "$vllm_pid" 2>/dev/null || true
    wait "$vllm_pid" 2>/dev/null || true
  fi
}
trap stop_vllm EXIT INT TERM

if [[ ! -f "$STATE_ROOT/bootstrap.json" ]]; then
  "$SCRIPT_DIR/bootstrap.sh"
fi

if [[ ! -f "$STATE_ROOT/inference-complete.json" ]]; then
  if ! curl -fsS "$VLLM_URL/models" >/dev/null 2>&1; then
    log "starting native ROCm vLLM worker"
    "$VLLM_LAUNCHER" >>"$LOG_ROOT/vllm.log" 2>&1 &
    vllm_pid="$!"
  else
    log "reusing healthy localhost vLLM worker"
  fi

  ready=0
  for _ in $(seq 1 120); do
    if curl -fsS "$VLLM_URL/models" >/dev/null 2>&1; then
      ready=1
      break
    fi
    if [[ -n "$vllm_pid" ]] && ! kill -0 "$vllm_pid" 2>/dev/null; then
      printf 'vLLM worker exited during startup\n' >&2
      exit 1
    fi
    sleep 5
  done
  if [[ "$ready" -ne 1 ]]; then
    printf 'vLLM worker did not become ready within 600 seconds\n' >&2
    exit 1
  fi

  log "starting/resuming 1,651-page native ROCm inference"
  "$CLIENT_PYTHON" "$SCRIPT_DIR/run_predictions.py" \
    --gt-json "$DATA_ROOT/OmniDocBench.json" \
    --images-dir "$DATA_ROOT/images" \
    --out-dir "$PREDICTION_ROOT" \
    --adapter-root "$SOURCE_ROOT/mineru-rocm" \
    --server-url "$VLLM_URL" \
    --model-name "$VLLM_MODEL_NAME" \
    --max-retries 3

  "$CLIENT_PYTHON" - "$PREDICTION_ROOT/run_manifest.json" "$STATE_ROOT/inference-complete.json" "$EXPECTED_PAGES" <<'PY'
import json
import os
import sys
from pathlib import Path

source, target, expected = Path(sys.argv[1]), Path(sys.argv[2]), int(sys.argv[3])
payload = json.loads(source.read_text(encoding="utf-8"))
state = payload.get("final_state", {})
if payload.get("status") != "complete" or state.get("complete") != expected:
    raise SystemExit("inference manifest is not complete")
tmp = target.with_suffix(".partial")
tmp.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
os.replace(tmp, target)
PY
  stop_vllm
  vllm_pid=""
fi

if [[ ! -f "$STATE_ROOT/score-v16-complete.json" ]]; then
  "$SCRIPT_DIR/score_track.sh" v16
fi

if [[ ! -f "$STATE_ROOT/score-v17-complete.json" ]]; then
  "$SCRIPT_DIR/score_track.sh" v17
fi

if [[ ! -f "$STATE_ROOT/all-complete.json" ]]; then
  "$CLIENT_PYTHON" "$SCRIPT_DIR/finalize.py" \
    --lab-root "$LAB_ROOT" \
    --expected-pages "$EXPECTED_PAGES"
fi

log "all OmniDocBench tracks complete"
