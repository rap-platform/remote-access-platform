import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Dialog {
    id: incomingConnectionDialog
    title: ""
    modal: true
    focus: true
    anchors.centerIn: Overlay.overlay
    width: 480
    height: 520
    closePolicy: Popup.NoAutoClose

    property string callerId: "115 604 669"
    property string callerDevice: "Remote Technician (Linux Workstation)"
    property string callerIp: "192.168.1.105"
    property int remainingSeconds: 30
    property int accessProfileIndex: 0 // 0: Full Access, 1: Standard, 2: Screen Share Only, 3: Custom

    signal acceptedWithPermissions(int accessMask)
    signal connectionDenied()

    Timer {
        id: countdownTimer
        interval: 1000
        running: incomingConnectionDialog.visible
        repeat: true
        onTriggered: {
            if (incomingConnectionDialog.remainingSeconds > 1) {
                incomingConnectionDialog.remainingSeconds -= 1;
            } else {
                incomingConnectionDialog.connectionDenied();
                incomingConnectionDialog.close();
            }
        }
    }

    background: Rectangle {
        color: themePalette.surface
        radius: Metrics.radiusMd
        border.color: themePalette.border
        border.width: 1
    }

    contentItem: ColumnLayout {
        spacing: Metrics.spacingMd
        anchors.margins: Metrics.spacingMd

        // Header Section
        RowLayout {
            Layout.fillWidth: true
            spacing: Metrics.spacingMd

            Rectangle {
                width: 48
                height: 48
                radius: 24
                color: themePalette.accent

                Label {
                    anchors.centerIn: parent
                    text: "💻"
                    font.pixelSize: 24
                }
            }

            ColumnLayout {
                spacing: 2

                Label {
                    text: "Incoming Connection Request"
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.fontSubheader
                    font.weight: Typography.weightBold
                    color: themePalette.textPrimary
                    Accessible.role: Accessible.Heading
                    Accessible.name: "Incoming Connection Dialog Header"
                }

                Label {
                    text: "Device ID: " + incomingConnectionDialog.callerId + " (" + incomingConnectionDialog.callerIp + ")"
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.fontCaption
                    color: themePalette.textSecondary
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: themePalette.border
        }

        // Caller Info Card
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            color: themePalette.background
            radius: Metrics.radiusSm
            border.color: themePalette.border

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Metrics.spacingMd
                anchors.rightMargin: Metrics.spacingMd

                Label {
                    text: "Requesting Remote Control of your Desktop"
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.fontBody
                    color: themePalette.textPrimary
                    Layout.fillWidth: true
                }

                Label {
                    text: incomingConnectionDialog.remainingSeconds + "s"
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.fontSubheader
                    font.weight: Typography.weightBold
                    color: themePalette.danger
                }
            }
        }

        // Access Level Preset Selector
        Label {
            text: "Select Granted Access Profile:"
            font.family: Typography.fontFamily
            font.pixelSize: Typography.fontCaption
            font.weight: Typography.weightBold
            color: themePalette.textSecondary
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Metrics.spacingSm

            Button {
                id: btnProfileFull
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                text: "🟢 Full Access"
                highlighted: incomingConnectionDialog.accessProfileIndex === 0
                onClicked: {
                    incomingConnectionDialog.accessProfileIndex = 0;
                    chkInput.checked = true;
                    chkClipboard.checked = true;
                    chkFileTransfer.checked = true;
                    chkSystemControl.checked = true;
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                Accessible.role: Accessible.Button
                Accessible.name: "Select Full Access Profile"
            }

            Button {
                id: btnProfileStd
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                text: "🟡 Standard"
                highlighted: incomingConnectionDialog.accessProfileIndex === 1
                onClicked: {
                    incomingConnectionDialog.accessProfileIndex = 1;
                    chkInput.checked = true;
                    chkClipboard.checked = true;
                    chkFileTransfer.checked = false;
                    chkSystemControl.checked = false;
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                Accessible.role: Accessible.Button
                Accessible.name: "Select Standard Access Profile"
            }

            Button {
                id: btnProfileScreen
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                text: "🔵 Screen Only"
                highlighted: incomingConnectionDialog.accessProfileIndex === 2
                onClicked: {
                    incomingConnectionDialog.accessProfileIndex = 2;
                    chkInput.checked = false;
                    chkClipboard.checked = false;
                    chkFileTransfer.checked = false;
                    chkSystemControl.checked = false;
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                Accessible.role: Accessible.Button
                Accessible.name: "Select Screen Share Only Profile"
            }
        }

        // Detailed Granular Permission Toggles
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Metrics.spacingXs

            CheckBox {
                id: chkInput
                text: "Allow Keyboard & Mouse Control"
                checked: true
                onCheckedChanged: incomingConnectionDialog.accessProfileIndex = 3
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                Accessible.role: Accessible.CheckBox
                Accessible.name: "Toggle Remote Input Permission"
            }

            CheckBox {
                id: chkClipboard
                text: "Allow Shared Clipboard Sync"
                checked: true
                onCheckedChanged: incomingConnectionDialog.accessProfileIndex = 3
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                Accessible.role: Accessible.CheckBox
                Accessible.name: "Toggle Clipboard Sync Permission"
            }

            CheckBox {
                id: chkFileTransfer
                text: "Allow File Manager Access & Transfer"
                checked: true
                onCheckedChanged: incomingConnectionDialog.accessProfileIndex = 3
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                Accessible.role: Accessible.CheckBox
                Accessible.name: "Toggle File Transfer Permission"
            }

            CheckBox {
                id: chkSystemControl
                text: "Allow System Actions (Lock Workstation, Ctrl+Alt+Del)"
                checked: true
                onCheckedChanged: incomingConnectionDialog.accessProfileIndex = 3
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                Accessible.role: Accessible.CheckBox
                Accessible.name: "Toggle System Control Permission"
            }
        }

        Item { Layout.fillHeight: true }

        // Action Buttons: Accept / Deny
        RowLayout {
            Layout.fillWidth: true
            spacing: Metrics.spacingMd

            Button {
                id: btnDeny
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                text: "❌ DENY / REJECT"
                onClicked: {
                    incomingConnectionDialog.connectionDenied();
                    incomingConnectionDialog.close();
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                background: Rectangle {
                    color: btnDeny.hovered ? Qt.darker(themePalette.danger, 1.15) : themePalette.danger
                    radius: Metrics.radiusSm
                }
                contentItem: Text {
                    text: btnDeny.text
                    color: themePalette.textPrimary
                    font.family: Typography.fontFamily
                    font.weight: Typography.weightBold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                Accessible.role: Accessible.Button
                Accessible.name: "Deny Connection Request"
            }

            Button {
                id: btnAccept
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                text: "✅ ACCEPT CONNECTION"
                onClicked: {
                    let mask = (chkInput.checked ? 1 : 0) |
                               (chkClipboard.checked ? 2 : 0) |
                               (chkFileTransfer.checked ? 4 : 0) |
                               (chkSystemControl.checked ? 8 : 0);
                    incomingConnectionDialog.acceptedWithPermissions(mask);
                    incomingConnectionDialog.close();
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                background: Rectangle {
                    color: btnAccept.hovered ? Qt.lighter(themePalette.success, 1.15) : themePalette.success
                    radius: Metrics.radiusSm
                }
                contentItem: Text {
                    text: btnAccept.text
                    color: themePalette.textPrimary
                    font.family: Typography.fontFamily
                    font.weight: Typography.weightBold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                Accessible.role: Accessible.Button
                Accessible.name: "Accept Connection Request"
            }
        }
    }
}
