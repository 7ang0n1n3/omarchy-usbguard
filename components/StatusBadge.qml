import QtQuick
import qs.Commons

Rectangle {
    id: root
    property string status: "Unknown"
    readonly property color tint: status === "Allowed" ? Color.accent : status === "Rejected" ? Color.urgent : Color.foreground
    implicitWidth: label.implicitWidth + Style.space(16)
    implicitHeight: label.implicitHeight + Style.space(8)
    radius: Style.cornerRadius
    color: Qt.alpha(tint, 0.10)
    Label {
        id: label
        anchors.centerIn: parent
        text: root.status.toUpperCase()
        font.pixelSize: Style.font.caption
        color: root.tint
    }
}
