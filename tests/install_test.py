"""Exercise user installation in temporary XDG roots without shell IPC."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class InstallTest(unittest.TestCase):
    def test_install_update_remove_and_collision(self):
        with tempfile.TemporaryDirectory(prefix="usbguard-install-") as temporary:
            base = Path(temporary)
            modules = base / "omarchy/shell"
            (modules / "Commons").mkdir(parents=True)
            (modules / "Commons/Color.qml").touch()
            (modules / "Ui").mkdir()
            (base / "bin").mkdir()
            stub = base / "bin/omarchy"
            stub.write_text('#!/bin/sh\n[ "$*" = "plugin disable tangonine.usbguard" ]\n')
            stub.chmod(0o755)
            env = dict(os.environ, XDG_CONFIG_HOME=str(base / "config"),
                       XDG_DATA_HOME=str(base / "data"), OMARCHY_PATH=str(base / "omarchy"),
                       PATH=str(base / "bin") + ":" + os.environ["PATH"])

            def run(script, success=True):
                result = subprocess.run(["bash", str(ROOT / script)], env=env,
                                        capture_output=True, text=True)
                self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)

            app = base / "config/quickshell/usbguard"
            plugin = base / "config/omarchy/plugins/tangonine.usbguard"
            desktop = base / "data/applications/omarchy-usbguard.desktop"
            run("install.sh")
            first = (app / "shell.qml").read_bytes()
            self.assertTrue((app / "Commons").is_symlink())
            self.assertFalse(any(p.is_symlink() for p in plugin.rglob("*")))
            entry = json.loads((plugin / "manifest.json").read_text())["entryPoints"]["panel"]
            self.assertTrue((plugin / entry).is_file())
            self.assertIn(entry.rsplit("/", 1)[0].encode(), first)
            run("install.sh")
            self.assertEqual(first, (app / "shell.qml").read_bytes())
            run("uninstall.sh")
            self.assertFalse(app.exists())
            self.assertFalse(plugin.exists())
            self.assertFalse(desktop.exists())
            run("uninstall.sh")
            app.mkdir()
            (app / "unrelated").write_text("keep")
            run("install.sh", success=False)
            self.assertEqual((app / "unrelated").read_text(), "keep")
            self.assertFalse(plugin.exists())


if __name__ == "__main__":
    unittest.main()
