import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"
import "../components"

Rectangle {
    id: securityKeysView
    color: themePalette.background

    IncomingConnectionDialog {
        id: testIncomingDialog
        onAcceptedWithPermissions: (mask) => {
            securityStatusLabel.text = "Last Test Authorization: APPROVED (Permissions Mask: 0x" + mask.toString(16).toUpperCase() + ")";
        }
        onConnectionDenied: {
            securityStatusLabel.text = "Last Test Authorization: REJECTED by Host";
        }
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: parent.width

        ColumnLayout {
            width: parent.width - (Metrics.spacingLg * 2)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Metrics.spacingMd

            // Header Section
            Label {
                text: "Host Authorization & Security Permissions Center"
                font.family: Typography.fontFamily
                font.pixelSize: Typography.fontHeader
                font.weight: Typography.weightBold
                color: themePalette.textPrimary
                Accessible.role: Accessible.Heading
                Accessible.name: "Security & Permissions Center Title"
            }

            Label {
                text: "Configure host access control settings, unattended password policies, and test interactive connection dialog prompts."
                font.family: Typography.fontFamily
                font.pixelSize: Typography.fontBody
                color: themePalette.textSecondary
            }

            // Access Control Mode Card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 180
                color: themePalette.surface
                radius: Metrics.radiusSm
                border.color: themePalette.border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Metrics.spacingMd
                    spacing: Metrics.spacingSm

                    Label {
                        text: "Host Access Control Mode"
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.fontSubheader
                        font.weight: Typography.weightBold
                        color: themePalette.textPrimary
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Metrics.spacingSm

                        Button {
                            Layout.fillWidth: true
                            text: "🟢 Full Unattended Access"
                            highlighted: modeGroup.checkedButton === btnFull
                            id: btnFull
                            checkable: true
                            checked: true
                            Accessible.role: Accessible.Button
                            Accessible.name: "Select Full Unattended Access"
                        }

                        Button {
                            Layout.fillWidth: true
                            text: "🔒 OTP & Password Required"
                            highlighted: modeGroup.checkedButton === btnPassword
                            id: btnPassword
                            checkable: true
                            Accessible.role: Accessible.Button
                            Accessible.name: "Select Password Required Access"
                        }

                        Button {
                            Layout.fillWidth: true
                            text: "🙋 Prompt Host Confirmation"
                            highlighted: modeGroup.checkedButton === btnPrompt
                            id: btnPrompt
                            checkable: true
                            Accessible.role: Accessible.Button
                            Accessible.name: "Select Prompt Host Confirmation Access"
                        }

                        ButtonGroup {
                            id: modeGroup
                            buttons: [btnFull, btnPassword, btnPrompt]
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Metrics.spacingMd

                        Button {
                            text: "🔔 Test Incoming Authorization Dialog"
                            onClicked: testIncomingDialog.open()
                            background: Rectangle {
                                color: themePalette.accent
                                radius: Metrics.radiusSm
                            }
                            contentItem: Text {
                                text: parent.text
                                color: themePalette.textPrimary
                                font.family: Typography.fontFamily
                                font.weight: Typography.weightBold
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            Accessible.role: Accessible.Button
                            Accessible.name: "Launch Test Authorization Dialog"
                        }

                        Label {
                            id: securityStatusLabel
                            text: "Status: Host Security Service Active (Listening for Incoming Handshakes)"
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontCaption
                            color: themePalette.success
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // Default Permitted Capabilities Card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 160
                color: themePalette.surface
                radius: Metrics.radiusSm
                border.color: themePalette.border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Metrics.spacingMd
                    spacing: Metrics.spacingSm

                    Label {
                        text: "Default Session Permissions Matrix"
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.fontSubheader
                        font.weight: Typography.weightBold
                        color: themePalette.textPrimary
                    }

                    GridLayout {
                        columns: 2
                        columnSpacing: Metrics.spacingLg
                        rowSpacing: Metrics.spacingXs

                        CheckBox {
                            text: "Allow Keyboard & Mouse Control"
                            checked: true
                            Accessible.role: Accessible.CheckBox
                            Accessible.name: "Allow Mouse Keyboard Control"
                        }

                        CheckBox {
                            text: "Allow Bidirectional Clipboard Sync"
                            checked: true
                            Accessible.role: Accessible.CheckBox
                            Accessible.name: "Allow Clipboard Sync"
                        }

                        CheckBox {
                            text: "Allow Remote File Transfer Operations"
                            checked: true
                            Accessible.role: Accessible.CheckBox
                            Accessible.name: "Allow File Transfer"
                        }

                        CheckBox {
                            text: "Allow Session Control Actions (Ctrl+Alt+Del, Lock Workstation)"
                            checked: true
                            Accessible.role: Accessible.CheckBox
                            Accessible.name: "Allow Session Control Actions"
                        }
                    }
                }
            }

            // Cryptographic Cipher Details
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 130
                color: themePalette.surface
                radius: Metrics.radiusSm
                border.color: themePalette.border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Metrics.spacingMd
                    spacing: Metrics.spacingXs

                    Label { text: "Encryption Cipher: ChaCha20-Poly1305 AEAD (256-bit key)"; font.weight: Typography.weightBold; color: themePalette.success }
                    Label { text: "Key Agreement: X25519 ECDH Key Exchange"; color: themePalette.textPrimary }
                    Label { text: "Protocol Magic: RAP0 (0x52415030)"; color: themePalette.textSecondary }
                    Label { text: "Replay & Tamper Protection: Active (12-byte monotonic IV + 16-byte Poly1305 Tag)"; color: themePalette.textSecondary }
                }
            }

            // NAT Traversal Card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 130
                color: themePalette.surface
                radius: Metrics.radiusSm
                border.color: themePalette.border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Metrics.spacingMd
                    spacing: Metrics.spacingXs

                    Label { text: "NAT Traversal & ICE Connection Mode"; font.weight: Typography.weightBold; color: themePalette.textPrimary }
                    Label { text: "Active Mode: Direct Local / STUN UDP Hole Punching (Fallback to Stateless Relay)"; color: themePalette.textSecondary }
                    Label { text: "STUN Server: stun.l.google.com:19302 / RFC 5389 Binding Client"; color: themePalette.textSecondary }
                    Label { text: "Stateless Relay Endpoint: 127.0.0.1:18445 (Zero-Decryption E2E Preserved)"; color: themePalette.textSecondary }
                }
            }
        }
    }
}
