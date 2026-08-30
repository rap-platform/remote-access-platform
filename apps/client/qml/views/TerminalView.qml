import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: terminalView
    color: themePalette.background

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
                color: themePalette.success
            }

            Rectangle {
                Layout.preferredWidth: 90
                Layout.preferredHeight: 22
                radius: 4
                color: Qt.rgba(themePalette.success.r, themePalette.success.g, themePalette.success.b, 0.15)
                border.color: themePalette.success

                Label {
                    anchors.centerIn: parent
                    text: sessionClient.isConnected ? "🟢 ONLINE" : "🔴 OFFLINE"
                    font.pixelSize: 10
                    font.weight: Typography.weightBold
                    color: sessionClient.isConnected ? themePalette.success : themePalette.error
                }
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "🧹 Clear"
                Layout.preferredHeight: 28
                font.family: Typography.fontFamily
                font.pixelSize: Typography.fontCaption
                onClicked: sessionClient.clearTerminal()
                background: Rectangle { color: themePalette.surface; radius: Metrics.radiusSm; border.color: themePalette.border }
                contentItem: Text { text: parent.text; color: themePalette.textPrimary; font: parent.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
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
                background: Rectangle { color: themePalette.surface; radius: Metrics.radiusSm; border.color: themePalette.border }
                contentItem: Text { text: parent.text; color: themePalette.textPrimary; font: parent.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
        }

        // Terminal Output Screen Container
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: themePalette.surface
            radius: Metrics.radiusSm
            border.color: themePalette.border

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
                    color: themePalette.primary
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

            Label { text: "Presets:"; font.family: Typography.fontFamily; font.pixelSize: 11; color: themePalette.textSecondary }

            Repeater {
                model: ["uname -a", "whoami", "uptime", "free -h", "ps aux", "help"]

                delegate: Button {
                    text: modelData
                    Layout.preferredHeight: 24
                    font.family: "Consolas, monospace"
                    font.pixelSize: 11
                    onClicked: sessionClient.sendTerminalInput(modelData)
                    background: Rectangle { color: parent.hovered ? themePalette.surfaceVariant : themePalette.surface; radius: 3; border.color: themePalette.border }
                    contentItem: Text { text: parent.text; color: themePalette.textSecondary; font: parent.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
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
                color: themePalette.success
            }

            TextField {
                id: cmdInput
                Layout.fillWidth: true
                placeholderText: "Enter command and press Enter..."
                font.family: "Consolas, Courier New, monospace"
                font.pixelSize: 13
                color: themePalette.textPrimary
                selectByMouse: true
                onAccepted: {
                    if (text.trim().length > 0) {
                        sessionClient.sendTerminalInput(text.trim())
                        text = ""
                    }
                }
                background: Rectangle {
                    color: themePalette.surface
                    border.color: cmdInput.activeFocus ? themePalette.primary : themePalette.border
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
                background: Rectangle { color: themePalette.primary; radius: Metrics.radiusSm }
                contentItem: Text { text: parent.text; color: themePalette.textPrimary; font: parent.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
            }
        }
    }
}
