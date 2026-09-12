import QtQuick
import Quickshell.Io

Process {
    id: root
    property string output: ""
    property string errors: ""
    property int timeoutSeconds: 10
    signal finished(int code, string output, string errors)
    function start(args) {
        if (running)
            return false;
        // Fail closed if an old caller tries to bypass the authenticated helper.
        if (args.length > 1 && /(^|\/)usbguard$/.test(args[0]) && /^(allow-device|block-device|reject-device|remove-rule|append-rule)$/.test(args[1])) {
            Qt.callLater(function() { root.finished(64, "", "Unauthenticated mutation refused. Reopen the updated USBGuard application."); });
            return false;
        }
        output = "";
        errors = "";
        command = ["timeout", "--kill-after=2s", timeoutSeconds + "s"].concat(args);
        running = true;
        return true;
    }
    stdout: StdioCollector {
        waitForEnd: true
        onStreamFinished: root.output = text
    }
    stderr: StdioCollector {
        waitForEnd: true
        onStreamFinished: root.errors = text
    }
    onExited: code => root.finished(code, root.output, code === 124 || code === 137 ? "USBGuard request timed out. " + root.errors : root.errors)
}
