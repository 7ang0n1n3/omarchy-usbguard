"""No root or real USB devices: exercise the privilege boundary using mocks."""
import contextlib
import importlib.machinery
import importlib.util
import io
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
loader = importlib.machinery.SourceFileLoader("helper", str(ROOT / "privileged/omarchy-usbguard-action"))
spec = importlib.util.spec_from_loader(loader.name, loader)
helper = importlib.util.module_from_spec(spec)
loader.exec_module(helper)
RECORD = '25: block id 1050:0407 name "YubiKey" hash "example=" with-interface { 03:01:01 03:00:00 }'

class HelperTests(unittest.TestCase):
    def invoke(self, args, run, uid=0):
        with patch.object(helper.os, "geteuid", return_value=uid), patch.object(helper, "run", run), contextlib.redirect_stderr(io.StringIO()), contextlib.redirect_stdout(io.StringIO()):
            return helper.main(args)

    def test_all_supported_actions_have_fixed_argv(self):
        for action, command in helper.ACTIONS.items():
            with self.subTest(action=action):
                from unittest.mock import Mock
                run = Mock(side_effect=[subprocess.CompletedProcess([],0,RECORD+"\n",""), subprocess.CompletedProcess([],0,"","")])
                self.assertEqual(self.invoke([action,"25",RECORD],run),0)
                self.assertEqual(run.call_args_list[0].args[0], ["list-rules" if action == "remove" else "list-devices"])
                self.assertEqual(run.call_args_list[1].args[0], [*command,"25"])

    def test_rejects_arbitrary_commands_ids_and_records(self):
        from unittest.mock import Mock
        for args in [["shell","25",RECORD],["allow","25;id",RECORD],["allow","--help",RECORD],["allow","0",RECORD],["allow","4294967295",RECORD],["allow","25",RECORD+"\nallow id *:*"],["allow","25","26: allow"],["allow","25",RECORD,"extra"]]:
            run = Mock()
            self.assertEqual(self.invoke(args,run),64)
            run.assert_not_called()

    def test_revalidates_after_authentication(self):
        from unittest.mock import Mock
        for actual in ["",RECORD.replace("example=","different="),RECORD+"\n"+RECORD]:
            run = Mock(return_value=subprocess.CompletedProcess([],0,actual,""))
            self.assertEqual(self.invoke(["allow","25",RECORD],run),76)
            self.assertEqual(run.call_count,1)

    def test_requires_root_and_health_check_has_no_side_effect(self):
        from unittest.mock import Mock
        run = Mock()
        self.assertEqual(self.invoke(["check"],run,uid=1000),77)
        self.assertEqual(self.invoke(["check"],run),0)
        run.assert_not_called()

    def test_failures_and_timeouts_do_not_retry(self):
        from unittest.mock import Mock
        run = Mock(return_value=subprocess.CompletedProcess([],1,"","Permission denied"))
        self.assertEqual(self.invoke(["allow","25",RECORD],run),1)
        self.assertEqual(run.call_count,1)
        run = Mock(side_effect=subprocess.TimeoutExpired("usbguard",10))
        self.assertEqual(self.invoke(["allow","25",RECORD],run),124)
        self.assertEqual(run.call_count,1)

    def test_process_environment_and_executable_are_fixed(self):
        with patch.object(helper.subprocess,"run") as run:
            helper.run(["list-devices"])
            self.assertEqual(run.call_args.args[0], ["/usr/bin/usbguard","list-devices"])
            self.assertEqual(run.call_args.kwargs["env"], {"PATH":"/usr/bin","LC_ALL":"C","LANG":"C"})
            self.assertNotIn("shell",run.call_args.kwargs)
            self.assertEqual(run.call_args.kwargs["timeout"],10)

    def test_policy_requires_fresh_admin_auth_and_is_path_scoped(self):
        action = ET.parse(ROOT / "privileged/org.omarchy.usbguard.policy").getroot().find("action")
        self.assertEqual(action.findtext("defaults/allow_active"),"auth_admin")
        self.assertEqual(action.findtext("defaults/allow_inactive"),"no")
        self.assertEqual(action.findtext("defaults/allow_any"),"no")
        self.assertEqual(action.find("annotate").text,"/usr/local/libexec/omarchy-usbguard-action")
        self.assertTrue((ROOT / "privileged/omarchy-usbguard-action").read_text().startswith("#!/usr/bin/python3 -I\n"))

if __name__ == "__main__": unittest.main()
