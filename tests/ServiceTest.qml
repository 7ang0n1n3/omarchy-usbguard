import QtQuick
import Quickshell
import Quickshell.Io
import "../services" as S
ShellRoot {
    S.UsbGuardService { id: service }
    property int stage: 0
    property int ticks: 0
    property int legacyBlocked: 0
    S.Command {
        id: legacy
        onFinished: (code, out, err) => {
            check(code === 64 && /Unauthenticated mutation refused/.test(err), "legacy direct mutation refused");
            legacyBlocked++;
        }
    }
    Component.onCompleted: {
        ["allow-device", "block-device", "reject-device", "remove-rule", "append-rule"].forEach(function(action) {
            legacy.start(["usbguard", action, "17"]);
        });
    }
    function check(value, message) { if (!value) { console.error("FAIL " + message); Qt.exit(1); } else console.log("PASS " + message); }
    Process {
        id: mode
        function setMode(value) {
            command = ["node", "-e", "const f=require('fs'),p=process.env.USBGUARD_TEST_DIR+'/state.json';const s=JSON.parse(f.readFileSync(p));s.mode=process.argv[1];if(s.mode==='reconnect'){s.mode='normal';s.connected=true;}f.writeFileSync(p,JSON.stringify(s));", value];
            running = true;
        }
        onExited: service.refresh()
    }
    Timer {
        interval: 350; running: true; repeat: true
        onTriggered: {
            if (++ticks > 130) { console.error("FAIL test timeout at " + stage); Qt.exit(1); }
            if (service.busy || mode.running || service.version === "Checking…") return;
            switch(stage) {
            case 0:
                if (!service.devices.length || legacyBlocked !== 5) return;
                check(service.devices.length === 1 && service.rules.length === 1, "device and rule listing");
                service.execute("allow", service.devices[0]); stage++; break;
            case 1:
                check(service.devices[0].status === "Allowed", "temporary allow and automatic refresh");
                service.execute("alwaysBlock", service.devices[0]); stage++; break;
            case 2:
                check(service.devices[0].status === "Blocked" && service.rules[0].status === "Blocked", "permanent block");
                service.execute("alwaysAllow", service.devices[0]); stage++; break;
            case 3:
                check(service.rules[0].status === "Allowed", "permanent allow");
                service.execute("block", service.devices[0]); stage++; break;
            case 4:
                check(service.devices[0].status === "Blocked" && service.rules[0].status === "Allowed", "temporary block preserves policy");
                service.execute("remove", service.rules[0]); stage++; break;
            case 5:
                check(service.rules.length === 0, "rule deletion refresh");
                service.execute("reject", service.devices[0]); stage++; break;
            case 6:
                check(service.devices.length === 0, "reject / disconnected device");
                mode.setMode("reconnect"); stage++; break;
            case 7:
                check(service.devices.length === 1, "reconnect and manual refresh");
                mode.setMode("denied"); stage++; break;
            case 8:
                check(!service.deviceAccess && !service.ruleAccess && service.devices.length === 0 && /Permission denied/.test(service.error), "permission denied clears stale data");
                mode.setMode("stopped"); stage++; break;
            case 9:
                check(service.daemon === "inactive" && !service.deviceAccess, "stopped daemon");
                mode.setMode("normal"); stage++; break;
            case 10:
                check(service.deviceAccess && service.devices.length === 1, "daemon recovery");
                var stale = Object.assign({}, service.devices[0]); stale.raw = "old identity";
                service.execute("allow", stale); stage++; break;
            case 11:
                check(!service.operating, "stale identity rejected without mutation");
                mode.setMode("auth_cancel"); stage++; break;
            case 12:
                service.execute("allow", service.devices[0]); stage++; break;
            case 13:
                check(/Authentication canceled/.test(service.error), "authentication cancellation without mutation");
                mode.setMode("auth_denied"); stage++; break;
            case 14:
                service.execute("allow", service.devices[0]); stage++; break;
            case 15:
                check(/not granted/.test(service.error), "authentication denied without retry");
                mode.setMode("missing_helper"); stage++; break;
            case 16:
                service.execute("allow", service.devices[0]); stage++; break;
            case 17:
                check(/helper is missing/.test(service.error), "missing privileged helper instructions");
                mode.setMode("missing"); stage++; break;
            case 18:
                check(!service.installed && !service.deviceAccess, "USBGuard not installed");
                console.log("SERVICE TESTS PASSED"); Qt.quit();
            }
        }
    }
}
