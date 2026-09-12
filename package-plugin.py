#!/usr/bin/env python3
"""Publish a complete, immutable QML generation before switching its manifest."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import sys
import tempfile

def package(source, destination):
    paths = [Path("Panel.qml")]
    for directory in ("components", "services"):
        paths += sorted(p.relative_to(source) for p in (source / directory).rglob("*")
                        if p.is_file() and p.suffix in (".qml", ".js", ".sh"))
    digest = hashlib.sha256()
    for path in paths:
        digest.update(str(path).encode() + b"\0" + (source / path).read_bytes() + b"\0")
    revision = digest.hexdigest()[:20]
    releases = destination / "releases"
    releases.mkdir(parents=True, exist_ok=True)
    release = releases / revision
    if not release.exists():
        with tempfile.TemporaryDirectory(prefix="usbguard-package-") as temporary:
            stage = Path(temporary) / revision
            for path in paths:
                (stage / path).parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(source / path, stage / path)
            shutil.move(str(stage), str(release))
    manifest = json.loads((source / "manifest.json").read_text())
    manifest["entryPoints"]["panel"] = f"releases/{revision}/Panel.qml"
    next_manifest = destination / ".manifest.next"
    next_manifest.write_text(json.dumps(manifest, indent=2) + "\n")
    os.replace(next_manifest, destination / "manifest.json")
    return revision

if __name__ == "__main__":
    print("Plugin release:", package(Path(sys.argv[1]), Path(sys.argv[2])))
