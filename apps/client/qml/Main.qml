import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "theme"

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 1280
    height: 800
    minimumWidth: 900
    minimumHeight: 600
    title: "Remote Access Platform — Enterprise Desktop Viewer"
    color: Palette.background

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Top Navigation Bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: Palette.surface
            border.color: Palette.border
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
                    color: Palette.textPrimary
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    Layout.topMargin: Metrics.spacingSm
                    Layout.bottomMargin: Metrics.spacingSm
                    color: Palette.border
                }

                TextField {
                    id: remoteIdInput
                    Layout.preferredWidth: 280
                    placeholderText: "Enter Remote Device ID (e.g. 192.168.1.50:18443)"
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.fontBody
                    color: Palette.textPrimary
                    background: Rectangle {
                        color: Palette.surfaceVariant
                        radius: Metrics.radiusSm
                        border.color: Palette.border
                    }
                }

                Button {
                    id: connectButton
                    text: "Connect Session"
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.fontBody
                    font.weight: Typography.weightMedium
                    contentItem: Text {
                        text: connectButton.text
                        font: connectButton.font
                        color: Palette.textPrimary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: Palette.primary
                        radius: Metrics.radiusSm
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: 12
                    Layout.preferredHeight: 12
                    radius: Metrics.radiusFull
                    color: Palette.success
                }

                Label {
                    text: "Agent Online"
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.fontCaption
                    color: Palette.textSecondary
                }
            }
        }

        // Main Workspace (Sidebar + Session Viewport)
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Left Navigation Sidebar
            Rectangle {
                Layout.preferredWidth: 220
                Layout.fillHeight: true
                color: Palette.surface
                border.color: Palette.border
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Metrics.spacingMd
                    spacing: Metrics.spacingSm

                    Label {
                        text: "NAVIGATION"
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.fontCaption
                        font.weight: Typography.weightBold
                        color: Palette.textSecondary
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: Metrics.radiusSm
                        color: Palette.surfaceVariant

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Metrics.spacingSm

                            Label {
                                text: "Desktop Session"
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.fontBody
                                font.weight: Typography.weightMedium
                                color: Palette.primary
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: Metrics.radiusSm
                        color: Palette.surface

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Metrics.spacingSm

                            Label {
                                text: "Saved Devices"
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.fontBody
                                color: Palette.textSecondary
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: Metrics.radiusSm
                        color: Palette.surface

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Metrics.spacingSm

                            Label {
                                text: "Security & Keys"
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.fontBody
                                color: Palette.textSecondary
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            // Session Viewport Surface
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Palette.background

                Image {
                    id: videoSurface
                    anchors.fill: parent
                    anchors.margins: Metrics.spacingMd
                    fillMode: Image.PreserveAspectFit
                    source: "image://frameprovider/current"
                    cache: false

                    Rectangle {
                        anchors.fill: parent
                        border.color: Palette.border
                        border.width: 1
                        color: Palette.transparent
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: Metrics.spacingMd
                        visible: videoSurface.status !== Image.Ready

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "No Active Remote Stream"
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontTitle
                            font.weight: Typography.weightBold
                            color: Palette.textPrimary
                        }

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Enter host agent address and click 'Connect Session'"
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontBody
                            color: Palette.textSecondary
                        }
                    }
                }
            }
        }

        // Bottom Status Bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            color: Palette.surface
            border.color: Palette.border
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Metrics.spacingMd
                anchors.rightMargin: Metrics.spacingMd

                Label {
                    text: "Transport: TCP Local MVP | Codec: RAW RGBA8888 | Latency: <1ms"
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.fontCaption
                    color: Palette.textSecondary
                }

                Item { Layout.fillWidth: true }

                Label {
                    text: "v0.1.0-dev (Milestone 4)"
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.fontCaption
                    color: Palette.textSecondary
                }
            }
        }
    }
}
