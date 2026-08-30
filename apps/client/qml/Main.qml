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
    property int currentViewIndex: 0
    property bool isFullScreen: false
    visibility: isFullScreen ? Window.FullScreen : Window.Windowed

    Shortcut { sequence: "F11"; onActivated: mainWindow.isFullScreen = !mainWindow.isFullScreen }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        Accessible.role: Accessible.Pane
        Accessible.name: "Remote Access Platform Desktop Viewer"
        Accessible.description: "Enterprise cross-platform remote desktop viewer and management client"

        HeaderBar { id: headerBar; visible: !mainWindow.isFullScreen }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            SidebarNav {
                id: sidebarNav
                visible: !mainWindow.isFullScreen
                currentViewIndex: mainWindow.currentViewIndex
                onNavigateTo: (index) => mainWindow.currentViewIndex = index
            }

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

        StatusBar { id: statusBar; visible: !mainWindow.isFullScreen }
    }

    ToastNotification { id: toastManager }
    OnboardingOverlay { id: onboardingTour }

    function showToast(message, type) { toastManager.showToast(message, type || "info") }

    Component.onCompleted: showToast("Remote Access Platform loaded successfully", "success")

    Connections {
        target: sessionClient
        function onConnectionStateChanged(connected) {
            showToast(connected ? "Connected to remote host — session active" : "Disconnected from remote host", connected ? "success" : "warning")
        }
    }
}
