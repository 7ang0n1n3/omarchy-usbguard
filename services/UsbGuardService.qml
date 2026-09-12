import QtQuick
import Quickshell
import Quickshell.Io
import "UsbGuardParser.js" as Parser

Item {
    id: root
    property bool active: true
    property var devices: []
    property var rules: []
    property var activity: []
    property string version: "Checking…"
    property string daemon: "checking"
    property string error: ""
    property string diagnostics: ""
    property bool installed: true
    property bool deviceAccess: false
    property bool ruleAccess: false
    property bool pendingRefresh: false
    property var pendingAction: null
    property var metadata: ({})
    property string notice: ""
    property string insertedPolicy: ""
    readonly property string actionBackend: "polkit-v3"
    readonly property bool busy: deviceProc.running || ruleProc.running || mutation.running || preflight.running
    readonly property bool operating: mutation.running || preflight.running
    function log(message) {
        activity = [
            {
                time: new Date().toLocaleTimeString(),
                message: message
            }
        ].concat(activity).slice(0, 80);
    }
    function fail(raw, context) {
        diagnostics = (context ? context + ": " : "") + raw;
        error = Parser.humanError(raw);
        if (context === "Device listing" || context === "Rule listing")
            error = context + " failed. " + error;
        else if (context === "Authenticated action")
            error = "Authenticated USBGuard action failed. Check diagnostics for the daemon response.";
        console.warn("USBGuard " + actionBackend + " · " + (context || "Request") + " failed");
        log(error);
    }
    function enrich(rows) {
        return rows.map(function (d) {
            var m = root.metadata[d.port];
            if (m && m.id === d.usbId) {
                d.manufacturer = m.manufacturer;
                if (!d.name && m.product)
                    d.title = m.product;
            }
            return d;
        });
    }
    function refresh() {
        if (!active)
            return;
        if (busy) {
            pendingRefresh = true;
            return;
        }
        pendingRefresh = false;
        error = "";
        versionProc.start(["usbguard", "--version"]);
        statusProc.start(["systemctl", "is-active", "usbguard.service"]);
        metadataProc.start(["bash", Qt.resolvedUrl("usb-metadata.sh").toString().replace("file://", "")]);
        deviceProc.start(["usbguard", "list-devices"]);
        ruleProc.start(["usbguard", "list-rules"]);
        policyProc.start(["usbguard", "get-parameter", "InsertedDevicePolicy"]);
    }
    // Re-read identity before mutation: daemon restarts can recycle numeric IDs.
    function execute(action, device) {
        if (busy || !active)
            return;
        notice = "";
        error = "";
        try {
            Parser.command(action, device);
        } catch (e) {
            fail(String(e));
            return;
        }
        pendingAction = {
            action: action,
            device: device
        };
        preflight.start(["usbguard", device.kind === "rule" ? "list-rules" : "list-devices"]);
    }
    onBusyChanged: if (!busy && pendingRefresh)
        Qt.callLater(refresh)
    onActiveChanged: {
        if (active)
            refresh();
        else
            watch.running = false;
    }
    Component.onCompleted: if (active)
        refresh()
    Command {
        id: versionProc
        onFinished: (code, out, err) => {
            root.installed = code === 0;
            root.version = code === 0 ? out.split("\n")[0] : "Not installed / unavailable";
        }
    }
    Command {
        id: statusProc
        onFinished: (code, out, err) => root.daemon = out.trim() || "unknown"
    }
    Command {
        id: policyProc
        onFinished: (code, out, err) => root.insertedPolicy = code === 0 ? out.trim().replace(/^"|"$/g, "") : ""
    }
    Command {
        id: metadataProc
        onFinished: (code, out, err) => {
            var map = {};
            out.split("\n").forEach(function (line) {
                var a = line.split("\t");
                if (a.length === 4)
                    map[a[0]] = {
                        id: a[1],
                        manufacturer: a[2],
                        product: a[3]
                    };
            });
            root.metadata = map;
            root.devices = root.enrich(root.devices);
        }
    }
    Command {
        id: deviceProc
        onFinished: (code, out, err) => {
            root.deviceAccess = code === 0;
            if (code !== 0) {
                root.devices = [];
                root.fail(err, "Device listing");
                return;
            }
            try {
                root.devices = root.enrich(Parser.parse(out, "device"));
            } catch (e) {
                root.devices = [];
                root.deviceAccess = false;
                root.fail(String(e));
            }
            if (root.active && root.deviceAccess && !watch.running)
                watch.running = true;
        }
    }
    Command {
        id: ruleProc
        onFinished: (code, out, err) => {
            root.ruleAccess = code === 0;
            if (code !== 0) {
                root.rules = [];
                root.fail(err, "Rule listing");
                return;
            }
            try {
                root.rules = Parser.parse(out, "rule");
            } catch (e) {
                root.rules = [];
                root.ruleAccess = false;
                root.fail(String(e));
            }
        }
    }
    Command {
        id: preflight
        onFinished: (code, out, err) => {
            var request = root.pendingAction;
            root.pendingAction = null;
            if (code !== 0) {
                root.fail(err, "Action preflight");
                return;
            }
            try {
                var current = Parser.parse(out, request.device.kind).filter(function (d) {
                    return d.id === request.device.id;
                })[0];
                if (!current || current.raw !== request.device.raw) {
                    root.error = "The selected device or rule changed. Refresh and review it before trying again.";
                    root.pendingRefresh = true;
                    return;
                }
                mutation.actionLabel = ({allow: "Allowed temporarily", block: "Blocked temporarily", reject: "Rejected", alwaysAllow: "Saved allow rule", alwaysBlock: "Saved block rule", remove: "Removed rule"})[request.action] + " · " + request.device.title;
                root.notice = "Waiting for administrator authentication…";
                console.info("USBGuard " + root.actionBackend + " · requesting pkexec for " + request.action + " #" + current.id);
                mutation.start(["/usr/bin/pkexec", "--disable-internal-agent", "/usr/local/libexec/omarchy-usbguard-action", request.action, current.id, current.raw]);
            } catch (e) {
                root.fail(String(e));
            }
        }
    }
    Command {
        id: mutation
        // Allow time to read the polkit dialog; the helper bounds each CLI call.
        timeoutSeconds: 180
        property string actionLabel: ""
        onFinished: (code, out, err) => {
            if (code === 0) {
                root.notice = "Done · " + actionLabel;
                root.log(root.notice);
            } else {
                root.notice = "";
                if (code === 126) {
                    root.error = "Authentication canceled. No USBGuard change was requested.";
                } else if (code === 127) {
                    root.diagnostics = err;
                    root.error = /No such file|not found|Error executing/i.test(err)
                        ? "The privileged USBGuard helper is missing. Run install-privileged.sh once, then try again."
                        : "Administrator authentication was not granted. Check the polkit authentication agent and try again.";
                } else root.fail(err, "Authenticated action");
            }
            // Preserve action errors while refreshing the two authoritative lists.
            deviceProc.start(["usbguard", "list-devices"]);
            ruleProc.start(["usbguard", "list-rules"]);
        }
    }
    Process {
        id: watch
        command: ["stdbuf", "-oL", "usbguard", "watch"]
        stdout: SplitParser {
            onRead: data => debounce.restart()
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim())
                root.diagnostics = text
        }
    }
    Timer {
        id: debounce
        interval: 350
        onTriggered: root.refresh()
    }
    // Also recovers from daemon restarts / missing listen permission and observes other clients' rule edits.
    Timer {
        interval: 30000
        repeat: true
        running: root.active
        onTriggered: root.refresh()
    }
}
