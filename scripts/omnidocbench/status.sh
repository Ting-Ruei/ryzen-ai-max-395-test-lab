#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

printf 'Lab root: %s\n' "$LAB_ROOT"
for marker in bootstrap inference-complete score-v16-complete score-v17-complete all-complete; do
  if [[ -f "$STATE_ROOT/$marker.json" ]]; then
    printf '%-24s complete\n' "$marker"
  else
    printf '%-24s pending\n' "$marker"
  fi
done

if [[ -f "$PREDICTION_ROOT/run_manifest.json" ]]; then
  "$CLIENT_PYTHON" - "$PREDICTION_ROOT/run_manifest.json" <<'PY'
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
print("prediction state:", payload.get("final_state"))
print("updated:", payload.get("updated_at") or payload.get("completed_at"))
PY
fi

if [[ -f "$RESULT_ROOT/v16/track-summary.json" ]]; then
  "$CLIENT_PYTHON" - "$RESULT_ROOT/v16/track-summary.json" "$RESULT_ROOT/v17/track-summary.json" <<'PY'
import json
import sys
for path in sys.argv[1:]:
    try:
        payload = json.load(open(path, encoding="utf-8"))
    except FileNotFoundError:
        continue
    print(payload["track"], payload["metrics"])
PY
fi

tail -n 20 "$LOG_ROOT/orchestrator.log" 2>/dev/null || true
