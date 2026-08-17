import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"
import "../components"

Rectangle {
    id: securityKeysView
    color: themePalette.background

    property string masterPassword: "admin123"
    property string dynamicOtp: "847291"
    property bool showPassword: false

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
                text: "Host Security & Permissions Settings Center"
                font.family: Typography.fontFamily
                font.pixelSize: Typography.fontHeader
                font.weight: Typography.weightBold
                color: themePalette.textPrimary
                Accessible.role: Accessible.Heading
                Accessible.name: "Security & Permissions Center Title"
            }

            Label {
                text: "Configure host access control settings, unattended access passwords, allowed remote permissions, and security cipher parameters."
                font.family: Typography.fontFamily
                font.pixelSize: Typography.fontBody
                color: themePalette.textSecondary
            }

            // Unattended Access & Password Configuration Card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 220
                color: themePalette.surface
                radius: Metrics.radiusSm
                border.color: themePalette.border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Metrics.spacingMd
                    spacing: Metrics.spacingSm

                    Label {
                        text: "🔑 Unattended Password & OTP Security Setup"
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.fontSubheader
                        font.weight: Typography.weightBold
                        color: themePalette.textPrimary
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Metrics.spacingMd

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Metrics.spacingXs

                            Label {
                                text: "Host Unattended Master Password:"
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.fontCaption
                                color: themePalette.textSecondary
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Metrics.spacingSm

                                TextField {
                                    id: pwdInput
                                    Layout.fillWidth: true
                                    text: securityKeysView.masterPassword
                                    echoMode: securityKeysView.showPassword ? TextField.Normal : TextField.Password
                                    placeholderText: "Enter host unattended password"
                                    Accessible.role: Accessible.EditableText
                                    Accessible.name: "Unattended Master Password Input"
                                }

                                Button {
                                    text: securityKeysView.showPassword ? "🙈 Hide" : "👁️ Show"
                                    onClicked: securityKeysView.showPassword = !securityKeysView.showPassword
                                    Accessible.role: Accessible.Button
                                    Accessible.name: "Toggle Password Visibility"
                                }

                                Button {
                                    text: "💾 Save Password"
                                    onClicked: {
                                        securityKeysView.masterPassword = pwdInput.text;
                                        securityStatusLabel.text = "Status: Unattended Master Password Updated Successfully!";
                                    }
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
                                    Accessible.name: "Save Unattended Master Password"
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.preferredWidth: 240
                            spacing: Metrics.spacingXs

                            Label {
                                text: "Dynamic One-Time Passcode (OTP):"
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.fontCaption
                                color: themePalette.textSecondary
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Metrics.spacingSm

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 38
                                    color: themePalette.background
                                    radius: Metrics.radiusSm
                                    border.color: themePalette.border

                                    Label {
                                        anchors.centerIn: parent
                                        text: securityKeysView.dynamicOtp
                                        font.family: Typography.fontFamily
                                        font.pixelSize: Typography.fontSubheader
                                        font.weight: Typography.weightBold
                                        color: themePalette.success
                                    }
                                }

                                Button {
                                    text: "🔄 New OTP"
                                    onClicked: {
                                        let newCode = Math.floor(100000 + Math.random() * 900000).toString();
                                        securityKeysView.dynamicOtp = newCode;
                                        securityStatusLabel.text = "Status: Generated New Dynamic OTP (" + newCode + ")";
                                    }
                                    Accessible.role: Accessible.Button
                                    Accessible.name: "Generate New Dynamic OTP"
                                }
                            }
                        }
                    }

                    Label {
                        text: "Remote clients must provide either the Unattended Master Password or the Dynamic OTP to establish encrypted connections."
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.fontCaption
                        color: themePalette.textSecondary
                    }
                }
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
                        text: "🛡️ Host Authorization Policy"
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
                            text: "🔒 OTP / Password Only"
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
                            text: "🔔 Launch Test Authorization Dialog Prompt"
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
                            text: "Status: Host Security Service Active & Enforcing Permissions"
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontCaption
                            color: themePalette.success
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // Permitted Capabilities Matrix Configuration Card
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
                        text: "⚙️ Granted Remote Permissions Matrix"
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
                            text: "Allow Remote Keyboard & Mouse Input Injection"
                            checked: true
                            Accessible.role: Accessible.CheckBox
                            Accessible.name: "Allow Mouse Keyboard Control"
                        }

                        CheckBox {
                            text: "Allow Bidirectional Shared Clipboard Synchronization"
                            checked: true
                            Accessible.role: Accessible.CheckBox
                            Accessible.name: "Allow Clipboard Sync"
                        }

                        CheckBox {
                            text: "Allow Remote File Manager Access & File Transfer"
                            checked: true
                            Accessible.role: Accessible.CheckBox
                            Accessible.name: "Allow File Transfer"
                        }

                        CheckBox {
                            text: "Allow Session Remote Actions (Ctrl+Alt+Del, Lock Workstation)"
                            checked: true
                            Accessible.role: Accessible.CheckBox
                            Accessible.name: "Allow Session Control Actions"
                        }

                        CheckBox {
                            text: "Allow Audio & Sound Streaming"
                            checked: true
                            Accessible.role: Accessible.CheckBox
                            Accessible.name: "Allow Audio Streaming"
                        }

                        CheckBox {
                            text: "Allow Host Remote System Reboot / Power Management"
                            checked: false
                            Accessible.role: Accessible.CheckBox
                            Accessible.name: "Allow System Reboot"
                        }
                    }
                }
            }

            // Cryptographic Cipher Details Card
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
