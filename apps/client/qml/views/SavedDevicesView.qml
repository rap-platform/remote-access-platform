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

        // Saved Devices Card Container
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 210
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
                    height: 52
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
                            Layout.preferredHeight: 30
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

        // Section Title: Recent Connection History Log
        RowLayout {
            Layout.fillWidth: true
            spacing: Metrics.spacingSm

            Label {
                text: "📜 Recent Connection Audit Log"
                font.family: Typography.fontFamily
                font.pixelSize: Typography.fontSubheader
                font.weight: Typography.weightBold
                color: themePalette.textPrimary
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "🗑️ Clear Log"
                Layout.preferredHeight: 28
                font.family: Typography.fontFamily
                font.pixelSize: Typography.fontCaption
                onClicked: sessionClient.clearConnectionHistory()
                background: Rectangle {
                    color: parent.hovered ? themePalette.surfaceVariant : themePalette.surface
                    radius: Metrics.radiusSm
                    border.color: themePalette.border
                }
            }
        }

        // Connection History Table Container
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: themePalette.surface
            radius: Metrics.radiusSm
            border.color: themePalette.border

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Metrics.spacingSm
                spacing: Metrics.spacingXs

                // Table Header
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    color: themePalette.surfaceVariant
                    radius: Metrics.radiusSm

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Metrics.spacingMd
                        anchors.rightMargin: Metrics.spacingMd

                        Label { text: "Timestamp"; font.weight: Typography.weightBold; color: themePalette.textSecondary; Layout.preferredWidth: 140 }
                        Label { text: "Remote Target"; font.weight: Typography.weightBold; color: themePalette.textSecondary; Layout.fillWidth: true }
                        Label { text: "Duration"; font.weight: Typography.weightBold; color: themePalette.textSecondary; Layout.preferredWidth: 90 }
                        Label { text: "Disconnect Reason"; font.weight: Typography.weightBold; color: themePalette.textSecondary; Layout.preferredWidth: 160 }
                        Label { text: "Action"; font.weight: Typography.weightBold; color: themePalette.textSecondary; Layout.preferredWidth: 90 }
                    }
                }

                // Table Rows
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: sessionClient.connectionHistory

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 38
                        color: index % 2 === 0 ? themePalette.surface : themePalette.surfaceVariant
                        border.color: themePalette.border
                        border.width: 0.5

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Metrics.spacingMd
                            anchors.rightMargin: Metrics.spacingMd

                            Label {
                                text: modelData.timestamp
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.fontCaption
                                color: themePalette.textSecondary
                                Layout.preferredWidth: 140
                            }

                            Label {
                                text: modelData.target
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.fontCaption
                                font.weight: Typography.weightBold
                                color: themePalette.textPrimary
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Label {
                                text: modelData.duration
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.fontCaption
                                color: themePalette.textSecondary
                                Layout.preferredWidth: 90
                            }

                            Label {
                                text: modelData.reason
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.fontCaption
                                color: modelData.reason.includes("Network") ? themePalette.warning || "#FFC107" : themePalette.textSecondary
                                Layout.preferredWidth: 160
                            }

                            Button {
                                text: "Reconnect"
                                Layout.preferredWidth: 80
                                Layout.preferredHeight: 26
                                font.family: Typography.fontFamily
                                font.pixelSize: 11
                                onClicked: sessionClient.connectToHost("127.0.0.1", 18443)
                                background: Rectangle {
                                    color: themePalette.primary
                                    radius: Metrics.radiusSm
                                }
                                contentItem: Text {
                                    text: parent.text
                                    font: parent.font
                                    color: "#FFFFFF"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

