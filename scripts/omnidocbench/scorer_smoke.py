#!/usr/bin/env python3
"""Dependency-free smoke test for the pinned OmniDocBench scorer image."""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
import tempfile

from src.metrics.cdm.cdm import cdm
from src.metrics.cdm.modules.texlive_env import (
    build_tex_env,
    resolve_cjk_font_family,
    resolve_tex_binary,
)


def checked_output(command: list[str], *, env: dict | None = None) -> str:
    completed = subprocess.run(
        command,
        check=True,
        capture_output=True,
        text=True,
        timeout=30,
        env=env,
    )
    return (completed.stdout or completed.stderr).splitlines()[0]


def main() -> int:
    if sys.version_info[:2] != (3, 10):
        raise RuntimeError(f"unexpected scorer Python: {sys.version.split()[0]}")

    tex_env = build_tex_env()
    pdflatex = resolve_tex_binary("pdflatex")
    kpsewhich = resolve_tex_binary("kpsewhich")
    magick = shutil.which("magick")
    ghostscript = shutil.which("gs")
    if not magick or not ghostscript:
        raise RuntimeError("ImageMagick or Ghostscript is unavailable")

    cjk_font = resolve_cjk_font_family()
    resources = {
        "CJK.sty": checked_output([kpsewhich, "CJK.sty"], env=tex_env),
        f"c70{cjk_font}.fd": checked_output(
            [kpsewhich, f"c70{cjk_font}.fd"], env=tex_env
        ),
    }
    if not all(resources.values()):
        raise RuntimeError(f"missing CJK resources: {resources}")

    latex = r"\mathrm{傳動側} + \text{效率} = \frac{1}{2}"
    with tempfile.TemporaryDirectory(prefix="omnidoc-cdm-smoke-") as tmp_dir:
        cdm_score = cdm(latex, latex, tmp_dir=tmp_dir)
    if cdm_score < 0.99:
        raise RuntimeError(f"identical-formula CDM score is too low: {cdm_score}")

    report = {
        "status": "passed",
        "python": sys.version.split()[0],
        "pdflatex": checked_output([pdflatex, "--version"], env=tex_env),
        "imagemagick": checked_output([magick, "--version"]),
        "ghostscript": checked_output([ghostscript, "--version"]),
        "cjk_font_family": cjk_font,
        "cjk_resources": resources,
        "identical_formula_cdm": cdm_score,
    }
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
