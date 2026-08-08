#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
import shutil
from pathlib import Path


def atomic_json(path: Path, payload: dict) -> None:
    tmp = path.with_suffix(path.suffix + ".partial")
    tmp.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    os.replace(tmp, path)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--track", required=True)
    parser.add_argument("--scorer-commit", required=True)
    parser.add_argument("--source-result-dir", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--expected-pages", type=int, required=True)
    args = parser.parse_args()

    prefix = "predictions_quick_match"
    summary_path = args.source_result_dir / f"{prefix}_run_summary.json"
    summary = json.loads(summary_path.read_text(encoding="utf-8"))
    metrics = summary["notebook_metric_summary"]["metrics"]
    required = {
        "text_block_Edit_dist": "text_edit_distance",
        "display_formula_CDM": "formula_cdm",
        "table_TEDS": "table_teds",
        "reading_order_Edit_dist": "reading_order_edit_distance",
    }
    normalized = {}
    for source_key, target_key in required.items():
        record = metrics.get(source_key, {})
        value = record.get("raw")
        if not isinstance(value, (int, float)):
            raise SystemExit(f"missing numeric metric: {source_key}")
        denominator = record.get("page_denominator")
        if denominator != args.expected_pages:
            raise SystemExit(f"unexpected denominator for {source_key}: {denominator}")
        normalized[target_key] = value

    normalized["overall"] = (
        (1.0 - normalized["text_edit_distance"]) * 100.0
        + normalized["formula_cdm"] * 100.0
        + normalized["table_teds"] * 100.0
    ) / 3.0

    args.output_dir.mkdir(parents=True, exist_ok=True)
    copied = []
    for source in sorted(args.source_result_dir.glob(f"{prefix}*")):
        if source.is_file():
            target = args.output_dir / source.name
            shutil.copy2(source, target)
            copied.append({
                "name": target.name,
                "bytes": target.stat().st_size,
                "sha256": hashlib.sha256(target.read_bytes()).hexdigest(),
            })

    payload = {
        "schema_version": 1,
        "track": args.track,
        "scorer_commit": args.scorer_commit,
        "completed_at": dt.datetime.now(dt.timezone.utc).astimezone().isoformat(),
        "expected_pages": args.expected_pages,
        "metrics": normalized,
        "artifacts": copied,
    }
    atomic_json(args.output_dir / "track-summary.json", payload)
    atomic_json(args.output_dir.parent.parent.parent / "state" / f"score-{args.track}-complete.json", payload)
    print(json.dumps(payload, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
