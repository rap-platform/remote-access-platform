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
    color: themePalette.background

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

                // Theme Switcher Selector
                Label {
                    text: "Theme:"
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.fontCaption
                    font.weight: Typography.weightMedium
                    color: themePalette.textSecondary
                }

                ComboBox {
                    id: themeSelector
                    model: ["Catppuccin Dark", "Tokyo Night", "Nordic Frost", "GitHub Dark", "Enterprise Light"]
                    currentIndex: themePalette.currentTheme
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.fontCaption
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

                Rectangle {
                    Layout.preferredWidth: 12
                    Layout.preferredHeight: 12
                    radius: Metrics.radiusFull
                    color: sessionClient.isConnected ? themePalette.success : themePalette.warning
                }

                Label {
                    text: sessionClient.isConnected ? "Session Active" : "Agent Ready"
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.fontCaption
                    color: themePalette.textSecondary
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
                color: themePalette.surface
                border.color: themePalette.border
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
                        color: themePalette.textSecondary
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: Metrics.radiusSm
                        color: themePalette.surfaceVariant

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Metrics.spacingSm

                            Label {
                                text: "Desktop Session"
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.fontBody
                                font.weight: Typography.weightMedium
                                color: themePalette.primary
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: Metrics.radiusSm
                        color: themePalette.surface

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Metrics.spacingSm

                            Label {
                                text: "Saved Devices"
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.fontBody
                                color: themePalette.textSecondary
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: Metrics.radiusSm
                        color: themePalette.surface

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Metrics.spacingSm

                            Label {
                                text: "Security & Keys"
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.fontBody
                                color: themePalette.textSecondary
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
                color: themePalette.background

                Image {
                    id: videoSurface
                    anchors.fill: parent
                    anchors.margins: Metrics.spacingMd
                    fillMode: Image.PreserveAspectFit
                    source: "image://frameprovider/current"
                    cache: false

                    Rectangle {
                        anchors.fill: parent
                        border.color: themePalette.border
                        border.width: 1
                        color: themePalette.transparent
                    }

                    MouseArea {
                        id: viewportMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        focus: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                        onClicked: { viewportMouseArea.forceActiveFocus(); }

                        onPositionChanged: (mouse) => {
                            if (sessionClient.isConnected && width > 0 && height > 0) {
                                var normX = Math.round((mouse.x / width) * 1920);
                                var normY = Math.round((mouse.y / height) * 1080);
                                sessionClient.sendInputEvent(1, normX, normY, 0, 0, 0, 0);
                            }
                        }
                        onPressed: (mouse) => {
                            viewportMouseArea.forceActiveFocus();
                            if (sessionClient.isConnected && width > 0 && height > 0) {
                                var normX = Math.round((mouse.x / width) * 1920);
                                var normY = Math.round((mouse.y / height) * 1080);
                                var btn = (mouse.button === Qt.LeftButton) ? 1 : ((mouse.button === Qt.RightButton) ? 3 : 2);
                                sessionClient.sendInputEvent(2, normX, normY, btn, 0, 0, 0);
                            }
                        }
                        onReleased: (mouse) => {
                            if (sessionClient.isConnected && width > 0 && height > 0) {
                                var normX = Math.round((mouse.x / width) * 1920);
                                var normY = Math.round((mouse.y / height) * 1080);
                                var btn = (mouse.button === Qt.LeftButton) ? 1 : ((mouse.button === Qt.RightButton) ? 3 : 2);
                                sessionClient.sendInputEvent(3, normX, normY, btn, 0, 0, 0);
                            }
                        }
                        onWheel: (wheel) => {
                            if (sessionClient.isConnected) {
                                sessionClient.sendInputEvent(4, 0, 0, 0, wheel.angleDelta.y, 0, 0);
                            }
                        }
                        Keys.onPressed: (event) => {
                            if (sessionClient.isConnected) {
                                sessionClient.sendInputEvent(5, 0, 0, 0, 0, event.nativeScanCode || event.key, event.modifiers);
                                event.accepted = true;
                            }
                        }
                        Keys.onReleased: (event) => {
                            if (sessionClient.isConnected) {
                                sessionClient.sendInputEvent(6, 0, 0, 0, 0, event.nativeScanCode || event.key, event.modifiers);
                                event.accepted = true;
                            }
                        }
                    }



                    Column {
                        anchors.centerIn: parent
                        spacing: Metrics.spacingMd
                        visible: !sessionClient.isConnected

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "No Active Remote Stream"
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontTitle
                            font.weight: Typography.weightBold
                            color: themePalette.textPrimary
                        }

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Click 'Connect Session' above to start real-time desktop streaming"
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontBody
                            color: themePalette.textSecondary
                        }
                    }
                }
            }
        }

        // Bottom Status Bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            color: themePalette.surface
            border.color: themePalette.border
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Metrics.spacingMd
                anchors.rightMargin: Metrics.spacingMd

                Label {
                    text: "Status: " + sessionClient.statusText + " | Active Theme: " + themePalette.currentThemeName
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.fontCaption
                    color: themePalette.textSecondary
                }

                Item { Layout.fillWidth: true }

                Label {
                    text: "v0.1.0-dev (Milestone 4)"
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.fontCaption
                    color: themePalette.textSecondary
                }
            }
        }
    }
}
