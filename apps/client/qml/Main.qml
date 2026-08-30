import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "theme"
import "components"
import "views"

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 1280
    height: 800
    minimumWidth: 900
    minimumHeight: 600
    title: "Remote Access Platform — Enterprise Desktop Viewer"
    color: themePalette.background

    property int currentViewIndex: 0 // 0: Desktop Session, 1: Saved Devices, 2: Security & Keys, 3: File Transfer, 4: Settings, 5: Terminal Shell
    property bool isFullScreen: false

    visibility: isFullScreen ? Window.FullScreen : Window.Windowed

    Shortcut {
        sequence: "F11"
        onActivated: mainWindow.isFullScreen = !mainWindow.isFullScreen
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        Accessible.role: Accessible.Pane
        Accessible.name: "Remote Access Platform Desktop Viewer"
        Accessible.description: "Enterprise cross-platform remote desktop viewer and management client"

        // Top Navigation Header Bar (Hidden in Fullscreen mode)
        HeaderBar {
            id: headerBar
            visible: !mainWindow.isFullScreen
        }

        // Central Content Area
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Left Navigation Sidebar (Hidden in Fullscreen mode)
            SidebarNav {
                id: sidebarNav
                visible: !mainWindow.isFullScreen
                currentViewIndex: mainWindow.currentViewIndex
                onNavigateTo: (index) => mainWindow.currentViewIndex = index
            }

            // Central Stacked Views
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: mainWindow.currentViewIndex

                DesktopSessionView { id: desktopSessionView }
                SavedDevicesView { id: savedDevicesView }
                SecurityKeysView { id: securityKeysView }
                FileTransferView { id: fileTransferView }
                SettingsView { id: settingsView }
                TerminalView { id: terminalView }
            }
        }

        // Bottom Status Bar (Hidden in Fullscreen mode)
        StatusBar {
            id: statusBar
            visible: !mainWindow.isFullScreen
        }
    }

    // Global Toast Notification System
    ToastNotification {
        id: toastManager
    }

    // Global convenience function for showing toasts from any component
    function showToast(message, type) {
        toastManager.showToast(message, type || "info")
    }

    // Show welcome toast on first load
    Component.onCompleted: {
        showToast("Remote Access Platform loaded successfully", "success")
    }

    // React to connection state changes with toast notifications
    Connections {
        target: sessionClient
        function onConnectionStateChanged(connected) {
            if (connected) {
                showToast("Connected to remote host — session active", "success")
            } else {
                showToast("Disconnected from remote host", "warning")
            }
        }
    }
}
