import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: savedDevicesView
    color: themePalette.background

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Metrics.spacingLg
        spacing: Metrics.spacingMd

        Label {
            text: "Saved Remote Host Devices"
            font.family: Typography.fontFamily
            font.pixelSize: Typography.fontHeader
            font.weight: Typography.weightBold
            color: themePalette.textPrimary
            Accessible.role: Accessible.Heading
            Accessible.name: "Saved Devices Title"
        }

        Label {
            text: "Directory of saved desktop agents and control plane registered devices (Milestone 8)."
            font.family: Typography.fontFamily
            font.pixelSize: Typography.fontBody
            color: themePalette.textSecondary
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: themePalette.surface
            radius: Metrics.radiusSm
            border.color: themePalette.border

            ListView {
                anchors.fill: parent
                anchors.margins: Metrics.spacingMd
                clip: true
                model: [
                    { name: "Local Linux Headless Host Agent", address: "127.0.0.1:18443", status: "Online", platform: "Linux (X11)" },
                    { name: "Production Gateway Agent #1", address: "192.168.1.100:18443", status: "Offline", platform: "Windows Server" },
                    { name: "Dev Workstation (macOS M2)", address: "10.0.0.15:18443", status: "Standby", platform: "macOS" }
                ]

                delegate: ItemDelegate {
                    width: ListView.view.width
                    height: 60

                    contentItem: RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Metrics.spacingSm
                        anchors.rightMargin: Metrics.spacingSm

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Label { text: modelData.name; font.weight: Typography.weightBold; color: themePalette.textPrimary }
                            Label { text: modelData.address + " • " + modelData.platform; font.pixelSize: Typography.fontCaption; color: themePalette.textSecondary }
                        }

                        Label {
                            text: modelData.status
                            font.weight: Typography.weightBold
                            color: modelData.status === "Online" ? themePalette.success : themePalette.textSecondary
                            Layout.preferredWidth: 80
                        }

                        Button {
                            text: "Connect"
                            enabled: modelData.status === "Online"
                            onClicked: sessionClient.connectToHost("127.0.0.1", 18443)
                        }
                    }
                }
            }
        }
    }
}
