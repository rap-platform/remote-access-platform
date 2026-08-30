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

            // IP Whitelist / Blacklist Access Control Card (Sprint 3)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 220
                color: themePalette.surface
                radius: Metrics.radiusSm
                border.color: themePalette.border

                ListModel {
                    id: ipRulesModel
                    ListElement { ipAddress: "192.168.1.0/24"; ruleType: "ALLOW"; description: "Local Subnet" }
                    ListElement { ipAddress: "10.0.0.5"; ruleType: "ALLOW"; description: "Admin Workstation" }
                    ListElement { ipAddress: "203.0.113.42"; ruleType: "DENY"; description: "Blocked Suspicious IP" }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Metrics.spacingMd
                    spacing: Metrics.spacingSm

                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            text: "🛡️ IP Filtering & Access Control List (ACL)"
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontSubheader
                            font.weight: Typography.weightBold
                            color: themePalette.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        ComboBox {
                            id: ipFilterMode
                            Layout.preferredWidth: 160
                            model: ["Allow All (Default)", "Whitelist Only", "Blacklist Only"]
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontCaption
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Metrics.spacingSm

                        TextField {
                            id: newIpInput
                            placeholderText: "Enter IP or CIDR (e.g. 192.168.1.100 or 10.0.0.0/16)"
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontCaption
                            color: themePalette.textPrimary
                            Layout.fillWidth: true
                            background: Rectangle { color: themePalette.surfaceVariant; radius: Metrics.radiusSm; border.color: themePalette.border }
                        }

                        ComboBox {
                            id: newIpType
                            Layout.preferredWidth: 100
                            model: ["ALLOW", "DENY"]
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontCaption
                        }

                        Button {
                            text: "➕ Add Rule"
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontCaption
                            font.weight: Typography.weightBold
                            onClicked: {
                                if (newIpInput.text.trim().length > 0) {
                                    ipRulesModel.append({
                                        ipAddress: newIpInput.text.trim(),
                                        ruleType: newIpType.currentText,
                                        description: "Custom Rule"
                                    })
                                    newIpInput.text = ""
                                    if (typeof mainWindow !== "undefined" && typeof mainWindow.showToast === "function") {
                                        mainWindow.showToast("IP Access Control rule added", "success")
                                    }
                                }
                            }
                            background: Rectangle { color: themePalette.primary; radius: Metrics.radiusSm }
                            contentItem: Text { text: parent.text; font: parent.font; color: themePalette.textPrimary; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        }
                    }

                    // Rule List View
                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: ipRulesModel
                        spacing: 4

                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 32
                            color: themePalette.surfaceVariant
                            radius: Metrics.radiusSm

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Metrics.spacingSm
                                anchors.rightMargin: Metrics.spacingSm

                                Rectangle {
                                    Layout.preferredWidth: 54
                                    Layout.preferredHeight: 20
                                    radius: 3
                                    color: model.ruleType === "ALLOW" ? Qt.rgba(0, 0.8, 0.4, 0.15) : Qt.rgba(0.9, 0.2, 0.2, 0.15)
                                    border.color: model.ruleType === "ALLOW" ? themePalette.success : themePalette.error

                                    Label {
                                        anchors.centerIn: parent
                                        text: model.ruleType
                                        font.pixelSize: 10
                                        font.weight: Typography.weightBold
                                        color: parent.border.color
                                    }
                                }

                                Label {
                                    text: model.ipAddress
                                    font.family: Typography.fontFamily
                                    font.pixelSize: Typography.fontCaption
                                    font.weight: Typography.weightBold
                                    color: themePalette.textPrimary
                                    Layout.preferredWidth: 160
                                }

                                Label {
                                    text: model.description
                                    font.family: Typography.fontFamily
                                    font.pixelSize: Typography.fontCaption
                                    color: themePalette.textSecondary
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: "✕"
                                    font.pixelSize: 12
                                    color: themePalette.textSecondary
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -4
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ipRulesModel.remove(index)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

