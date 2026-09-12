import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui as Ui

Sheet {
    id: root
    property var device: null
    signal chosen(string action, var device)
    readonly property var actions: !device ? [] : device.kind === "rule" ? [
        {
            text: "View rule details",
            action: "details"
        },
        {
            text: "Remove rule…",
            action: "remove"
        }
    ] : [
        {
            text: "View details",
            action: "details"
        },
        {
            text: "Allow temporarily",
            action: "allow",
            show: device.target !== "allow"
        },
        {
            text: "Always allow this device…",
            action: "alwaysAllow"
        },
        {
            text: "Block temporarily…",
            action: "block",
            show: device.target !== "block"
        },
        {
            text: "Always block this device…",
            action: "alwaysBlock"
        },
        {
            text: "Reject device…",
            action: "reject",
            show: device.target !== "reject"
        }
    ].filter(function (a) {
        return a.show !== false;
    })
    contentItem: ColumnLayout {
        spacing: Style.space(5)
        Label {
            Layout.fillWidth: true
            text: root.device ? root.device.title : ""
            font.bold: true
            bottomPadding: Style.space(12)
        }
        Repeater {
            model: root.actions
            Ui.Button {
                required property var modelData
                Layout.fillWidth: true
                leftAlign: true
                focusable: true
                text: modelData.text
                onClicked: {
                    root.close();
                    root.chosen(modelData.action, root.device);
                }
            }
        }
    }
}
