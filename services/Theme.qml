import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// The plugin receives theme updates from Omarchy. Standalone uses the very same
// singleton loaders; periodic reload handles replacement of the theme symlink.
Item {
    property bool standalone: false
    FileView {
        id: colors
        path: Color.currentThemePath + "/colors.toml"
        printErrors: false
        onLoaded: Color.loadColors(text())
    }
    FileView {
        id: surfaces
        path: Color.currentThemePath + "/shell.toml"
        printErrors: false
        onLoaded: Color.loadShell(text())
        onLoadFailed: Color.loadShell("")
    }
    Timer {
        interval: 2500
        repeat: true
        running: standalone
        onTriggered: {
            colors.reload();
            surfaces.reload();
        }
    }
}
