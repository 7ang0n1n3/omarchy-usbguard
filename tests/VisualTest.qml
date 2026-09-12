import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import QtTest
import "services/UsbGuardParser.js" as Parser
ShellRoot {
    Panel { id: app; opened: true; standalone: true }
    TestCase { id: input; when: false }
    IpcHandler {
        target: "preview"
        function tab(index: int): void { app.tab = index; }
        function details(): void { app.choose("details", sample()); }
        function confirm(): void { app.choose("alwaysBlock", sample()); }
        function mouseDetails(): void {
            var list = input.findChild(app, "deviceList");
            input.mouseClick(list, 100, 35);
        }
        function mouseMenu(): void {
            var list = input.findChild(app, "deviceList");
            input.mouseClick(list, list.width - 40, 35);
        }
        function snapshot(): string {
            var list = input.findChild(app, "deviceList");
            var search = input.findChild(app, "deviceSearch");
            return JSON.stringify({count:list.count,search:search.text,details:input.findChild(app,"deviceDetails").opened,menu:input.findChild(app,"actionMenu").opened,confirmation:input.findChild(app,"confirmation").opened});
        }
        function key(code: int): void {
            input.parent = input.findChild(app, "usbguardWindow").contentItem;
            input.keyClick(code);
        }
        function sample(): var { return Parser.parse('17: allow id 1234:5678 name "Composite input device" serial "Test serial" hash "test-hash" with-interface { 03:01:01 03:01:02 }', "device")[0]; }
    }
}
