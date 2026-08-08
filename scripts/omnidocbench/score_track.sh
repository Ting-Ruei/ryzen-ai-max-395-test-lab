#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

track="${1:?usage: score_track.sh v16|v17}"
case "$track" in
  v16)
    scorer_root="$SOURCE_ROOT/omnidocbench-v16"
    scorer_commit="$OMNIDOC_V16_COMMIT"
    ;;
  v17)
    scorer_root="$SOURCE_ROOT/omnidocbench-v17"
    scorer_commit="$OMNIDOC_V17_COMMIT"
    ;;
  *)
    printf 'unknown track: %s\n' "$track" >&2
    exit 2
    ;;
esac

test "$(git -C "$scorer_root" rev-parse HEAD)" = "$scorer_commit"
test -f "$STATE_ROOT/inference-complete.json"
mkdir -p "$RESULT_ROOT/$track"

log "starting OmniDocBench $track scoring at $scorer_commit"
docker run --rm --network none \
  --user "$(id -u):$(id -g)" \
  --shm-size 2g \
  -e HOME=/tmp/omnidoc-home \
  -e PYTHONPATH=/workspace/OmniDocBench \
  -v "$scorer_root:/workspace/OmniDocBench" \
  -v "$DATA_ROOT:/workspace/dataset:ro" \
  -v "$PREDICTION_ROOT:/workspace/predictions:ro" \
  -v "$SCRIPT_DIR/scorer-config.yaml:/workspace/scorer-config.yaml:ro" \
  -w /workspace/OmniDocBench \
  --entrypoint bash \
  "$SCORER_IMAGE" \
  -lc 'python pdf_validation.py --config /workspace/scorer-config.yaml'

"$CLIENT_PYTHON" "$SCRIPT_DIR/validate_score.py" \
  --track "$track" \
  --scorer-commit "$scorer_commit" \
  --source-result-dir "$scorer_root/result" \
  --output-dir "$RESULT_ROOT/$track" \
  --expected-pages "$EXPECTED_PAGES"

log "OmniDocBench $track scoring complete"
