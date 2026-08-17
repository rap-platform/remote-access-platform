import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: headerBar
    Layout.fillWidth: true
    Layout.preferredHeight: 60
    color: themePalette.surface
    border.color: themePalette.border
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Metrics.spacingLg
        anchors.rightMargin: Metrics.spacingLg
        spacing: Metrics.spacingMd

        Label {
            text: "Remote Access Platform"
            font.family: Typography.fontFamily
            font.pixelSize: Typography.fontSubtitle
            font.weight: Typography.weightBold
            color: themePalette.textPrimary
            Accessible.role: Accessible.Heading
            Accessible.name: "Application Title"
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            Layout.topMargin: Metrics.spacingSm
            Layout.bottomMargin: Metrics.spacingSm
            color: themePalette.border
        }

        TextField {
            id: remoteIdInput
            Layout.preferredWidth: 280
            text: "127.0.0.1:18443"
            placeholderText: "127.0.0.1:18443"
            font.family: Typography.fontFamily
            font.pixelSize: Typography.fontBody
            color: themePalette.textPrimary
            Accessible.role: Accessible.EditableText
            Accessible.name: "Remote Host Address Input"
            Accessible.description: "Enter target host IP and TCP port number (e.g. 127.0.0.1:18443)"
            background: Rectangle {
                color: themePalette.surfaceVariant
                radius: Metrics.radiusSm
                border.color: themePalette.border
            }
        }

        Button {
            id: connectButton
            text: sessionClient.isConnected ? "Disconnect" : "Connect Session"
            font.family: Typography.fontFamily
            font.pixelSize: Typography.fontBody
            font.weight: Typography.weightMedium
            Accessible.role: Accessible.Button
            Accessible.name: sessionClient.isConnected ? "Disconnect Session" : "Connect Session"
            Accessible.description: "Initiates or terminates remote desktop stream connection"
            onClicked: {
                if (sessionClient.isConnected) {
                    sessionClient.disconnectFromHost()
                } else {
                    sessionClient.connectToHost("127.0.0.1", 18443)
                }
            }
            contentItem: Text {
                text: connectButton.text
                font: connectButton.font
                color: themePalette.textPrimary
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                color: sessionClient.isConnected ? themePalette.error : themePalette.primary
                radius: Metrics.radiusSm
            }
        }

        Item { Layout.fillWidth: true }

        Label {
            text: "Theme:"
            font.family: Typography.fontFamily
            font.pixelSize: Typography.fontCaption
            font.weight: Typography.weightMedium
            color: themePalette.textSecondary
            Accessible.role: Accessible.StaticText
            Accessible.name: "Theme Selector Label"
        }

        ComboBox {
            id: themeSelector
            model: ["Catppuccin Dark", "Tokyo Night", "Nordic Frost", "GitHub Dark", "Enterprise Light"]
            currentIndex: themePalette.currentTheme
            font.family: Typography.fontFamily
            font.pixelSize: Typography.fontCaption
            Accessible.role: Accessible.ComboBox
            Accessible.name: "Color Theme Selector"
            Accessible.description: "Select visual color theme palette for accessibility and appearance"
            onActivated: (index) => {
                themePalette.setTheme(index)
            }
            contentItem: Text {
                text: themeSelector.displayText
                font: themeSelector.font
                color: themePalette.textPrimary
                verticalAlignment: Text.AlignVCenter
                leftPadding: Metrics.spacingSm
            }
            background: Rectangle {
                color: themePalette.surfaceVariant
                radius: Metrics.radiusSm
                border.color: themePalette.border
            }
        }
    }
}
