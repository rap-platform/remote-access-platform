import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: fileTransferView
    color: themePalette.background

    Component.onCompleted: {
        sessionClient.requestLocalDirectoryListing(".")
        if (sessionClient.isConnected) {
            sessionClient.requestDirectoryListing(".")
        }
    }

    Connections {
        target: sessionClient
        function onConnectionStateChanged(connected) {
            if (connected) {
                sessionClient.requestLocalDirectoryListing(".")
                sessionClient.requestDirectoryListing(".")
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Metrics.spacingMd
        spacing: Metrics.spacingSm

        // Header Title Bar
        RowLayout {
            Layout.fillWidth: true
            Label {
                text: "AnyDesk-Style Encrypted File Manager"
                font.family: Typography.fontFamily
                font.pixelSize: Typography.fontHeadline
                font.weight: Typography.weightBold
                color: themePalette.textPrimary
                Accessible.role: Accessible.Heading
                Accessible.name: "File Transfer Dual Pane Title"
            }
            Item { Layout.fillWidth: true }

            Label {
                text: "Target Agent:"
                font.family: Typography.fontFamily
                font.pixelSize: Typography.fontCaption
                color: themePalette.textSecondary
                visible: sessionClient.isConnected
            }

            ComboBox {
                id: targetAgentSelector
                Layout.preferredWidth: 200
                visible: sessionClient.isConnected
                model: [ "Agent #1 (127.0.0.1:18443)", "Agent #2 (P2P Relay)" ]
                font.family: Typography.fontFamily
                font.pixelSize: Typography.fontCaption
                onActivated: (index) => {
                    sessionClient.requestDirectoryListing(sessionClient.currentRemotePath)
                }
            }

            Rectangle {
                Layout.preferredWidth: 210
                Layout.preferredHeight: 24
                radius: Metrics.radiusSm
                color: Qt.rgba(0.0, 0.8, 0.4, 0.15)
                border.color: themePalette.success

                Label {
                    anchors.centerIn: parent
                    text: "⚡ E2E Encrypted • 256KB Chunking"
                    font.pixelSize: Typography.fontCaption
                    font.weight: Typography.weightBold
                    color: themePalette.success
                }
            }
        }

        // Disconnected Offline Notice Overlay
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !sessionClient.isConnected
            color: themePalette.surface
            radius: Metrics.radiusLg
            border.color: themePalette.border

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Metrics.spacingMd

                Label {
                    text: "🔒"
                    font.pixelSize: 56
                    Layout.alignment: Qt.AlignHCenter
                }

                Label {
                    text: "File Explorer Offline — No Agent Connected"
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.fontTitle
                    font.weight: Typography.weightBold
                    color: themePalette.textPrimary
                    Layout.alignment: Qt.AlignHCenter
                }

                Label {
                    text: "Dual-pane file directory browsing is available when connected to a remote host.\nPlease switch to the Remote Desktop tab and connect to a peer's Desk ID."
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.fontBody
                    color: themePalette.textSecondary
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        // Dual Pane Split Layout (Local Device vs. Remote Device)
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: sessionClient.isConnected
            spacing: Metrics.spacingMd

            // LEFT PANE: Local System Directory Explorer
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: themePalette.surface
                radius: Metrics.radiusSm
                border.color: themePalette.border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Metrics.spacingSm
                    spacing: Metrics.spacingXs

                    RowLayout {
                     Layout.fillWidth: true
                        Label {
                            text: "💻  Local Device Explorer"
                            font.weight: Typography.weightBold
                            color: themePalette.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Button {
                            id: btnLocalUp
                            text: "⬆ Parent"
                            Layout.preferredHeight: 30
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontCaption
                            font.weight: Typography.weightMedium
                            Accessible.role: Accessible.Button
                            Accessible.name: "Local Up Directory"
                            onClicked: {
                                let path = sessionClient.currentLocalPath
                                let parts = path.split("/")
                                if (parts.length > 1) {
                                    parts.pop()
                                    let newPath = parts.join("/")
                                    sessionClient.requestLocalDirectoryListing(newPath.length === 0 ? "." : newPath)
                                }
                            }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            background: Rectangle {
                                color: btnLocalUp.hovered ? themePalette.surfaceVariant : themePalette.surface
                                radius: Metrics.radiusSm
                                border.color: themePalette.border
                            }
                        }
                        Button {
                            id: btnLocalRefresh
                            text: "🔄 Refresh"
                            Layout.preferredHeight: 30
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontCaption
                            font.weight: Typography.weightMedium
                            Accessible.role: Accessible.Button
                            Accessible.name: "Refresh Local Directory"
                            onClicked: sessionClient.requestLocalDirectoryListing(sessionClient.currentLocalPath)
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            background: Rectangle {
                                color: btnLocalRefresh.hovered ? themePalette.surfaceVariant : themePalette.surface
                                radius: Metrics.radiusSm
                                border.color: themePalette.border
                            }
                        }
                    }

                    TextField {
                        id: localPathInput
                        Layout.fillWidth: true
                        text: sessionClient.currentLocalPath
                        selectByMouse: true
                        color: themePalette.textPrimary
                        background: Rectangle {
                            color: themePalette.surfaceVariant
                            border.color: themePalette.border
                            radius: Metrics.radiusSm
                        }
                        onAccepted: sessionClient.requestLocalDirectoryListing(text)
                    }

                    // Table Header Bar (SharkView pattern)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 26
                        color: themePalette.surfaceVariant
                        radius: Metrics.radiusSm

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Metrics.spacingSm
                            anchors.rightMargin: Metrics.spacingSm

                            Label { text: "Name"; font.weight: Typography.weightBold; color: themePalette.textSecondary; Layout.fillWidth: true }
                            Label { text: "Type"; font.weight: Typography.weightBold; color: themePalette.textSecondary; Layout.preferredWidth: 60 }
                            Label { text: "Size"; font.weight: Typography.weightBold; color: themePalette.textSecondary; Layout.preferredWidth: 70 }
                            Label { text: "Actions"; font.weight: Typography.weightBold; color: themePalette.textSecondary; Layout.preferredWidth: 110 }
                        }
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: sessionClient.localDirectoryList

                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 36
                            color: index % 2 === 0 ? themePalette.surface : themePalette.surfaceVariant
                            border.color: themePalette.border
                            border.width: 0.5

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Metrics.spacingSm
                                anchors.rightMargin: Metrics.spacingSm

                                Label {
                                    text: modelData.name
                                    font.weight: modelData.isDir ? Typography.weightBold : Typography.weightMedium
                                    color: modelData.isDir ? themePalette.primary : themePalette.textPrimary
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                // Type Badge
                                Rectangle {
                                    Layout.preferredWidth: 50
                                    Layout.preferredHeight: 20
                                    radius: 3
                                    color: modelData.isDir ? Qt.rgba(0.2, 0.5, 1.0, 0.15) : Qt.rgba(0.5, 0.5, 0.5, 0.15)
                                    border.color: modelData.isDir ? themePalette.primary : themePalette.border

                                    Label {
                                        anchors.centerIn: parent
                                        text: modelData.isDir ? "DIR" : "FILE"
                                        font.pixelSize: 10
                                        font.weight: Typography.weightBold
                                        color: parent.border.color
                                    }
                                }

                                Label {
                                    text: modelData.isDir ? "-" : Math.round(modelData.size / 1024) + " KB"
                                    color: themePalette.textSecondary
                                    Layout.preferredWidth: 70
                                }

                                RowLayout {
                                    Layout.preferredWidth: 110
                                    spacing: 4

                                    Button {
                                        text: modelData.isDir ? "Open" : "Upload ➔"
                                        onClicked: {
                                            if (modelData.isDir) {
                                                let nextPath = sessionClient.currentLocalPath === "." ? modelData.name : sessionClient.currentLocalPath + "/" + modelData.name
                                                sessionClient.requestLocalDirectoryListing(nextPath)
                                            } else {
                                                let fullPath = sessionClient.currentLocalPath === "." ? modelData.name : sessionClient.currentLocalPath + "/" + modelData.name
                                                sessionClient.startFileUpload(fullPath, sessionClient.currentRemotePath)
                                            }
                                        }
                                    }

                                    Button {
                                        text: "🗑️"
                                        onClicked: {
                                            let fullPath = sessionClient.currentLocalPath === "." ? modelData.name : sessionClient.currentLocalPath + "/" + modelData.name
                                            sessionClient.deleteLocalFile(fullPath)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // RIGHT PANE: Remote Agent System Directory Explorer
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: themePalette.surface
                radius: Metrics.radiusSm
                border.color: themePalette.border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Metrics.spacingSm
                    spacing: Metrics.spacingXs

                    RowLayout {
                        Layout.fillWidth: true
                        Label {
                            text: "🖥️  Remote Agent Explorer"
                            font.weight: Typography.weightBold
                            color: themePalette.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Button {
                            id: btnRemoteUp
                            text: "⬆ Parent"
                            Layout.preferredHeight: 30
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontCaption
                            font.weight: Typography.weightMedium
                            Accessible.role: Accessible.Button
                            Accessible.name: "Remote Up Directory"
                            onClicked: {
                                let path = sessionClient.currentRemotePath
                                let parts = path.split("/")
                                if (parts.length > 1) {
                                    parts.pop()
                                    let newPath = parts.join("/")
                                    sessionClient.requestDirectoryListing(newPath.length === 0 ? "." : newPath)
                                }
                            }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            background: Rectangle {
                                color: btnRemoteUp.hovered ? themePalette.surfaceVariant : themePalette.surface
                                radius: Metrics.radiusSm
                                border.color: themePalette.border
                            }
                        }
                        Button {
                            id: btnRemoteRefresh
                            text: "🔄 Refresh"
                            Layout.preferredHeight: 30
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontCaption
                            font.weight: Typography.weightMedium
                            Accessible.role: Accessible.Button
                            Accessible.name: "Refresh Remote Directory"
                            onClicked: sessionClient.requestDirectoryListing(sessionClient.currentRemotePath)
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            background: Rectangle {
                                color: btnRemoteRefresh.hovered ? themePalette.surfaceVariant : themePalette.surface
                                radius: Metrics.radiusSm
                                border.color: themePalette.border
                            }
                        }
                    }

                    TextField {
                        id: remotePathInput
                        Layout.fillWidth: true
                        text: sessionClient.currentRemotePath
                        selectByMouse: true
                        color: themePalette.textPrimary
                        background: Rectangle {
                            color: themePalette.surfaceVariant
                            border.color: themePalette.border
                            radius: Metrics.radiusSm
                        }
                        onAccepted: sessionClient.requestDirectoryListing(text)
                    }

                    // Table Header Bar (SharkView pattern)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 26
                        color: themePalette.surfaceVariant
                        radius: Metrics.radiusSm

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Metrics.spacingSm
                            anchors.rightMargin: Metrics.spacingSm

                            Label { text: "Name"; font.weight: Typography.weightBold; color: themePalette.textSecondary; Layout.fillWidth: true }
                            Label { text: "Type"; font.weight: Typography.weightBold; color: themePalette.textSecondary; Layout.preferredWidth: 60 }
                            Label { text: "Size"; font.weight: Typography.weightBold; color: themePalette.textSecondary; Layout.preferredWidth: 70 }
                            Label { text: "Actions"; font.weight: Typography.weightBold; color: themePalette.textSecondary; Layout.preferredWidth: 120 }
                        }
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: sessionClient.directoryList

                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 36
                            color: index % 2 === 0 ? themePalette.surface : themePalette.surfaceVariant
                            border.color: themePalette.border
                            border.width: 0.5

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Metrics.spacingSm
                                anchors.rightMargin: Metrics.spacingSm

                                Label {
                                    text: modelData.name
                                    font.weight: modelData.isDir ? Typography.weightBold : Typography.weightMedium
                                    color: modelData.isDir ? themePalette.primary : themePalette.textPrimary
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                // Type Badge
                                Rectangle {
                                    Layout.preferredWidth: 50
                                    Layout.preferredHeight: 20
                                    radius: 3
                                    color: modelData.isDir ? Qt.rgba(0.2, 0.5, 1.0, 0.15) : Qt.rgba(0.5, 0.5, 0.5, 0.15)
                                    border.color: modelData.isDir ? themePalette.primary : themePalette.border

                                    Label {
                                        anchors.centerIn: parent
                                        text: modelData.isDir ? "DIR" : "FILE"
                                        font.pixelSize: 10
                                        font.weight: Typography.weightBold
                                        color: parent.border.color
                                    }
                                }

                                Label {
                                    text: modelData.isDir ? "-" : Math.round(modelData.size / 1024) + " KB"
                                    color: themePalette.textSecondary
                                    Layout.preferredWidth: 70
                                }

                                RowLayout {
                                    Layout.preferredWidth: 120
                                    spacing: 4

                                    Button {
                                        text: modelData.isDir ? "Open" : "⬅ Download"
                                        onClicked: {
                                            if (modelData.isDir) {
                                                let nextPath = sessionClient.currentRemotePath === "." ? modelData.name : sessionClient.currentRemotePath + "/" + modelData.name
                                                sessionClient.requestDirectoryListing(nextPath)
                                            } else {
                                                let fullPath = sessionClient.currentRemotePath === "." ? modelData.name : sessionClient.currentRemotePath + "/" + modelData.name
                                                sessionClient.startFileDownload(fullPath, sessionClient.currentLocalPath)
                                            }
                                        }
                                    }

                                    Button {
                                        text: "🗑️"
                                        onClicked: {
                                            let fullPath = sessionClient.currentRemotePath === "." ? modelData.name : sessionClient.currentRemotePath + "/" + modelData.name
                                            sessionClient.deleteRemoteFile(fullPath)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // BOTTOM PANEL: Active File Transfer Status & Progress Bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 85
            color: themePalette.surface
            radius: Metrics.radiusSm
            border.color: themePalette.border
            visible: sessionClient.isConnected

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Metrics.spacingSm
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: "Status: " + sessionClient.transferStatus
                        font.weight: Typography.weightBold
                        color: themePalette.textPrimary
                    }
                    Item { Layout.fillWidth: true }
                    Label {
                        text: "Speed: " + sessionClient.transferSpeed
                        font.weight: Typography.weightBold
                        color: themePalette.primary
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 12
                    color: themePalette.surfaceVariant
                    radius: 6

                    Rectangle {
                        width: parent.width * sessionClient.transferProgress
                        height: parent.height
                        color: themePalette.primary
                        radius: 6
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Metrics.spacingSm
                    Button { text: "Pause"; onClicked: sessionClient.pauseFileTransfer() }
                    Button { text: "Resume"; onClicked: sessionClient.resumeFileTransfer() }
                    Button { text: "Cancel"; onClicked: sessionClient.cancelFileTransfer() }
                    Item { Layout.fillWidth: true }
                    Label { text: Math.round(sessionClient.transferProgress * 100) + "%"; color: themePalette.textSecondary }
                }
            }
        }
    }
}
