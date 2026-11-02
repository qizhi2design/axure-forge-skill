"""Developer-only tests for the installed skill baseline and Release packaging."""
import hashlib
import json
import runpy
import tarfile
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
namespace = runpy.run_path(str(ROOT / "scripts/package_release.py"))
refresh = namespace["refresh"]
package = namespace["package"]


class ReleaseTests(unittest.TestCase):
    def test_committed_baseline_matches_files(self):
        folder = ROOT / "skills/axure-forge"
        manifest = json.loads((folder / "skill-manifest.json").read_text())
        files = {file.relative_to(folder).as_posix(): hashlib.sha256(file.read_bytes()).hexdigest()
                 for file in folder.rglob("*") if file.is_file() and file.name != "skill-manifest.json"}
        self.assertEqual(manifest["files"], files, "Refresh skill-manifest.json after editing skill files")

    def test_archive_contract_and_immutable_output(self):
        with tempfile.TemporaryDirectory() as temporary:
            folder = Path(temporary) / "skill"
            folder.mkdir()
            (folder / "SKILL.md").write_text("---\nname: axure-forge\n---\nExample")
            original = refresh.__globals__["SKILL"]
            refresh.__globals__["SKILL"] = folder
            try:
                manifest = refresh("0.4.0", "0.3.0", "0.5.0")
                output = Path(temporary) / "release"
                package(manifest, output)
                archive = output / "axure-forge-skill-0.4.0.tar.gz"
                release = json.loads((output / "release-manifest.json").read_text())
                digest = hashlib.sha256(archive.read_bytes()).hexdigest()
                self.assertEqual(release["assets"]["skill"]["sha256"], digest)
                self.assertIn(digest, (output / "SHA256SUMS").read_text())
                with tarfile.open(archive) as reader:
                    bundled = json.load(reader.extractfile("axure-forge/skill-manifest.json"))
                    self.assertEqual(bundled, manifest)
                with self.assertRaises(FileExistsError):
                    package(manifest, output)
            finally:
                refresh.__globals__["SKILL"] = original


if __name__ == "__main__":
    unittest.main()
