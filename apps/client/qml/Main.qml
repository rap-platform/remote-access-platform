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
    property int currentViewIndex: 0 // 0: Desktop Session, 1: Saved Devices, 2: Security & Keys

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

        // Main Workspace (Sidebar + Multi-View Stack)
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

                    // View 0: Desktop Session
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: Metrics.radiusSm
                        color: mainWindow.currentViewIndex === 0 ? themePalette.surfaceVariant : themePalette.surface

                        MouseArea {
                            anchors.fill: parent
                            onClicked: mainWindow.currentViewIndex = 0
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Metrics.spacingSm

                            Label {
                                text: "Desktop Session"
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.fontBody
                                font.weight: mainWindow.currentViewIndex === 0 ? Typography.weightBold : Typography.weightMedium
                                color: mainWindow.currentViewIndex === 0 ? themePalette.primary : themePalette.textPrimary
                            }
                        }
                    }

                    // View 1: Saved Devices (Milestone 8)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: Metrics.radiusSm
                        color: mainWindow.currentViewIndex === 1 ? themePalette.surfaceVariant : themePalette.surface

                        MouseArea {
                            anchors.fill: parent
                            onClicked: mainWindow.currentViewIndex = 1
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Metrics.spacingSm

                            Label {
                                text: "Saved Devices"
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.fontBody
                                font.weight: mainWindow.currentViewIndex === 1 ? Typography.weightBold : Typography.weightMedium
                                color: mainWindow.currentViewIndex === 1 ? themePalette.primary : themePalette.textSecondary
                            }
                        }
                    }

                    // View 2: Security & Keys (Milestone 5, 8 & 9)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: Metrics.radiusSm
                        color: mainWindow.currentViewIndex === 2 ? themePalette.surfaceVariant : themePalette.surface

                        MouseArea {
                            anchors.fill: parent
                            onClicked: mainWindow.currentViewIndex = 2
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Metrics.spacingSm

                            Label {
                                text: "Security & NAT Keys"
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.fontBody
                                font.weight: mainWindow.currentViewIndex === 2 ? Typography.weightBold : Typography.weightMedium
                                color: mainWindow.currentViewIndex === 2 ? themePalette.primary : themePalette.textSecondary
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            // Stacked View Content Container
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: mainWindow.currentViewIndex

                // Screen 0: Live Desktop Viewport
                Rectangle {
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

                // Screen 1: Control Plane Saved Devices (Milestone 8 UI Screen)
                Rectangle {
                    color: themePalette.background

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Metrics.spacingLg
                        spacing: Metrics.spacingMd

                        Label {
                            text: "Control Plane — Saved & Registered Devices"
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontTitle
                            font.weight: Typography.weightBold
                            color: themePalette.textPrimary
                        }

                        Label {
                            text: "Registered host agents and remote client devices discovered via Control Plane Identity Service."
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

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: Metrics.spacingMd

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Metrics.spacingLg

                                    Label { text: "Device ID"; font.weight: Typography.weightBold; color: themePalette.textPrimary; Layout.preferredWidth: 200 }
                                    Label { text: "Hostname"; font.weight: Typography.weightBold; color: themePalette.textPrimary; Layout.preferredWidth: 180 }
                                    Label { text: "OS Target"; font.weight: Typography.weightBold; color: themePalette.textPrimary; Layout.preferredWidth: 150 }
                                    Label { text: "Status"; font.weight: Typography.weightBold; color: themePalette.textPrimary; Layout.preferredWidth: 100 }
                                    Item { Layout.fillWidth: true }
                                }

                                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: themePalette.border }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Metrics.spacingLg

                                    Label { text: "rap-dev-7480-local"; color: themePalette.primary; Layout.preferredWidth: 200 }
                                    Label { text: "dell-latitude-7480"; color: themePalette.textPrimary; Layout.preferredWidth: 180 }
                                    Label { text: "Linux Ubuntu 24.04"; color: themePalette.textSecondary; Layout.preferredWidth: 150 }
                                    Label { text: "Online"; color: themePalette.success; font.weight: Typography.weightBold; Layout.preferredWidth: 100 }
                                    Button {
                                        text: "Connect P2P"
                                        onClicked: sessionClient.connectToHost("127.0.0.1", 18443)
                                    }
                                }

                                Item { Layout.fillHeight: true }
                            }
                        }
                    }
                }

                // Screen 2: Security & NAT Keys Audit Screen (Milestone 5, 8 & 9 UI Screen)
                Rectangle {
                    color: themePalette.background

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Metrics.spacingLg
                        spacing: Metrics.spacingMd

                        Label {
                            text: "Security, Encryption & NAT Traversal Audit"
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontTitle
                            font.weight: Typography.weightBold
                            color: themePalette.textPrimary
                        }

                        Label {
                            text: "Real-time state for ChaCha20-Poly1305 AEAD cipher, X25519 ECDH key exchange, and STUN/ICE NAT connection mode."
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontBody
                            color: themePalette.textSecondary
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 140
                            color: themePalette.surface
                            radius: Metrics.radiusSm
                            border.color: themePalette.border

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: Metrics.spacingMd
                                spacing: Metrics.spacingSm

                                Label { text: "Encryption Cipher: ChaCha20-Poly1305 AEAD (256-bit key)"; font.weight: Typography.weightBold; color: themePalette.success }
                                Label { text: "Key Agreement: X25519 ECDH Key Exchange"; color: themePalette.textPrimary }
                                Label { text: "Protocol Magic: RAP0 (0x52415030)"; color: themePalette.textSecondary }
                                Label { text: "Replay & Tamper Protection: Active (12-byte monotonic IV + 16-byte Poly1305 Tag)"; color: themePalette.textSecondary }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: themePalette.surface
                            radius: Metrics.radiusSm
                            border.color: themePalette.border

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: Metrics.spacingMd
                                spacing: Metrics.spacingSm

                                Label { text: "NAT Traversal & ICE Connection Mode"; font.weight: Typography.weightBold; color: themePalette.textPrimary }
                                Label { text: "Active Mode: Direct Local / STUN UDP Hole Punching (Fallback to Stateless Relay)"; color: themePalette.textSecondary }
                                Label { text: "STUN Server: stun.l.google.com:19302 / RFC 5389 Binding Client"; color: themePalette.textSecondary }
                                Label { text: "Stateless Relay Endpoint: 127.0.0.1:18445 (Zero-Decryption E2E Preserved)"; color: themePalette.textSecondary }
                                Item { Layout.fillHeight: true }
                            }
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
                    text: "v0.3.0-dev (Phase 3 Complete)"
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.fontCaption
                    color: themePalette.textSecondary
                }
            }
        }
    }
}
