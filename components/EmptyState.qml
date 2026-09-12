import QtQuick
import QtQuick.Layouts
import qs.Commons

ColumnLayout {
    property string title: "No USB devices detected"
    property string message: "Connect a device, then refresh."
    spacing: Style.space(12)
    Label {
        Layout.alignment: Qt.AlignHCenter
        text: "󰕓"
        font.pixelSize: Style.font.displayLarge
        color: Color.muted
    }
    Label {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: parent.title
        font.pixelSize: Style.font.title
        wrapMode: Text.WordWrap
    }
    Label {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: parent.message
        color: Qt.alpha(Color.foreground, 0.65)
        wrapMode: Text.WordWrap
    }
}
