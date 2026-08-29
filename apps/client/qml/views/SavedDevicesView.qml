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
                spacing: Metrics.spacingSm
                delegate: Rectangle {
                    id: deviceCard
                    width: ListView.view.width
                    height: 68
                    color: cardHover.hovered ? themePalette.surfaceVariant : themePalette.surface
                    radius: Metrics.radiusSm
                    border.color: themePalette.border
                    border.width: 1

                    HoverHandler {
                        id: cardHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Metrics.spacingMd
                        anchors.rightMargin: Metrics.spacingMd
                        spacing: Metrics.spacingMd

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: modelData.name
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.fontBody
                                font.weight: Typography.weightBold
                                color: themePalette.textPrimary
                            }

                            Label {
                                text: modelData.address + " • " + modelData.platform
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.fontCaption
                                color: themePalette.textSecondary
                            }
                        }

                        // Status Tag Badge Pill
                        Rectangle {
                            Layout.preferredWidth: 84
                            Layout.preferredHeight: 26
                            radius: 13
                            color: modelData.status === "Online" ? Qt.rgba(0.0, 0.8, 0.4, 0.15) : Qt.rgba(0.5, 0.5, 0.5, 0.12)
                            border.color: modelData.status === "Online" ? themePalette.success : themePalette.border

                            Label {
                                anchors.centerIn: parent
                                text: modelData.status
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.fontCaption
                                font.weight: Typography.weightBold
                                color: modelData.status === "Online" ? themePalette.success : themePalette.textSecondary
                            }
                        }

                        Button {
                            id: btnConnectDevice
                            text: "Connect"
                            Layout.preferredWidth: 90
                            Layout.preferredHeight: 34
                            enabled: modelData.status === "Online"
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontCaption
                            font.weight: Typography.weightBold
                            onClicked: sessionClient.connectToHost("127.0.0.1", 18443)

                            HoverHandler {
                                cursorShape: btnConnectDevice.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            }

                            contentItem: Text {
                                text: btnConnectDevice.text
                                font: btnConnectDevice.font
                                color: btnConnectDevice.enabled ? "#FFFFFF" : themePalette.textSecondary
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            background: Rectangle {
                                color: !btnConnectDevice.enabled ? themePalette.surfaceVariant : (btnConnectDevice.hovered ? Qt.lighter(themePalette.primary, 1.1) : themePalette.primary)
                                radius: Metrics.radiusSm
                            }
                        }
                    }
                }
            }
        }
    }
}
