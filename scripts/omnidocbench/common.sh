#!/usr/bin/env bash
set -euo pipefail

LAB_ROOT="${OMNIDOC_LAB_ROOT:-$HOME/ai395/omnidocbench-test-lab}"
SOURCE_ROOT="$LAB_ROOT/sources"
DATA_ROOT="$LAB_ROOT/dataset"
PREDICTION_ROOT="$LAB_ROOT/artifacts/predictions"
RESULT_ROOT="$LAB_ROOT/artifacts/results"
STATE_ROOT="$LAB_ROOT/state"
LOG_ROOT="$LAB_ROOT/logs"

AIWORK_REPOSITORY="https://github.com/AIwork4me/MinerU-ROCm.git"
AIWORK_COMMIT="1585e1ec08e5d37bbad068f392cbf9864f016118"
OMNIDOC_REPOSITORY="https://github.com/opendatalab/OmniDocBench.git"
OMNIDOC_V16_COMMIT="2b161d010d2e3aff77a0edef359ea3a6411d23cd"
OMNIDOC_V17_COMMIT="193627ae9e97d89188468ed1ee3b7a856ff76044"
DATASET_REPOSITORY="opendatalab/OmniDocBench"
DATASET_REVISION="aa1ee96d106dbe53d0ae59474d75c6e6d9b53fec"
GT_SHA256="a45cd84b04ad8b793e775089640e6b681209abea33ead54c1828ddca35fae496"
EXPECTED_PAGES=1651

SCORER_IMAGE="ghcr.io/zeng-weijun/omnidocbench-eval@sha256:6116ad72172e763b5c43e963d5efebf2093f2362b975f58156ce4f6c9142e617"
CLIENT_PYTHON="${MINERU_CLIENT_PYTHON:-$HOME/ai395/mineru/venv-3.4.4-rocm714-py312/bin/python}"
VLLM_LAUNCHER="${MINERU_VLLM_LAUNCHER:-$HOME/ai395/mineru/run-vllm-0.21.0-local.sh}"
VLLM_URL="${MINERU_VLLM_URL:-http://127.0.0.1:18080/v1}"
VLLM_MODEL_NAME="${MINERU_VLLM_MODEL_NAME:-mineru-vlm-1.2b}"

mkdir -p "$SOURCE_ROOT" "$DATA_ROOT" "$PREDICTION_ROOT" "$RESULT_ROOT" "$STATE_ROOT" "$LOG_ROOT"

timestamp() {
  date --iso-8601=seconds
}

log() {
  printf '[%s] %s\n' "$(timestamp)" "$*"
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'required command not found: %s\n' "$1" >&2
    exit 1
  }
}
