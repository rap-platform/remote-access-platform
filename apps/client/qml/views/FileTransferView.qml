import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: fileTransferView
    color: themePalette.background

    // Search & filter state
    property string localSearchText: ""
    property string remoteSearchText: ""
    property int localFilterType: 0  // 0: All, 1: Dirs only, 2: Files only
    property int remoteFilterType: 0

    function filterItems(items, searchText, filterType) {
        let result = []
        for (let i = 0; i < items.length; i++) {
            let item = items[i]
            let matchesSearch = searchText.length === 0 || item.name.toLowerCase().includes(searchText.toLowerCase())
            let matchesFilter = filterType === 0 || (filterType === 1 && item.isDir) || (filterType === 2 && !item.isDir)
            if (matchesSearch && matchesFilter) {
                result.push(item)
            }
        }
        return result
    }

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

                    // File Search & Filter Bar (Local)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Metrics.spacingXs

                        TextField {
                            id: localSearchField
                            Layout.fillWidth: true
                            placeholderText: "🔍 Search files..."
                            text: fileTransferView.localSearchText
                            selectByMouse: true
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontCaption
                            color: themePalette.textPrimary
                            onTextChanged: fileTransferView.localSearchText = text
                            background: Rectangle {
                                color: themePalette.surfaceVariant
                                border.color: localSearchField.activeFocus ? themePalette.primary : themePalette.border
                                radius: Metrics.radiusSm
                            }
                        }

                        ComboBox {
                            id: localFilterCombo
                            Layout.preferredWidth: 120
                            Layout.preferredHeight: 30
                            model: ["All", "Dirs Only", "Files Only"]
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontCaption
                            currentIndex: fileTransferView.localFilterType
                            onActivated: (index) => { fileTransferView.localFilterType = index }
                            background: Rectangle {
                                color: themePalette.surfaceVariant
                                border.color: themePalette.border
                                radius: Metrics.radiusSm
                            }
                        }
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
                        model: fileTransferView.filterItems(sessionClient.localDirectoryList, fileTransferView.localSearchText, fileTransferView.localFilterType)

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
                border.color: remoteDropArea.containsDrag ? themePalette.primary : themePalette.border
                border.width: remoteDropArea.containsDrag ? 2 : 1

                // Drag-and-Drop overlay for file uploads
                DropArea {
                    id: remoteDropArea
                    anchors.fill: parent
                    onDropped: (drop) => {
                        if (drop.hasUrls) {
                            for (let i = 0; i < drop.urls.length; i++) {
                                let localPath = drop.urls[i].toString().replace("file:///", "")
                                sessionClient.startFileUpload(localPath, sessionClient.currentRemotePath)
                            }
                            if (typeof mainWindow !== "undefined" && typeof mainWindow.showToast === "function") {
                                mainWindow.showToast("Uploading " + drop.urls.length + " file(s)...", "info")
                            }
                        }
                    }
                }

                // Drop zone visual indicator
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: Metrics.spacingMd
                    visible: remoteDropArea.containsDrag
                    color: Qt.rgba(themePalette.primary.r, themePalette.primary.g, themePalette.primary.b, 0.08)
                    radius: Metrics.radiusMd
                    border.color: themePalette.primary
                    border.width: 2
                    z: 50

                    Column {
                        anchors.centerIn: parent
                        spacing: Metrics.spacingSm
                        Text {
                            text: "📂"
                            font.pixelSize: 42
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: "Drop files here to upload"
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontBody
                            font.weight: Typography.weightBold
                            color: themePalette.primary
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }

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

                    // File Search & Filter Bar (Remote)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Metrics.spacingXs

                        TextField {
                            id: remoteSearchField
                            Layout.fillWidth: true
                            placeholderText: "🔍 Search remote files..."
                            text: fileTransferView.remoteSearchText
                            selectByMouse: true
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontCaption
                            color: themePalette.textPrimary
                            onTextChanged: fileTransferView.remoteSearchText = text
                            background: Rectangle {
                                color: themePalette.surfaceVariant
                                border.color: remoteSearchField.activeFocus ? themePalette.primary : themePalette.border
                                radius: Metrics.radiusSm
                            }
                        }

                        ComboBox {
                            id: remoteFilterCombo
                            Layout.preferredWidth: 120
                            Layout.preferredHeight: 30
                            model: ["All", "Dirs Only", "Files Only"]
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontCaption
                            currentIndex: fileTransferView.remoteFilterType
                            onActivated: (index) => { fileTransferView.remoteFilterType = index }
                            background: Rectangle {
                                color: themePalette.surfaceVariant
                                border.color: themePalette.border
                                radius: Metrics.radiusSm
                            }
                        }
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
                        model: fileTransferView.filterItems(sessionClient.directoryList, fileTransferView.remoteSearchText, fileTransferView.remoteFilterType)

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
