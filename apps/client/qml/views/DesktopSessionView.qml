import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: desktopSessionView
    color: themePalette.background

    property int activeTabIndex: 0
    property int activeConnectedTabIndex: -1
    property bool isCurrentTabConnected: sessionClient.isConnected && (activeTabIndex === activeConnectedTabIndex)

    ListModel {
        id: sessionTabsModel
        ListElement { title: "New Session"; targetHost: "127.0.0.1:18443"; connected: false }
    }

    Connections {
        target: sessionClient
        function onIsConnectedChanged() {
            if (!sessionClient.isConnected) {
                desktopSessionView.activeConnectedTabIndex = -1
                for (let i = 0; i < sessionTabsModel.count; ++i) {
                    sessionTabsModel.setProperty(i, "connected", false)
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Multi-Tab Session Connection Bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            color: themePalette.surfaceVariant
            border.color: themePalette.border

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Metrics.spacingSm
                anchors.rightMargin: Metrics.spacingSm
                spacing: Metrics.spacingXs

                ListView {
                    id: sessionTabBar
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    orientation: ListView.Horizontal
                    model: sessionTabsModel
                    spacing: 4

                    delegate: Rectangle {
                        width: 160
                        height: 32
                        anchors.verticalCenter: parent.verticalCenter
                        color: index === desktopSessionView.activeTabIndex ? themePalette.surface : themePalette.background
                        radius: Metrics.radiusSm
                        border.color: index === desktopSessionView.activeTabIndex ? themePalette.primary : themePalette.border

                        MouseArea {
                            anchors.fill: parent
                            onClicked: desktopSessionView.activeTabIndex = index
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Metrics.spacingSm
                            anchors.rightMargin: Metrics.spacingSm
                            spacing: 4

                            Rectangle {
                                width: 8; height: 8; radius: 4
                                color: (index === desktopSessionView.activeConnectedTabIndex && sessionClient.isConnected) ? themePalette.success : themePalette.textSecondary
                            }

                            Text {
                                text: model.title
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.fontCaption
                                font.weight: index === desktopSessionView.activeTabIndex ? Typography.weightBold : Typography.weightRegular
                                color: themePalette.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: "✕"
                                font.pixelSize: 12
                                font.weight: Typography.weightBold
                                color: themePalette.textSecondary
                                visible: sessionTabsModel.count > 1

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    z: 10
                                    onClicked: (mouse) => {
                                        mouse.accepted = true
                                        let removeIdx = index
                                        sessionTabsModel.remove(removeIdx)
                                        if (desktopSessionView.activeTabIndex >= sessionTabsModel.count) {
                                            desktopSessionView.activeTabIndex = Math.max(0, sessionTabsModel.count - 1)
                                        }
                                        if (removeIdx === desktopSessionView.activeConnectedTabIndex) {
                                            sessionClient.disconnectFromHost()
                                            desktopSessionView.activeConnectedTabIndex = -1
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Button {
                    text: "+ New Tab"
                    Layout.preferredHeight: 30
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.fontCaption
                    onClicked: {
                        let newIdx = sessionTabsModel.count + 1
                        sessionTabsModel.append({ title: "Session " + newIdx, targetHost: "127.0.0.1:18443", connected: false })
                        desktopSessionView.activeTabIndex = sessionTabsModel.count - 1
                    }
                    background: Rectangle {
                        color: themePalette.surface
                        radius: Metrics.radiusSm
                        border.color: themePalette.border
                    }
                }
            }
        }

        // Active Session Content Area
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Live Remote Viewport Container (Shown when connected and active tab selected)
            Item {
                anchors.fill: parent
                anchors.margins: Metrics.spacingMd
                visible: desktopSessionView.isCurrentTabConnected

                Image {
                    id: videoSurface
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                    source: "image://frameprovider/current"
                    cache: false
                    Accessible.role: Accessible.Graphic
                    Accessible.name: "Live Remote Desktop Viewport"
                    Accessible.description: "Interactive canvas displaying decoded remote host desktop stream"

                    Connections {
                        target: frameProvider
                        function onFrameReady() {
                            videoSurface.source = ""
                            videoSurface.source = "image://frameprovider/current"
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: themePalette.border
                    border.width: 1
                    radius: Metrics.radiusSm
                }

                // Overlay disconnect header bar inside active session
                Rectangle {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: Metrics.spacingSm
                    width: 320
                    height: 36
                    radius: Metrics.radiusSm
                    color: themePalette.surface
                    border.color: themePalette.border
                    z: 50

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Metrics.spacingSm
                        anchors.rightMargin: Metrics.spacingSm

                        Rectangle {
                            width: 8; height: 8; radius: 4
                            color: themePalette.success
                        }

                        Label {
                            text: sessionClient.statusText
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontCaption
                            font.weight: Typography.weightBold
                            color: themePalette.textPrimary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Button {
                            text: "Disconnect"
                            Layout.preferredHeight: 26
                            font.family: Typography.fontFamily
                            font.pixelSize: 11
                            font.weight: Typography.weightBold
                            onClicked: {
                                sessionClient.disconnectFromHost()
                                desktopSessionView.activeConnectedTabIndex = -1
                            }
                            background: Rectangle {
                                color: themePalette.error
                                radius: Metrics.radiusSm
                            }
                        }
                    }
                }

                MouseArea {
                    id: inputArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    focus: true

                    onPositionChanged: (mouse) => {
                        if (sessionClient.isConnected) {
                            sessionClient.sendInputEvent(0, mouse.x, mouse.y, 0, 0, 0, mouse.modifiers)
                        }
                    }

                    onPressed: (mouse) => {
                        if (sessionClient.isConnected) {
                            let btn = 1
                            if (mouse.button === Qt.RightButton) btn = 2
                            if (mouse.button === Qt.MiddleButton) btn = 3
                            sessionClient.sendInputEvent(1, mouse.x, mouse.y, btn, 0, 0, mouse.modifiers)
                        }
                    }

                    onReleased: (mouse) => {
                        if (sessionClient.isConnected) {
                            let btn = 1
                            if (mouse.button === Qt.RightButton) btn = 2
                            if (mouse.button === Qt.MiddleButton) btn = 3
                            sessionClient.sendInputEvent(2, mouse.x, mouse.y, btn, 0, 0, mouse.modifiers)
                        }
                    }

                    onWheel: (wheel) => {
                        if (sessionClient.isConnected) {
                            sessionClient.sendInputEvent(3, wheel.x, wheel.y, 0, wheel.angleDelta.y, 0, wheel.modifiers)
                        }
                    }

                    Keys.onPressed: (event) => {
                        if (sessionClient.isConnected && inputArea.containsMouse) {
                            sessionClient.sendInputEvent(4, 0, 0, 0, 0, event.nativeScanCode, event.modifiers)
                            event.accepted = true
                        }
                    }

                    Keys.onReleased: (event) => {
                        if (sessionClient.isConnected && inputArea.containsMouse) {
                            sessionClient.sendInputEvent(5, 0, 0, 0, 0, event.nativeScanCode, event.modifiers)
                            event.accepted = true
                        }
                    }
                }
            }

            // Connection Cards Container (Card 1: This Desk & Card 2: Remote Desk)
            RowLayout {
                anchors.centerIn: parent
                visible: !desktopSessionView.isCurrentTabConnected
                spacing: Metrics.spacingLg

                // Card 1: THIS DESK (Your P2P Desk ID)
                Rectangle {
                    Layout.preferredWidth: 360
                    Layout.preferredHeight: 220
                    color: themePalette.surface
                    radius: Metrics.radiusLg
                    border.color: themePalette.border
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Metrics.spacingLg
                        spacing: Metrics.spacingSm

                        RowLayout {
                            spacing: Metrics.spacingSm
                            Rectangle {
                                width: 10; height: 10; radius: 5
                                color: themePalette.success
                            }
                            Label {
                                text: "This Desk (Ready for Incoming)"
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.fontCaption
                                font.weight: Typography.weightBold
                                color: themePalette.textSecondary
                            }
                        }

                        Label {
                            text: sessionClient.p2pId
                            font.family: Typography.fontFamily
                            font.pixelSize: 32
                            font.weight: Typography.weightBold
                            color: themePalette.primary
                            Accessible.role: Accessible.StaticText
                            Accessible.name: "Your AnyDesk P2P Desk ID"
                        }

                        Label {
                            text: "Share this Desk ID to allow remote devices to access this screen."
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontCaption
                            color: themePalette.textSecondary
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Item { Layout.fillHeight: true }

                        Button {
                            text: "Copy Desk ID"
                            Layout.fillWidth: true
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontCaption
                            font.weight: Typography.weightMedium
                            onClicked: sessionClient.sendClipboardText(sessionClient.p2pId)
                            background: Rectangle {
                                color: themePalette.surfaceVariant
                                radius: Metrics.radiusSm
                                border.color: themePalette.border
                            }
                        }
                    }
                }

                // Card 2: REMOTE DESK (Connect to Peer)
                Rectangle {
                    Layout.preferredWidth: 360
                    Layout.preferredHeight: 220
                    color: themePalette.surface
                    radius: Metrics.radiusLg
                    border.color: themePalette.border
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Metrics.spacingLg
                        spacing: Metrics.spacingSm

                        Label {
                            text: "Remote Desk"
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontCaption
                            font.weight: Typography.weightBold
                            color: themePalette.textSecondary
                        }

                        TextField {
                            id: targetIdInput
                            placeholderText: "Enter Remote P2P ID or IP:Port"
                            text: "127.0.0.1:18443"
                            Layout.fillWidth: true
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontBody
                            color: themePalette.textPrimary
                            background: Rectangle {
                                color: themePalette.surfaceVariant
                                radius: Metrics.radiusSm
                                border.color: themePalette.border
                            }
                        }

                        Label {
                            text: "Enter peer's 9-digit Desk ID (e.g. 482 915 307) or IP address to connect."
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontCaption
                            color: themePalette.textSecondary
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Item { Layout.fillHeight: true }

                        Button {
                            text: "Connect to Remote Desk"
                            Layout.fillWidth: true
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontBody
                            font.weight: Typography.weightBold
                            onClicked: {
                                let target = targetIdInput.text
                                desktopSessionView.activeConnectedTabIndex = desktopSessionView.activeTabIndex
                                sessionTabsModel.setProperty(desktopSessionView.activeTabIndex, "title", target.length > 0 ? target : "Desk Session")
                                sessionTabsModel.setProperty(desktopSessionView.activeTabIndex, "connected", true)
                                if (target.indexOf(":") !== -1) {
                                    let parts = target.split(":")
                                    sessionClient.connectToHost(parts[0], parseInt(parts[1]))
                                } else {
                                    sessionClient.connectByP2PId(target)
                                }
                            }
                            contentItem: Text {
                                text: parent.text
                                font: parent.font
                                color: themePalette.textPrimary
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: themePalette.primary
                                radius: Metrics.radiusSm
                            }
                        }
                    }
                }
            }
        }
    }
}
