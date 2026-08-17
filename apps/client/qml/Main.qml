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

    // Design System Instantiated Component Objects
    Palette { id: palette }
    Typography { id: typography }
    Metrics { id: metrics }

    color: palette.background
    property int frameCounter: 0

    Connections {
        target: frameProvider
        function onFrameReady() {
            mainWindow.frameCounter++
            videoSurface.source = "image://frameprovider/current?" + mainWindow.frameCounter
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Top Navigation Bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: palette.surface
            border.color: palette.border
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: metrics.spacingLg
                anchors.rightMargin: metrics.spacingLg
                spacing: metrics.spacingMd

                Label {
                    text: "Remote Access Platform"
                    font.family: typography.fontFamily
                    font.pixelSize: typography.fontSubtitle
                    font.weight: typography.weightBold
                    color: palette.textPrimary
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    Layout.topMargin: metrics.spacingSm
                    Layout.bottomMargin: metrics.spacingSm
                    color: palette.border
                }

                TextField {
                    id: remoteIdInput
                    Layout.preferredWidth: 280
                    text: "127.0.0.1:18443"
                    placeholderText: "127.0.0.1:18443"
                    font.family: typography.fontFamily
                    font.pixelSize: typography.fontBody
                    color: palette.textPrimary
                    background: Rectangle {
                        color: palette.surfaceVariant
                        radius: metrics.radiusSm
                        border.color: palette.border
                    }
                }

                Button {
                    id: connectButton
                    text: sessionClient.isConnected ? "Disconnect" : "Connect Session"
                    font.family: typography.fontFamily
                    font.pixelSize: typography.fontBody
                    font.weight: typography.weightMedium
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
                        color: palette.textPrimary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: sessionClient.isConnected ? palette.error : palette.primary
                        radius: metrics.radiusSm
                    }
                }

                Item { Layout.fillWidth: true }

                // Theme Switcher Selector
                Label {
                    text: "Theme:"
                    font.family: typography.fontFamily
                    font.pixelSize: typography.fontCaption
                    font.weight: typography.weightMedium
                    color: palette.textSecondary
                }

                ComboBox {
                    id: themeSelector
                    model: ["Catppuccin Dark", "Tokyo Night", "Nordic Frost", "GitHub Dark", "Enterprise Light"]
                    currentIndex: palette.currentTheme
                    font.family: typography.fontFamily
                    font.pixelSize: typography.fontCaption
                    onCurrentIndexChanged: {
                        palette.setTheme(currentIndex)
                    }
                    contentItem: Text {
                        text: themeSelector.displayText
                        font: themeSelector.font
                        color: palette.textPrimary
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: metrics.spacingSm
                    }
                    background: Rectangle {
                        color: palette.surfaceVariant
                        radius: metrics.radiusSm
                        border.color: palette.border
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 12
                    Layout.preferredHeight: 12
                    radius: metrics.radiusFull
                    color: sessionClient.isConnected ? palette.success : palette.warning
                }

                Label {
                    text: sessionClient.isConnected ? "Session Active" : "Agent Ready"
                    font.family: typography.fontFamily
                    font.pixelSize: typography.fontCaption
                    color: palette.textSecondary
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
                color: palette.surface
                border.color: palette.border
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: metrics.spacingMd
                    spacing: metrics.spacingSm

                    Label {
                        text: "NAVIGATION"
                        font.family: typography.fontFamily
                        font.pixelSize: typography.fontCaption
                        font.weight: typography.weightBold
                        color: palette.textSecondary
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: metrics.radiusSm
                        color: palette.surfaceVariant

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: metrics.spacingSm

                            Label {
                                text: "Desktop Session"
                                font.family: typography.fontFamily
                                font.pixelSize: typography.fontBody
                                font.weight: typography.weightMedium
                                color: palette.primary
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: metrics.radiusSm
                        color: palette.surface

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: metrics.spacingSm

                            Label {
                                text: "Saved Devices"
                                font.family: typography.fontFamily
                                font.pixelSize: typography.fontBody
                                color: palette.textSecondary
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: metrics.radiusSm
                        color: palette.surface

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: metrics.spacingSm

                            Label {
                                text: "Security & Keys"
                                font.family: typography.fontFamily
                                font.pixelSize: typography.fontBody
                                color: palette.textSecondary
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
                color: palette.background

                Image {
                    id: videoSurface
                    anchors.fill: parent
                    anchors.margins: metrics.spacingMd
                    fillMode: Image.PreserveAspectFit
                    source: "image://frameprovider/current"
                    cache: false

                    Rectangle {
                        anchors.fill: parent
                        border.color: palette.border
                        border.width: 1
                        color: palette.transparent
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: metrics.spacingMd
                        visible: !sessionClient.isConnected

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "No Active Remote Stream"
                            font.family: typography.fontFamily
                            font.pixelSize: typography.fontTitle
                            font.weight: typography.weightBold
                            color: palette.textPrimary
                        }

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Click 'Connect Session' above to start real-time desktop streaming"
                            font.family: typography.fontFamily
                            font.pixelSize: typography.fontBody
                            color: palette.textSecondary
                        }
                    }
                }
            }
        }

        // Bottom Status Bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            color: palette.surface
            border.color: palette.border
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: metrics.spacingMd
                anchors.rightMargin: metrics.spacingMd

                Label {
                    text: "Status: " + sessionClient.statusText + " | Active Theme: " + palette.currentThemeName
                    font.family: typography.fontFamily
                    font.pixelSize: typography.fontCaption
                    color: palette.textSecondary
                }

                Item { Layout.fillWidth: true }

                Label {
                    text: "v0.1.0-dev (Milestone 4)"
                    font.family: typography.fontFamily
                    font.pixelSize: typography.fontCaption
                    color: palette.textSecondary
                }
            }
        }
    }
}
