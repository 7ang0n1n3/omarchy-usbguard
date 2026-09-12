import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui as Ui

Ui.CursorSurface {
    id: root
    required property var device
    signal details
    signal actions
    signal hovered
    implicitHeight: Style.space(76)
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered()
        onClicked: root.details()
    }
    RowLayout {
        anchors.fill: parent
        anchors.margins: Style.spacing.rowPaddingX
        spacing: Style.space(14)
        Label {
            text: root.device.icon
            font.pixelSize: Style.font.iconLarge
            color: Color.accent
            Layout.preferredWidth: Style.space(26)
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.space(5)
            Label {
                Layout.fillWidth: true
                text: root.device.title
                font.bold: true
            }
            Label {
                Layout.fillWidth: true
                text: (root.device.manufacturer ? root.device.manufacturer + " · " : "") + root.device.usbId + " · " + (root.device.kind === "rule" ? "Rule " : "#") + root.device.id
                color: Qt.alpha(Color.foreground, 0.65)
                font.pixelSize: Style.font.bodySmall
            }
        }
        StatusBadge {
            status: root.device.status
        }
        Ui.Button {
            iconText: "󰇙"
            tooltipText: "Device actions"
            focusable: true
            onClicked: root.actions()
        }
    }
}
