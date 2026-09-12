import importlib.util
import json
from pathlib import Path
import shutil
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("packaging", ROOT / "package-plugin.py")
packaging = importlib.util.module_from_spec(spec)
spec.loader.exec_module(packaging)

class PackagingTest(unittest.TestCase):
    def test_releases_are_complete_immutable_and_reusable(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            source = base / "source"
            source.mkdir()
            for filename in ("Panel.qml", "manifest.json"):
                shutil.copyfile(ROOT / filename, source / filename)
            for folder in ("components", "services"):
                shutil.copytree(ROOT / folder, source / folder)
            destination = base / "plugin"
            first = packaging.package(source, destination)
            old = destination / "releases" / first / "services/UsbGuardService.qml"
            old_bytes = old.read_bytes()
            self.assertEqual(packaging.package(source, destination), first)
            with (source / "services/UsbGuardService.qml").open("a") as stream:
                stream.write("\n// changed nested component\n")
            second = packaging.package(source, destination)
            self.assertNotEqual(first, second)
            self.assertEqual(old.read_bytes(), old_bytes)
            manifest = json.loads((destination / "manifest.json").read_text())
            self.assertEqual(manifest["entryPoints"]["panel"], f"releases/{second}/Panel.qml")
            for filename in ("Panel.qml", "components/ConfirmDialog.qml", "services/Command.qml", "services/UsbGuardParser.js", "services/usb-metadata.sh"):
                self.assertTrue((destination / "releases" / second / filename).is_file())
            self.assertFalse(any(p.is_symlink() for p in destination.rglob("*")))

if __name__ == "__main__": unittest.main()
