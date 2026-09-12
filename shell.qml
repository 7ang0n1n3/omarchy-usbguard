import Quickshell
import Quickshell.Io

ShellRoot {
    Panel {
        id: app
        standalone: true
        opened: true
        onOpenedChanged: if (!opened)
            Qt.quit()
    }
    IpcHandler {
        target: "usbguard"
        function refresh(): void {
            app.open("");
        }
    }
}
