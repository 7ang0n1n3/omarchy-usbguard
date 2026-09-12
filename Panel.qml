import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC
import Quickshell
import qs.Commons
import qs.Ui as Ui
import "components" as C
import "services" as S
import "services/UsbGuardParser.js" as Parser

Item {
    id: root
    property var shell: null
    property var manifest: null
    property bool opened: false
    property bool standalone: false
    property int tab: 0
    property string filter: "All"
    property var pending: null
    onOpenedChanged: if (opened)
        Qt.callLater(function () {
            keys.forceActiveFocus();
        })
    function open(payload) {
        opened = true;
        Qt.callLater(function () {
            keys.forceActiveFocus();
        });
    }
    function close() {
        opened = false;
    }
    // Read-only support endpoint: identifies the loaded generation, not just files on disk.
    function diagnosticsSnapshot(unused) {
        return JSON.stringify({backend: service.actionBackend, source: Qt.resolvedUrl("Panel.qml").toString(),
            deviceAccess: service.deviceAccess, ruleAccess: service.ruleAccess, error: service.error,
            diagnostics: service.diagnostics, notice: service.notice});
    }
    function toggle(payload) {
        if (opened)
            close();
        else
            open(payload);
    }
    function choose(action, device) {
        if (action === "details") {
            details.device = device;
            details.open();
            return;
        }
        if (service.busy)
            return;
        if (action === "allow") {
            service.execute(action, device);
            return;
        }
        pending = {
            action: action,
            device: device
        };
        confirm.title = action === "remove" ? "Remove saved rule " + device.id + "?" : action === "alwaysAllow" ? "Always allow this device?" : action === "alwaysBlock" ? "Always block this device?" : action === "reject" ? "Reject this device?" : "Block this device?";
        var warning = action === "alwaysAllow" ? "" : Parser.warning(device);
        confirm.message = warning + (action === "remove" ? "This deletes the selected policy rule. Future connections may be handled by another rule or the default policy. The current device state is not changed immediately." : action === "alwaysAllow" ? "Allow “" + device.title + "” now and ask USBGuard to save a device-specific allow rule. The daemon’s insertion policy still applies on reconnect." : action === "alwaysBlock" ? "Block “" + device.title + "” now and save a device-specific block rule. Active transfers may be interrupted." : action === "reject" ? "Remove “" + device.title + "” from the system until it is reconnected. Active transfers may be interrupted." : "Block “" + device.title + "” for this connection. Active transfers may be interrupted.");
        confirm.open();
    }
    S.UsbGuardService {
        id: service
        active: root.opened
    }
    S.Theme {
        standalone: root.standalone
    }
    FloatingWindow {
        id: window
        objectName: "usbguardWindow"
        visible: root.opened
        title: "USBGuard"
        implicitWidth: Style.space(660)
        implicitHeight: Style.space(580)
        minimumSize: Qt.size(540, 440)
        color: Color.popups.background
        onClosed: root.close()
        FocusScope {
            id: keys
            anchors.fill: parent
            focus: true
            readonly property var rows: (root.tab === 0 ? service.devices : service.rules).filter(function (d) {
                return Parser.search(d, search.text) && (root.filter === "All" || d.status === root.filter);
            })
            Keys.onPressed: event => {
                if (actionSheet.opened || details.opened || confirm.opened || setup.opened)
                    return;
                if (event.key === Qt.Key_Escape) {
                    if (search.text || search.activeFocus) {
                        search.text = "";
                        keys.forceActiveFocus();
                    } else
                        root.close();
                    event.accepted = true;
                } else if (!search.activeFocus) {
                    if (event.key === Qt.Key_R) {
                        service.refresh();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Slash) {
                        search.forceActiveFocus();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
                        keys.forceActiveFocus();
                        list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
                        keys.forceActiveFocus();
                        list.currentIndex = Math.max(0, list.currentIndex - 1);
                        event.accepted = true;
                    } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && list.currentIndex >= 0 && root.tab < 2) {
                        root.choose("details", keys.rows[list.currentIndex]);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Menu && list.currentIndex >= 0 && root.tab < 2) {
                        actionSheet.device = keys.rows[list.currentIndex];
                        actionSheet.open();
                        event.accepted = true;
                    }
                }
            }
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Style.spacing.panelPadding
                spacing: Style.space(14)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.space(12)
                    C.Label {
                        text: "󰕓"
                        font.pixelSize: Style.font.display
                        color: Color.accent
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Style.space(3)
                        C.Label {
                            Layout.fillWidth: true
                            text: "USBGuard"
                            font.pixelSize: Style.font.heading
                            font.bold: true
                        }
                        C.Label {
                            Layout.fillWidth: true
                            text: "Control USB device access"
                            font.pixelSize: Style.font.bodySmall
                            color: Qt.alpha(Color.foreground, 0.65)
                        }
                    }
                    Ui.Button {
                        iconText: "󰑐"
                        tooltipText: "Refresh · R"
                        focusable: true
                        enabled: !service.busy
                        iconSpinning: service.busy
                        onClicked: service.refresh()
                    }
                    Ui.Button {
                        iconText: "󰋽"
                        tooltipText: "Setup and diagnostics"
                        focusable: true
                        onClicked: setup.open()
                    }
                    Ui.Button {
                        iconText: "󰅖"
                        tooltipText: "Close · Esc"
                        focusable: true
                        onClicked: root.close()
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Repeater {
                        model: ["Devices", "Rules", "Activity"]
                        Ui.Button {
                            required property int index
                            required property string modelData
                            text: modelData
                            selected: root.tab === index
                            focusable: true
                            onClicked: {
                                root.tab = index;
                                list.currentIndex = 0;
                            }
                        }
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    C.Label {
                        text: service.daemon === "active" ? "● Active" : "○ " + service.daemon
                        color: service.daemon === "active" ? Color.accent : Color.muted
                        font.pixelSize: Style.font.caption
                    }
                }
                Ui.TextField {
                    id: search
                    objectName: "deviceSearch"
                    visible: root.tab < 2
                    Layout.fillWidth: true
                    placeholderText: "Search devices, IDs or serials  /"
                    placeholderTextColor: Qt.alpha(Color.foreground, 0.55)
                    onTextChanged: list.currentIndex = 0
                    onAccepted: {
                        keys.forceActiveFocus();
                        if (keys.rows.length)
                            root.choose("details", keys.rows[Math.max(0, list.currentIndex)]);
                    }
                }
                RowLayout {
                    visible: root.tab < 2
                    Layout.fillWidth: true
                    spacing: Style.space(2)
                    Repeater {
                        model: ["All", "Allowed", "Blocked", "Rejected", "Unknown"]
                        Ui.Button {
                            required property string modelData
                            text: modelData
                            fontSize: Style.font.caption
                            horizontalPadding: Style.space(8)
                            selected: root.filter === modelData
                            focusable: true
                            onClicked: {
                                root.filter = modelData;
                                list.currentIndex = 0;
                            }
                        }
                    }
                }
                C.Label {
                    Layout.fillWidth: true
                    visible: service.error !== "" || !service.installed || service.daemon === "inactive" || service.daemon === "failed"
                    text: !service.installed ? "USBGuard is required. Open setup instructions to get started." : service.daemon === "inactive" || service.daemon === "failed" ? "USBGuard daemon is not running. Open setup instructions." : service.error
                    color: Color.urgent
                    wrapMode: Text.WordWrap
                    elide: Text.ElideNone
                }
                Ui.Button {
                    visible: service.error !== "" || !service.installed || service.daemon === "inactive" || service.daemon === "failed"
                    text: "Show setup instructions"
                    focusable: true
                    onClicked: setup.open()
                }
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    ListView {
                        id: list
                        objectName: "deviceList"
                        anchors.fill: parent
                        visible: root.tab < 2
                        clip: true
                        model: keys.rows
                        currentIndex: 0
                        spacing: Style.space(4)
                        boundsBehavior: Flickable.StopAtBounds
                        QQC.ScrollBar.vertical: QQC.ScrollBar {
                            policy: QQC.ScrollBar.AsNeeded
                        }
                        delegate: C.DeviceRow {
                            required property var modelData
                            required property int index
                            width: list.width - Style.space(10)
                            device: modelData
                            hasCursor: list.currentIndex === index
                            onHovered: list.currentIndex = index
                            onDetails: root.choose("details", device)
                            onActions: {
                                actionSheet.device = device;
                                actionSheet.open();
                            }
                        }
                    }
                    C.EmptyState {
                        anchors.centerIn: parent
                        width: parent.width - Style.space(50)
                        visible: root.tab < 2 && !keys.rows.length
                        title: service.busy ? "Refreshing…" : !(root.tab === 0 ? service.deviceAccess : service.ruleAccess) ? "USBGuard access unavailable" : search.text || root.filter !== "All" ? "No matching results" : root.tab === 0 ? "No USB devices detected" : "No USBGuard rules found"
                        message: !(root.tab === 0 ? service.deviceAccess : service.ruleAccess) ? "Open setup and diagnostics for connection details." : root.tab === 0 ? "Connect a device or adjust your search." : "Saved policy rules appear here, including disconnected devices."
                    }
                    ListView {
                        anchors.fill: parent
                        visible: root.tab === 2
                        clip: true
                        model: service.activity
                        spacing: Style.space(14)
                        delegate: C.Label {
                            required property var modelData
                            width: ListView.view.width
                            text: modelData.time + "   " + modelData.message
                            wrapMode: Text.WordWrap
                        }
                        C.EmptyState {
                            anchors.centerIn: parent
                            width: parent.width
                            visible: service.activity.length === 0
                            title: "No actions this session"
                            message: "Actions performed here appear in this session’s activity."
                        }
                    }
                }
                C.Label {
                    Layout.fillWidth: true
                    visible: service.notice !== ""
                    text: service.notice
                    color: Color.accent
                    font.pixelSize: Style.font.caption
                }
                C.Label {
                    Layout.fillWidth: true
                    text: service.devices.length + " devices · " + service.rules.length + " rules" + (service.insertedPolicy === "block" ? "   ·   New connections start blocked" : "")
                    color: Qt.alpha(Color.foreground, 0.6)
                    font.pixelSize: Style.font.caption
                }
            }
            C.ActionMenu {
                id: actionSheet
                objectName: "actionMenu"
                onClosed: keys.forceActiveFocus()
                onChosen: (action, device) => root.choose(action, device)
            }
            C.DeviceDetails {
                id: details
                objectName: "deviceDetails"
                onClosed: keys.forceActiveFocus()
                rules: service.rules
                onRemoveRule: rule => {
                    details.close();
                    root.choose("remove", rule);
                }
            }
            C.ConfirmDialog {
                id: confirm
                objectName: "confirmation"
                onClosed: keys.forceActiveFocus()
                onConfirmed: {
                    if (root.pending)
                        service.execute(root.pending.action, root.pending.device);
                    root.pending = null;
                }
            }
            C.Sheet {
                id: setup
                onClosed: keys.forceActiveFocus()
                contentItem: QQC.ScrollView {
                    implicitHeight: setupContent.implicitHeight
                    contentWidth: availableWidth
                    clip: true
                    ColumnLayout {
                        id: setupContent
                        width: parent.width
                        spacing: Style.space(14)
                        C.Label {
                            text: "Setup & diagnostics"
                            font.pixelSize: Style.font.heading
                            font.bold: true
                        }
                        C.Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            text: "Action backend: " + service.actionBackend + "\n" + service.version + "\nDaemon: " + service.daemon + "\nDevice IPC: " + (service.deviceAccess ? "available" : "unavailable") + "\nPolicy IPC: " + (service.ruleAccess ? "available" : "unavailable") + "\n" + service.devices.length + " devices · " + service.rules.length + " rules"
                        }
                        C.Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            elide: Text.ElideNone
                            text: "Device and rule changes request administrator authentication through Omarchy’s polkit dialog. The UI stays unprivileged, and no password is stored.\n\nInstall the root-owned helper once from the project directory:\nbash install-privileged.sh\n\nBrowsing uses your existing read-only USBGuard IPC access and never opens an authentication dialog. No USBGuard group membership or persistent write permission is required.\n\nIf listing is denied, an administrator can grant read-only IPC access; see README.\n\nPermanent actions save a rule through USBGuard. They do not override the daemon’s insertion policy. Rejected devices may disappear until reconnected.\n\nUSBGuard package (Arch):\nsudo pacman -S usbguard"
                        }
                        Ui.Button {
                            text: "Technical details"
                            focusable: true
                            onClicked: technical.visible = !technical.visible
                        }
                        C.Label {
                            id: technical
                            visible: false
                            Layout.fillWidth: true
                            text: service.diagnostics || "No diagnostic errors recorded."
                            wrapMode: Text.WrapAnywhere
                            elide: Text.ElideNone
                            font.pixelSize: Style.font.caption
                        }
                        Ui.Button {
                            text: "Close"
                            Layout.alignment: Qt.AlignRight
                            focusable: true
                            onClicked: setup.close()
                        }
                    }
                }
            }
        }
    }
}
