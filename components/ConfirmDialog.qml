import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC
import qs.Commons
import qs.Ui as Ui

Sheet {
    id: root
    property string message: ""
    property string title: "Confirm device action"
    signal confirmed
    closePolicy: QQC.Popup.CloseOnEscape
    onOpened: cancel.forceActiveFocus()
    contentItem: ColumnLayout {
        spacing: Style.space(18)
        Label {
            text: root.title
            font.bold: true
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }
        QQC.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: Math.min(messageText.implicitHeight, Style.space(260))
            contentWidth: availableWidth
            clip: true
            Label {
                id: messageText
                width: parent.width
                text: root.message
                wrapMode: Text.WordWrap
                elide: Text.ElideNone
            }
        }
        RowLayout {
            Layout.alignment: Qt.AlignRight
            Ui.Button {
                id: cancel
                text: "Cancel"
                focusable: true
                bordered: true
                onClicked: root.close()
            }
            Ui.Button {
                text: "Confirm"
                foreground: Color.urgent
                focusable: true
                onClicked: {
                    root.close();
                    root.confirmed();
                }
            }
        }
    }
}
