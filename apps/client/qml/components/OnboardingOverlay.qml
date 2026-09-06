import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: onboardingRoot
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.75)
    z: 99999
    visible: false

    property int currentStep: 0
    signal tourCompleted()

    property var steps: [
        {
            title: "👋 Welcome to Remote Access Platform",
            desc: "Enterprise cross-platform remote desktop control, file transfer, and encrypted P2P tunneling.",
            targetText: "Get Started ➔"
        },
        {
            title: "🆔 Your P2P Desk ID",
            desc: "This is your unique AnyDesk-style hardware Desk ID. Share this ID with authorized technicians to allow incoming sessions.",
            targetText: "Next Step ➔"
        },
        {
            title: "⚡ Connect to Remote Host",
            desc: "Enter a remote target's Desk ID or IP address into the search bar and press Connect to start a streaming session.",
            targetText: "Next Step ➔"
        },
        {
            title: "🖥️ Modular Sidebar Navigation",
            desc: "Switch seamlessly between Desktop Viewport, Saved Fleet Devices, IP Access Control Rules, File Manager, Settings, and Remote Terminal Shell.",
            targetText: "Next Step ➔"
        },
        {
            title: "🛡️ Enterprise Security & Privacy",
            desc: "All connections are secured with libsodium E2E encryption, 2FA authorization, and real-time IP Access Control Lists (ACL).",
            targetText: "Finish Tour 🎉"
        }
    ]

    function startTour() {
        currentStep = 0
        visible = true
    }

    Rectangle {
        anchors.centerIn: parent
        width: 480
        height: 240
        radius: Metrics.radiusMd
        color: themePalette.surface
        border.color: themePalette.primary
        border.width: 2

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Metrics.spacingLg
            spacing: Metrics.spacingMd

            Label {
                text: onboardingRoot.steps[onboardingRoot.currentStep].title
                font.family: Typography.fontFamily
                font.pixelSize: Typography.fontSubheader
                font.weight: Typography.weightBold
                color: themePalette.textPrimary
                Layout.fillWidth: true
                Accessible.role: Accessible.Heading
                Accessible.name: text
            }

            Label {
                text: onboardingRoot.steps[onboardingRoot.currentStep].desc
                font.family: Typography.fontFamily
                font.pixelSize: Typography.fontBody
                color: themePalette.textSecondary
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Metrics.spacingSm

                Label {
                    text: "Step " + (onboardingRoot.currentStep + 1) + " of " + onboardingRoot.steps.length
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.fontCaption
                    color: themePalette.textSecondary
                    Layout.fillWidth: true
                }

                Button {
                    text: "Skip"
                    Layout.preferredHeight: 32
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.fontCaption
                    onClicked: {
                        onboardingRoot.visible = false
                        onboardingRoot.tourCompleted()
                    }
                    background: Rectangle { color: themePalette.surfaceVariant; radius: Metrics.radiusSm }
                    contentItem: Text { text: parent.text; color: themePalette.textSecondary; font: parent.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }

                Button {
                    text: onboardingRoot.steps[onboardingRoot.currentStep].targetText
                    Layout.preferredHeight: 32
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.fontCaption
                    font.weight: Typography.weightBold
                    onClicked: {
                        if (onboardingRoot.currentStep < onboardingRoot.steps.length - 1) {
                            onboardingRoot.currentStep += 1
                        } else {
                            onboardingRoot.visible = false
                            onboardingRoot.tourCompleted()
                        }
                    }
                    background: Rectangle { color: themePalette.primary; radius: Metrics.radiusSm }
                    contentItem: Text { text: parent.text; color: themePalette.textPrimary; font: parent.font; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                }
            }
        }
    }
}
