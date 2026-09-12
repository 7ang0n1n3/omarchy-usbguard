import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC
import qs.Commons
import qs.Ui as Ui

Sheet {
    id: root
    property var device: null
    property var rules: []
    signal removeRule(var rule)
    readonly property var related: device && device.kind === "device" && device.hash ? rules.filter(function (r) {
        return r.hash === root.device.hash;
    }) : []
    contentItem: QQC.ScrollView {
        implicitHeight: content.implicitHeight
        contentWidth: availableWidth
        clip: true
        ColumnLayout {
            id: content
            width: parent.width
            spacing: Style.space(14)
            Label {
                Layout.fillWidth: true
                text: root.device ? root.device.title : ""
                font.pixelSize: Style.font.heading
                font.bold: true
                wrapMode: Text.Wrap
            }
            StatusBadge {
                status: root.device ? root.device.status : "Unknown"
            }
            Repeater {
                model: root.device ? [["Connection", root.device.kind === "device" ? "Recognized by USBGuard" : "Saved policy · not a live connection"], ["Manufacturer", root.device.manufacturer || "Not reported"], [root.device.kind === "rule" ? "Rule ID" : "Device ID", root.device.id], ["Vendor : product", root.device.usbId], ["Serial", root.device.serial || "Not reported"], ["Port", root.device.port || "Not constrained"], ["Interfaces", root.device.interfaces || "Not reported"], ["Device hash", root.device.hash || "Not constrained"]] : []
                ColumnLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: Style.space(3)
                    Label {
                        text: parent.modelData[0]
                        color: Qt.alpha(Color.foreground, 0.6)
                        font.pixelSize: Style.font.caption
                    }
                    Label {
                        Layout.fillWidth: true
                        text: parent.modelData[1]
                        wrapMode: Text.WrapAnywhere
                        elide: Text.ElideNone
                    }
                }
            }
            Label {
                visible: root.related.length > 0
                Layout.fillWidth: true
                text: "Rules with the same device hash"
                color: Color.accent
            }
            Repeater {
                model: root.related
                Ui.Button {
                    required property var modelData
                    Layout.fillWidth: true
                    text: "Remove rule " + modelData.id + " · " + modelData.status
                    focusable: true
                    onClicked: root.removeRule(modelData)
                }
            }
            Label {
                visible: root.related.length > 0
                Layout.fillWidth: true
                text: "Hash association only; other rule conditions can differ."
                wrapMode: Text.WordWrap
                font.pixelSize: Style.font.caption
                color: Qt.alpha(Color.foreground, 0.6)
            }
            Ui.Button {
                text: "Full USBGuard record"
                focusable: true
                onClicked: record.visible = !record.visible
            }
            Label {
                id: record
                visible: false
                Layout.fillWidth: true
                text: root.device ? root.device.raw : ""
                wrapMode: Text.WrapAnywhere
                elide: Text.ElideNone
                font.pixelSize: Style.font.caption
            }
            Ui.Button {
                text: "Close"
                focusable: true
                Layout.alignment: Qt.AlignRight
                onClicked: root.close()
            }
        }
    }
}
