#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

require_command docker
require_command git
require_command sha256sum
require_command flock

exec 9>"$STATE_ROOT/bootstrap.lock"
flock 9

clone_at_commit() {
  local repository="$1"
  local destination="$2"
  local commit="$3"

  if [[ ! -d "$destination/.git" ]]; then
    git clone --filter=blob:none --no-checkout "$repository" "$destination"
  fi
  git -C "$destination" fetch --depth=1 origin "$commit"
  git -C "$destination" checkout --detach --force "$commit"
  test "$(git -C "$destination" rev-parse HEAD)" = "$commit"
}

log "pinning AIwork4me adapter"
clone_at_commit "$AIWORK_REPOSITORY" "$SOURCE_ROOT/mineru-rocm" "$AIWORK_COMMIT"

log "pinning OmniDocBench v1.6 compatibility scorer"
clone_at_commit "$OMNIDOC_REPOSITORY" "$SOURCE_ROOT/omnidocbench-v16" "$OMNIDOC_V16_COMMIT"

log "pinning OmniDocBench v1.7 current scorer"
clone_at_commit "$OMNIDOC_REPOSITORY" "$SOURCE_ROOT/omnidocbench-v17" "$OMNIDOC_V17_COMMIT"

if [[ ! -x "$CLIENT_PYTHON" ]]; then
  printf 'MinerU client Python not found: %s\n' "$CLIENT_PYTHON" >&2
  exit 1
fi

log "downloading pinned OmniDocBench dataset snapshot"
export HF_HUB_DISABLE_XET="${HF_HUB_DISABLE_XET:-1}"
export HF_HUB_DOWNLOAD_TIMEOUT="${HF_HUB_DOWNLOAD_TIMEOUT:-300}"
"$CLIENT_PYTHON" - "$DATA_ROOT" "$DATASET_REPOSITORY" "$DATASET_REVISION" <<'PY'
import sys
from huggingface_hub import snapshot_download

destination, repository, revision = sys.argv[1:]
snapshot_download(
    repo_id=repository,
    repo_type="dataset",
    revision=revision,
    local_dir=destination,
    max_workers=2,
)
PY

log "validating dataset identity and image coverage"
"$CLIENT_PYTHON" - "$DATA_ROOT" "$GT_SHA256" "$EXPECTED_PAGES" <<'PY'
import hashlib
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
expected_sha = sys.argv[2]
expected_pages = int(sys.argv[3])
gt_path = root / "OmniDocBench.json"
images = root / "images"

actual_sha = hashlib.sha256(gt_path.read_bytes()).hexdigest()
if actual_sha != expected_sha:
    raise SystemExit(f"GT SHA mismatch: {actual_sha} != {expected_sha}")

pages = json.loads(gt_path.read_text(encoding="utf-8"))
if len(pages) != expected_pages:
    raise SystemExit(f"page count mismatch: {len(pages)} != {expected_pages}")

missing = []
for page in pages:
    name = Path(page["page_info"]["image_path"]).name
    if not (images / name).is_file():
        missing.append(name)
if missing:
    raise SystemExit(f"missing {len(missing)} images; first={missing[:5]}")
print(f"dataset valid: pages={len(pages)} gt_sha256={actual_sha}")
PY

log "pulling official pinned scorer image"
docker pull "$SCORER_IMAGE"
docker image inspect "$SCORER_IMAGE" >/dev/null

log "running official scorer environment and CDM smoke tests"
docker run --rm --network none \
  --user "$(id -u):$(id -g)" \
  --shm-size 2g \
  -e HOME=/tmp/omnidoc-home \
  -e PYTHONPATH=/workspace/OmniDocBench \
  -v "$SOURCE_ROOT/omnidocbench-v17:/workspace/OmniDocBench" \
  -w /workspace/OmniDocBench \
  --entrypoint bash \
  "$SCORER_IMAGE" \
  -lc 'python -m pytest tools/test_environment_and_smoke.py::TestEnvironmentVersions tools/test_environment_and_smoke.py::TestCDMCalculation -q'

"$CLIENT_PYTHON" - "$STATE_ROOT/bootstrap.json" "$SCORER_IMAGE" "$AIWORK_COMMIT" "$OMNIDOC_V16_COMMIT" "$OMNIDOC_V17_COMMIT" "$DATASET_REVISION" "$GT_SHA256" <<'PY'
import datetime
import json
import os
import sys
from pathlib import Path

path = Path(sys.argv[1])
payload = {
    "schema_version": 1,
    "completed_at": datetime.datetime.now(datetime.timezone.utc).astimezone().isoformat(),
    "scorer_image": sys.argv[2],
    "aiwork4me_commit": sys.argv[3],
    "scorer_v16_commit": sys.argv[4],
    "scorer_v17_commit": sys.argv[5],
    "dataset_revision": sys.argv[6],
    "gt_sha256": sys.argv[7],
}
tmp = path.with_suffix(".partial")
tmp.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
os.replace(tmp, path)
PY

log "bootstrap complete"
