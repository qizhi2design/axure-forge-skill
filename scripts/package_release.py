"""Refresh skill metadata or produce a complete, checksummed skill Release asset."""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import shutil
import tarfile
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SKILL = ROOT / "skills/axure-forge"


def refresh(version, cli_min, cli_max=None):
    for value in (version, cli_min, cli_max):
        if value is not None and not re.fullmatch(r"(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)", value):
            raise ValueError("Stable X.Y.Z versions only")
    files = {}
    for file in sorted(SKILL.rglob("*")):
        if file.is_symlink():
            raise ValueError("Skill package cannot contain links")
        if file.is_file() and file.name != "skill-manifest.json":
            files[file.relative_to(SKILL).as_posix()] = hashlib.sha256(file.read_bytes()).hexdigest()
    manifest = {"manifest_version": 1, "name": "axure-forge", "version": version,
                "protocol_version": 3, "cli_min_version": cli_min,
                "cli_max_version": cli_max, "platforms": ["macos-arm64"], "files": files}
    (SKILL / "skill-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    return manifest


def package(manifest, output):
    output.mkdir(parents=True, exist_ok=False)
    filename = f"axure-forge-skill-{manifest['version']}.tar.gz"
    with tempfile.TemporaryDirectory() as temporary:
        folder = Path(temporary) / "axure-forge"
        shutil.copytree(SKILL, folder)
        with tarfile.open(output / filename, "w:gz") as archive:
            archive.add(folder, arcname="axure-forge")
    digest = hashlib.sha256((output / filename).read_bytes()).hexdigest()
    release = {k: v for k, v in manifest.items() if k not in ("name", "files")}
    release.update(component="skill", assets={"skill": {"filename": filename, "sha256": digest}})
    (output / "release-manifest.json").write_text(json.dumps(release, indent=2) + "\n")
    (output / "SHA256SUMS").write_text(f"{digest}  {filename}\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True)
    parser.add_argument("--cli-min", required=True)
    parser.add_argument("--cli-max")
    parser.add_argument("--output", type=Path, help="Omit to refresh metadata only")
    args = parser.parse_args()
    manifest = refresh(args.version, args.cli_min, args.cli_max)
    if args.output:
        package(manifest, args.output)
