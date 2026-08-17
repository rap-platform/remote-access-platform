import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: sidebarNav
    property int currentViewIndex: 0
    signal navigateTo(int index)

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
            Accessible.role: Accessible.Heading
            Accessible.name: "Navigation Menu"
        }

        // View 0: Desktop Session
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: Metrics.radiusSm
            color: sidebarNav.currentViewIndex === 0 ? themePalette.surfaceVariant : themePalette.surface
            Accessible.role: Accessible.Button
            Accessible.name: "Desktop Session View"
            Accessible.description: "Switches workspace view to live remote desktop interactive viewport"

            MouseArea {
                anchors.fill: parent
                onClicked: sidebarNav.navigateTo(0)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Metrics.spacingSm

                Label {
                    text: "Desktop Session"
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.fontBody
                    font.weight: sidebarNav.currentViewIndex === 0 ? Typography.weightBold : Typography.weightMedium
                    color: sidebarNav.currentViewIndex === 0 ? themePalette.primary : themePalette.textPrimary
                }
            }
        }

        // View 1: Saved Devices
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: Metrics.radiusSm
            color: sidebarNav.currentViewIndex === 1 ? themePalette.surfaceVariant : themePalette.surface
            Accessible.role: Accessible.Button
            Accessible.name: "Saved Devices View"
            Accessible.description: "Switches workspace view to control plane registered devices directory"

            MouseArea {
                anchors.fill: parent
                onClicked: sidebarNav.navigateTo(1)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Metrics.spacingSm

                Label {
                    text: "Saved Devices"
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.fontBody
                    font.weight: sidebarNav.currentViewIndex === 1 ? Typography.weightBold : Typography.weightMedium
                    color: sidebarNav.currentViewIndex === 1 ? themePalette.primary : themePalette.textSecondary
                }
            }
        }

        // View 2: Security & Keys
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: Metrics.radiusSm
            color: sidebarNav.currentViewIndex === 2 ? themePalette.surfaceVariant : themePalette.surface
            Accessible.role: Accessible.Button
            Accessible.name: "Security & Keys View"
            Accessible.description: "Switches workspace view to cryptographic cipher and STUN connection details"

            MouseArea {
                anchors.fill: parent
                onClicked: sidebarNav.navigateTo(2)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Metrics.spacingSm

                Label {
                    text: "Security & NAT Keys"
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.fontBody
                    font.weight: sidebarNav.currentViewIndex === 2 ? Typography.weightBold : Typography.weightMedium
                    color: sidebarNav.currentViewIndex === 2 ? themePalette.primary : themePalette.textSecondary
                }
            }
        }

        // View 3: Encrypted File Transfer Channel
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: Metrics.radiusSm
            color: sidebarNav.currentViewIndex === 3 ? themePalette.surfaceVariant : themePalette.surface
            Accessible.role: Accessible.Button
            Accessible.name: "File Transfer Channel View"
            Accessible.description: "Switches workspace view to high-speed encrypted file upload, download, and directory browser"

            MouseArea {
                anchors.fill: parent
                onClicked: sidebarNav.navigateTo(3)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Metrics.spacingSm

                Label {
                    text: "File Transfer Channel"
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.fontBody
                    font.weight: sidebarNav.currentViewIndex === 3 ? Typography.weightBold : Typography.weightMedium
                    color: sidebarNav.currentViewIndex === 3 ? themePalette.primary : themePalette.textSecondary
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
