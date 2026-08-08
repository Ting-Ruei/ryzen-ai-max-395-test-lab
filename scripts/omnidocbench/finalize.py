#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path


def atomic_json(path: Path, payload: dict) -> None:
    tmp = path.with_suffix(path.suffix + ".partial")
    tmp.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    os.replace(tmp, path)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--lab-root", type=Path, required=True)
    parser.add_argument("--expected-pages", type=int, required=True)
    args = parser.parse_args()

    state = args.lab_root / "state"
    artifacts = args.lab_root / "artifacts"
    predictions = artifacts / "predictions"
    summaries = {
        track: json.loads((state / f"score-{track}-complete.json").read_text(encoding="utf-8"))
        for track in ("v16", "v17")
    }

    prediction_records = []
    for path in sorted(predictions.glob("*.md")):
        content = path.read_bytes()
        prediction_records.append({
            "name": path.name,
            "bytes": len(content),
            "sha256": hashlib.sha256(content).hexdigest(),
        })
    if len(prediction_records) != args.expected_pages:
        raise SystemExit(f"prediction count mismatch: {len(prediction_records)}")

    parity = summaries["v16"]["metrics"] == summaries["v17"]["metrics"]
    payload = {
        "schema_version": 1,
        "completed_at": dt.datetime.now(dt.timezone.utc).astimezone().isoformat(),
        "expected_pages": args.expected_pages,
        "prediction_count": len(prediction_records),
        "prediction_manifest_sha256": hashlib.sha256(
            json.dumps(prediction_records, sort_keys=True, separators=(",", ":")).encode("utf-8")
        ).hexdigest(),
        "tracks": summaries,
        "track_metric_parity": parity,
        "note": "The pinned v1.6 and v1.7 scorer revisions differ only in documentation at benchmark start; parity is checked, not assumed.",
    }
    atomic_json(artifacts / "final-manifest.json", payload)
    atomic_json(state / "all-complete.json", payload)
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
