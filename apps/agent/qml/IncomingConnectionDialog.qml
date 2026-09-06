import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: incomingWindow
    title: "RAP Security - Incoming Remote Desktop Request"
    width: 440
    height: 320
    visible: true
    flags: Qt.Dialog | Qt.WindowStaysOnTopHint

    signal connectionAccepted(int permissions)
    signal connectionDenied()

    property string remotePeerId: "127.0.0.1"
    property int countdown: 30

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            incomingWindow.countdown -= 1
            if (incomingWindow.countdown <= 0) {
                incomingWindow.connectionDenied()
                incomingWindow.close()
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#1E1E2E"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            RowLayout {
                spacing: 10
                Label { text: "🔔"; font.pixelSize: 26 }
                ColumnLayout {
                    spacing: 2
                    Label {
                        text: "Incoming Connection Request"
                        font.pixelSize: 16
                        font.bold: true
                        color: "#F5E0DC"
                    }
                    Label {
                        text: "Remote Device: " + incomingWindow.remotePeerId
                        font.pixelSize: 12
                        color: "#BAC2DE"
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#45475A"
            }

            Label {
                text: "Choose permissions granted to remote operator:"
                font.pixelSize: 12
                color: "#A6ADC8"
            }

            CheckBox {
                id: allowControl
                text: "Allow Mouse & Keyboard Control"
                checked: true
                font.pixelSize: 12
                palette.text: "#CDD6F4"
            }

            CheckBox {
                id: allowClipboard
                text: "Allow Bidirectional Clipboard Sync"
                checked: true
                font.pixelSize: 12
                palette.text: "#CDD6F4"
            }

            CheckBox {
                id: allowFileTransfer
                text: "Allow Remote File Transfer"
                checked: true
                font.pixelSize: 12
                palette.text: "#CDD6F4"
            }

            Label {
                text: "Auto-denying connection in " + incomingWindow.countdown + " seconds..."
                font.pixelSize: 11
                color: "#F38BA8"
                Layout.alignment: Qt.AlignHCenter
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Button {
                    text: "⛔ Deny"
                    Layout.fillWidth: true
                    onClicked: {
                        incomingWindow.connectionDenied()
                        incomingWindow.close()
                    }
                    background: Rectangle {
                        color: "#F38BA8"
                        radius: 6
                    }
                }

                Button {
                    text: "✅ Accept Connection"
                    Layout.fillWidth: true
                    onClicked: {
                        let perm = 0
                        if (allowControl.checked) perm |= 1
                        if (allowClipboard.checked) perm |= 2
                        if (allowFileTransfer.checked) perm |= 4
                        incomingWindow.connectionAccepted(perm)
                        incomingWindow.close()
                    }
                    background: Rectangle {
                        color: "#A6E3A1"
                        radius: 6
                    }
                }
            }
        }
    }
}
