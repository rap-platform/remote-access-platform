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
            color: navHover0.hovered ? themePalette.surfaceVariant : (sidebarNav.currentViewIndex === 0 ? themePalette.surfaceVariant : themePalette.surface)
            border.color: sidebarNav.currentViewIndex === 0 ? themePalette.primary : "transparent"
            border.width: 1

            HoverHandler {
                id: navHover0
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: sidebarNav.navigateTo(0)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Metrics.spacingSm
                anchors.rightMargin: Metrics.spacingSm
                spacing: Metrics.spacingSm

                Rectangle {
                    width: 3
                    Layout.fillHeight: true
                    color: sidebarNav.currentViewIndex === 0 ? themePalette.primary : "transparent"
                    radius: 2
                }

                Label {
                    text: "Desktop Session"
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.fontBody
                    font.weight: sidebarNav.currentViewIndex === 0 ? Typography.weightBold : Typography.weightMedium
                    color: sidebarNav.currentViewIndex === 0 ? themePalette.primary : themePalette.textPrimary
                    Layout.fillWidth: true
                }
            }
        }

        // View 1: Saved Devices
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: Metrics.radiusSm
            color: navHover1.hovered ? themePalette.surfaceVariant : (sidebarNav.currentViewIndex === 1 ? themePalette.surfaceVariant : themePalette.surface)
            border.color: sidebarNav.currentViewIndex === 1 ? themePalette.primary : "transparent"
            border.width: 1

            HoverHandler {
                id: navHover1
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: sidebarNav.navigateTo(1)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Metrics.spacingSm
                anchors.rightMargin: Metrics.spacingSm
                spacing: Metrics.spacingSm

                Rectangle {
                    width: 3
                    Layout.fillHeight: true
                    color: sidebarNav.currentViewIndex === 1 ? themePalette.primary : "transparent"
                    radius: 2
                }

                Label {
                    text: "Saved Devices"
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.fontBody
                    font.weight: sidebarNav.currentViewIndex === 1 ? Typography.weightBold : Typography.weightMedium
                    color: sidebarNav.currentViewIndex === 1 ? themePalette.primary : themePalette.textSecondary
                    Layout.fillWidth: true
                }
            }
        }

        // View 2: Security & Keys
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: Metrics.radiusSm
            color: navHover2.hovered ? themePalette.surfaceVariant : (sidebarNav.currentViewIndex === 2 ? themePalette.surfaceVariant : themePalette.surface)
            border.color: sidebarNav.currentViewIndex === 2 ? themePalette.primary : "transparent"
            border.width: 1

            HoverHandler {
                id: navHover2
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: sidebarNav.navigateTo(2)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Metrics.spacingSm
                anchors.rightMargin: Metrics.spacingSm
                spacing: Metrics.spacingSm

                Rectangle {
                    width: 3
                    Layout.fillHeight: true
                    color: sidebarNav.currentViewIndex === 2 ? themePalette.primary : "transparent"
                    radius: 2
                }

                Label {
                    text: "Security & NAT Keys"
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.fontBody
                    font.weight: sidebarNav.currentViewIndex === 2 ? Typography.weightBold : Typography.weightMedium
                    color: sidebarNav.currentViewIndex === 2 ? themePalette.primary : themePalette.textSecondary
                    Layout.fillWidth: true
                }
            }
        }

        // View 3: Encrypted File Transfer Channel
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: Metrics.radiusSm
            color: navHover3.hovered ? themePalette.surfaceVariant : (sidebarNav.currentViewIndex === 3 ? themePalette.surfaceVariant : themePalette.surface)
            border.color: sidebarNav.currentViewIndex === 3 ? themePalette.primary : "transparent"
            border.width: 1

            HoverHandler {
                id: navHover3
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: sidebarNav.navigateTo(3)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Metrics.spacingSm
                anchors.rightMargin: Metrics.spacingSm
                spacing: Metrics.spacingSm

                Rectangle {
                    width: 3
                    Layout.fillHeight: true
                    color: sidebarNav.currentViewIndex === 3 ? themePalette.primary : "transparent"
                    radius: 2
                }

                Label {
                    text: "File Transfer Channel"
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.fontBody
                    font.weight: sidebarNav.currentViewIndex === 3 ? Typography.weightBold : Typography.weightMedium
                    color: sidebarNav.currentViewIndex === 3 ? themePalette.primary : themePalette.textSecondary
                    Layout.fillWidth: true
                }
            }
        }

        Item { Layout.fillHeight: true }

        // View 4: Settings & Preferences (anchored to bottom)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: Metrics.radiusSm
            color: navHover4.hovered ? themePalette.surfaceVariant : (sidebarNav.currentViewIndex === 4 ? themePalette.surfaceVariant : themePalette.surface)
            border.color: sidebarNav.currentViewIndex === 4 ? themePalette.primary : "transparent"
            border.width: 1

            HoverHandler {
                id: navHover4
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: sidebarNav.navigateTo(4)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Metrics.spacingSm
                anchors.rightMargin: Metrics.spacingSm
                spacing: Metrics.spacingSm

                Rectangle {
                    width: 3
                    Layout.fillHeight: true
                    color: sidebarNav.currentViewIndex === 4 ? themePalette.primary : "transparent"
                    radius: 2
                }

                Label {
                    text: "⚙️ Settings"
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.fontBody
                    font.weight: sidebarNav.currentViewIndex === 4 ? Typography.weightBold : Typography.weightMedium
                    color: sidebarNav.currentViewIndex === 4 ? themePalette.primary : themePalette.textSecondary
                    Layout.fillWidth: true
                }
            }
        }
    }
}
