import QtQuick
import QtQuick.Controls as QQC
import qs.Commons
import qs.Ui as Ui

QQC.Popup {
    id: root
    parent: QQC.Overlay.overlay
    modal: true
    focus: true
    width: Math.min(parent.width - Style.space(32), Style.space(470))
    height: Math.min(implicitHeight, parent.height - Style.space(32))
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    padding: Style.spacing.panelPadding
    closePolicy: QQC.Popup.CloseOnEscape | QQC.Popup.CloseOnPressOutside
    background: Ui.BorderSurface {
        color: Color.background
        radius: Style.cornerRadius
        borderSpec: Border.flat(Qt.alpha(Color.foreground, 0.22), 1)
    }
    QQC.Overlay.modal: Rectangle {
        color: Qt.alpha(Color.background, 0.76)
    }
    enter: Transition {
        NumberAnimation {
            property: "opacity"
            from: 0
            to: 1
            duration: 120
        }
    }
    exit: Transition {
        NumberAnimation {
            property: "opacity"
            from: 1
            to: 0
            duration: 80
        }
    }
}
