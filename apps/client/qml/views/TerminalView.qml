import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: terminalView
    color: "#0E1117"  // Deep dark console background

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Metrics.spacingMd
        spacing: Metrics.spacingSm

        // Terminal Header Bar
        RowLayout {
            Layout.fillWidth: true
            spacing: Metrics.spacingSm

            Label {
                text: "🖥️ Remote PTY Terminal Shell"
                font.family: Typography.fontFamily
                font.pixelSize: Typography.fontSubheader
                font.weight: Typography.weightBold
                color: "#4CAF50"
            }

            Rectangle {
                Layout.preferredWidth: 90
                Layout.preferredHeight: 22
                radius: 4
                color: Qt.rgba(0.0, 0.8, 0.4, 0.15)
                border.color: "#4CAF50"

                Label {
                    anchors.centerIn: parent
                    text: sessionClient.isConnected ? "🟢 ONLINE" : "🔴 OFFLINE"
                    font.pixelSize: 10
                    font.weight: Typography.weightBold
                    color: sessionClient.isConnected ? "#4CAF50" : "#F44336"
                }
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "🧹 Clear"
                Layout.preferredHeight: 28
                font.family: Typography.fontFamily
                font.pixelSize: Typography.fontCaption
                onClicked: sessionClient.clearTerminal()
                background: Rectangle { color: "#1E222D"; radius: Metrics.radiusSm; border.color: "#30363D" }
                contentItem: Text { text: parent.text; color: "#C9D1D9"; font: parent.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }

            Button {
                text: "📋 Copy Output"
                Layout.preferredHeight: 28
                font.family: Typography.fontFamily
                font.pixelSize: Typography.fontCaption
                onClicked: {
                    sessionClient.sendClipboardText(sessionClient.terminalOutput)
                    if (typeof mainWindow !== "undefined" && typeof mainWindow.showToast === "function") {
                        mainWindow.showToast("Terminal output copied to clipboard", "info")
                    }
                }
                background: Rectangle { color: "#1E222D"; radius: Metrics.radiusSm; border.color: "#30363D" }
                contentItem: Text { text: parent.text; color: "#C9D1D9"; font: parent.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
        }

        // Terminal Output Screen Container
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#161B22"
            radius: Metrics.radiusSm
            border.color: "#30363D"

            ScrollView {
                id: termScrollView
                anchors.fill: parent
                anchors.margins: Metrics.spacingSm
                clip: true

                TextArea {
                    id: termArea
                    readOnly: true
                    text: sessionClient.terminalOutput
                    font.family: "Consolas, Courier New, monospace"
                    font.pixelSize: 13
                    color: "#58A6FF"
                    wrapMode: TextEdit.WrapAnywhere
                    selectByMouse: true
                    background: null

                    onTextChanged: {
                        termArea.cursorPosition = termArea.length
                    }
                }
            }
        }

        // Quick Command Preset Pills
        RowLayout {
            Layout.fillWidth: true
            spacing: Metrics.spacingXs

            Label { text: "Presets:"; font.family: Typography.fontFamily; font.pixelSize: 11; color: "#8B949E" }

            Repeater {
                model: ["uname -a", "whoami", "uptime", "free -h", "ps aux", "help"]

                delegate: Button {
                    text: modelData
                    Layout.preferredHeight: 24
                    font.family: "Consolas, monospace"
                    font.pixelSize: 11
                    onClicked: sessionClient.sendTerminalInput(modelData)
                    background: Rectangle { color: parent.hovered ? "#21262D" : "#161B22"; radius: 3; border.color: "#30363D" }
                    contentItem: Text { text: parent.text; color: "#8B949E"; font: parent.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
            }
        }

        // Command Prompt Input Line
        RowLayout {
            Layout.fillWidth: true
            spacing: Metrics.spacingSm

            Label {
                text: "root@rap-agent:~$"
                font.family: "Consolas, monospace"
                font.pixelSize: 13
                font.weight: Font.Bold
                color: "#4CAF50"
            }

            TextField {
                id: cmdInput
                Layout.fillWidth: true
                placeholderText: "Enter command and press Enter..."
                font.family: "Consolas, Courier New, monospace"
                font.pixelSize: 13
                color: "#F0F6FC"
                selectByMouse: true
                onAccepted: {
                    if (text.trim().length > 0) {
                        sessionClient.sendTerminalInput(text.trim())
                        text = ""
                    }
                }
                background: Rectangle {
                    color: "#161B22"
                    border.color: cmdInput.activeFocus ? "#58A6FF" : "#30363D"
                    radius: Metrics.radiusSm
                }
            }

            Button {
                text: "Send ➔"
                Layout.preferredHeight: 34
                font.family: Typography.fontFamily
                font.pixelSize: Typography.fontCaption
                font.weight: Typography.weightBold
                onClicked: {
                    if (cmdInput.text.trim().length > 0) {
                        sessionClient.sendTerminalInput(cmdInput.text.trim())
                        cmdInput.text = ""
                    }
                }
                background: Rectangle { color: "#238636"; radius: Metrics.radiusSm }
                contentItem: Text { text: parent.text; color: "#FFFFFF"; font: parent.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
        }
    }
}
