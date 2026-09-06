import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: statusBar
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
            text: "v" + (typeof appVersion !== "undefined" ? appVersion : "0.3.0") + "-dev"
            font.family: Typography.fontFamily
            font.pixelSize: Typography.fontCaption
            color: themePalette.textSecondary
        }
    }
}
