#!/usr/bin/env python3
"""Crash-resumable OmniDocBench prediction runner using AIwork4me's VLM adapter."""

from __future__ import annotations

import argparse
import datetime as dt
import fcntl
import hashlib
import json
import os
import sys
import time
import traceback
from pathlib import Path


def atomic_bytes(path: Path, content: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    partial = path.with_name(path.name + ".partial")
    with partial.open("wb") as handle:
        handle.write(content)
        handle.flush()
        os.fsync(handle.fileno())
    os.replace(partial, path)


def atomic_json(path: Path, payload: dict) -> None:
    atomic_bytes(path, (json.dumps(payload, ensure_ascii=False, indent=2) + "\n").encode("utf-8"))


def now() -> str:
    return dt.datetime.now(dt.timezone.utc).astimezone().isoformat()


def load_marker(marker: Path, prediction: Path) -> bool:
    if not marker.is_file() or not prediction.is_file():
        return False
    try:
        record = json.loads(marker.read_text(encoding="utf-8"))
        content = prediction.read_bytes()
    except (OSError, UnicodeDecodeError, json.JSONDecodeError):
        return False
    return (
        record.get("status") == "complete"
        and record.get("sha256") == hashlib.sha256(content).hexdigest()
        and record.get("bytes") == len(content)
    )


def page_list(gt_json: Path, images_dir: Path) -> list[tuple[str, Path]]:
    pages = json.loads(gt_json.read_text(encoding="utf-8"))
    output = []
    seen = set()
    for page in pages:
        name = Path(page["page_info"]["image_path"]).name
        image = images_dir / name
        stem = image.stem
        if stem in seen:
            raise RuntimeError(f"duplicate prediction stem: {stem}")
        if not image.is_file():
            raise FileNotFoundError(image)
        seen.add(stem)
        output.append((stem, image))
    return output


def snapshot_state(pages: list[tuple[str, Path]], out_dir: Path) -> dict:
    complete = 0
    failed = 0
    for stem, _ in pages:
        if load_marker(out_dir / ".done" / f"{stem}.json", out_dir / f"{stem}.md"):
            complete += 1
        elif (out_dir / ".errors" / f"{stem}.json").is_file():
            failed += 1
    return {
        "expected": len(pages),
        "complete": complete,
        "failed": failed,
        "pending": len(pages) - complete - failed,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--gt-json", type=Path, required=True)
    parser.add_argument("--images-dir", type=Path, required=True)
    parser.add_argument("--out-dir", type=Path, required=True)
    parser.add_argument("--adapter-root", type=Path, required=True)
    parser.add_argument("--server-url", required=True)
    parser.add_argument("--model-name", required=True)
    parser.add_argument("--max-retries", type=int, default=3)
    args = parser.parse_args()

    sys.path.insert(0, str(args.adapter_root / "src"))
    from mineru_rocm.backends import vlm

    pages = page_list(args.gt_json, args.images_dir)
    args.out_dir.mkdir(parents=True, exist_ok=True)
    lock_path = args.out_dir / ".prediction.lock"
    lock_handle = lock_path.open("a+")
    fcntl.flock(lock_handle.fileno(), fcntl.LOCK_EX)

    cfg = {
        "backend": "vlm-vllm",
        "server_url": args.server_url,
        "api_model_name": args.model_name,
    }
    started = time.monotonic()
    attempted = succeeded = failed = skipped = 0

    for index, (stem, image) in enumerate(pages, start=1):
        prediction = args.out_dir / f"{stem}.md"
        marker = args.out_dir / ".done" / f"{stem}.json"
        error_path = args.out_dir / ".errors" / f"{stem}.json"
        if load_marker(marker, prediction):
            skipped += 1
            continue

        attempted += 1
        page_started = time.monotonic()
        for attempt in range(1, args.max_retries + 1):
            try:
                markdown = vlm.infer_page(image, "linux-rocm", cfg)
                if not isinstance(markdown, str):
                    raise TypeError(f"prediction must be str, got {type(markdown).__name__}")
                content = markdown.encode("utf-8")
                atomic_bytes(prediction, content)
                atomic_json(marker, {
                    "status": "complete",
                    "image": image.name,
                    "bytes": len(content),
                    "sha256": hashlib.sha256(content).hexdigest(),
                    "attempt": attempt,
                    "seconds": time.monotonic() - page_started,
                    "completed_at": now(),
                })
                error_path.unlink(missing_ok=True)
                succeeded += 1
                break
            except Exception as exc:
                if attempt < args.max_retries:
                    time.sleep(2 ** attempt)
                    continue
                atomic_json(error_path, {
                    "status": "failed",
                    "image": image.name,
                    "attempts": attempt,
                    "exception_type": type(exc).__name__,
                    "exception_message": str(exc),
                    "traceback": traceback.format_exc(),
                    "failed_at": now(),
                })
                failed += 1

        state = snapshot_state(pages, args.out_dir)
        atomic_json(args.out_dir / "run_manifest.json", {
            "schema_version": 1,
            "backend": "vlm-vllm",
            "model": args.model_name,
            "server_url": args.server_url,
            "updated_at": now(),
            "progress_index": index,
            "run_counts": {
                "attempted": attempted,
                "succeeded": succeeded,
                "failed": failed,
                "skipped": skipped,
            },
            "final_state": state,
            "elapsed_seconds_this_process": time.monotonic() - started,
        })
        print(f"[{index}/{len(pages)}] {image.name}: {state}", flush=True)

    try:
        vlm.finalize_run(cfg)
    except Exception:
        traceback.print_exc()

    state = snapshot_state(pages, args.out_dir)
    atomic_json(args.out_dir / "run_manifest.json", {
        "schema_version": 1,
        "backend": "vlm-vllm",
        "model": args.model_name,
        "server_url": args.server_url,
        "completed_at": now(),
        "run_counts": {
            "attempted": attempted,
            "succeeded": succeeded,
            "failed": failed,
            "skipped": skipped,
        },
        "final_state": state,
        "elapsed_seconds_this_process": time.monotonic() - started,
        "status": "complete" if state["complete"] == state["expected"] else "incomplete",
    })
    return 0 if state["complete"] == state["expected"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
