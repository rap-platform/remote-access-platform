import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

// ToastNotification — Reusable system-wide toast notification component.
// Supports: success, error, warning, info types with auto-dismiss.
// Usage: toastManager.showToast("Message text", "success")
Item {
    id: toastRoot

    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: Metrics.spacingLg
    anchors.rightMargin: Metrics.spacingLg
    width: 360
    z: 9999

    // Public API function
    function showToast(message, type) {
        let icon = "ℹ️"
        let color = themePalette.primary
        let bgColor = Qt.rgba(themePalette.surface.r, themePalette.surface.g, themePalette.surface.b, 0.95)

        if (type === "success") {
            icon = "✅"
            color = themePalette.success
        } else if (type === "error") {
            icon = "❌"
            color = themePalette.error
        } else if (type === "warning") {
            icon = "⚠️"
            color = themePalette.warning
        } else {
            icon = "ℹ️"
            color = themePalette.primary
        }

        toastModel.append({
            message: message,
            toastType: type || "info",
            toastIcon: icon,
            accentColor: color.toString(),
            dismissed: false
        })
    }

    ListModel {
        id: toastModel
    }

    Column {
        anchors.fill: parent
        spacing: Metrics.spacingSm

        Repeater {
            model: toastModel

            delegate: Rectangle {
                id: toastCard
                width: toastRoot.width
                height: toastContent.implicitHeight + Metrics.spacingMd * 2
                radius: Metrics.radiusMd
                color: Qt.rgba(themePalette.surface.r, themePalette.surface.g, themePalette.surface.b, 0.95)
                border.color: model.accentColor
                border.width: 2
                opacity: 0
                x: 60  // Start offset for slide-in

                // Slide-in + fade-in animation on creation
                Component.onCompleted: {
                    slideIn.start()
                    autoDismissTimer.start()
                }

                ParallelAnimation {
                    id: slideIn
                    NumberAnimation { target: toastCard; property: "opacity"; to: 1.0; duration: 250; easing.type: Easing.OutCubic }
                    NumberAnimation { target: toastCard; property: "x"; to: 0; duration: 300; easing.type: Easing.OutCubic }
                }

                ParallelAnimation {
                    id: slideOut
                    NumberAnimation { target: toastCard; property: "opacity"; to: 0.0; duration: 200; easing.type: Easing.InCubic }
                    NumberAnimation { target: toastCard; property: "x"; to: 60; duration: 200; easing.type: Easing.InCubic }
                    onFinished: {
                        // Remove from model after animation completes
                        if (index >= 0 && index < toastModel.count) {
                            toastModel.remove(index)
                        }
                    }
                }

                // Auto-dismiss after 4 seconds
                Timer {
                    id: autoDismissTimer
                    interval: 4000
                    repeat: false
                    onTriggered: slideOut.start()
                }

                // Left accent stripe
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 4
                    radius: Metrics.radiusMd
                    color: model.accentColor
                }

                RowLayout {
                    id: toastContent
                    anchors.fill: parent
                    anchors.margins: Metrics.spacingMd
                    anchors.leftMargin: Metrics.spacingMd + 4  // Account for accent stripe
                    spacing: Metrics.spacingSm

                    // Icon
                    Text {
                        text: model.toastIcon
                        font.pixelSize: 20
                        verticalAlignment: Text.AlignVCenter
                    }

                    // Message text
                    Text {
                        text: model.message
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.fontCaption
                        font.weight: Typography.weightMedium
                        color: themePalette.textPrimary
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                    }

                    // Close button
                    Text {
                        text: "✕"
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        color: themePalette.textSecondary
                        verticalAlignment: Text.AlignVCenter

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: slideOut.start()
                        }
                    }
                }

                // Hover effect
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    propagateComposedEvents: true
                    onEntered: autoDismissTimer.stop()
                    onExited: autoDismissTimer.restart()
                    onClicked: (mouse) => mouse.accepted = false
                    onPressed: (mouse) => mouse.accepted = false
                    onReleased: (mouse) => mouse.accepted = false
                }
            }
        }
    }
}
