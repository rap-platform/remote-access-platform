import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: headerBar
    Layout.fillWidth: true
    Layout.preferredHeight: 50
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
            Accessible.role: Accessible.Heading
            Accessible.name: "Application Title"
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            Layout.topMargin: Metrics.spacingSm
            Layout.bottomMargin: Metrics.spacingSm
            color: themePalette.border
        }

        Rectangle {
            Layout.preferredWidth: 180
            Layout.preferredHeight: 24
            radius: Metrics.radiusSm
            color: Qt.rgba(0.0, 0.8, 0.4, 0.12)
            border.color: themePalette.success

            Label {
                anchors.centerIn: parent
                text: "⚡ Hardware P2P Active"
                font.pixelSize: Typography.fontCaption
                font.weight: Typography.weightBold
                color: themePalette.success
            }
        }

        Item { Layout.fillWidth: true }

        Label {
            text: "Theme:"
            font.family: Typography.fontFamily
            font.pixelSize: Typography.fontCaption
            font.weight: Typography.weightMedium
            color: themePalette.textSecondary
            Accessible.role: Accessible.StaticText
            Accessible.name: "Theme Selector Label"
        }

        ComboBox {
            id: themeSelector
            model: ["Catppuccin Dark", "Tokyo Night", "Nordic Frost", "GitHub Dark", "Enterprise Light"]
            currentIndex: themePalette.currentTheme
            font.family: Typography.fontFamily
            font.pixelSize: Typography.fontCaption
            Accessible.role: Accessible.ComboBox
            Accessible.name: "Color Theme Selector"
            Accessible.description: "Select visual color theme palette for accessibility and appearance"
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
    }
}
