import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: settingsView
    color: themePalette.background

    property int activeCategory: 0

    ScrollView {
        anchors.fill: parent
        anchors.margins: Metrics.spacingMd

        ColumnLayout {
            width: parent.width
            spacing: Metrics.spacingMd

            // Header
            Label {
                text: "⚙️ Settings & Preferences"
                font.family: Typography.fontFamily
                font.pixelSize: Typography.fontHeadline
                font.weight: Typography.weightBold
                color: themePalette.textPrimary
            }

            Label {
                text: "Configure client behavior, display quality, network, and security options."
                font.family: Typography.fontFamily
                font.pixelSize: Typography.fontBody
                color: themePalette.textSecondary
            }

            // Category Tab Bar
            RowLayout {
                Layout.fillWidth: true
                spacing: Metrics.spacingXs

                Repeater {
                    model: ["General", "Display", "Network", "Security", "Shortcuts", "About"]

                    delegate: Button {
                        text: modelData
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.fontCaption
                        font.weight: settingsView.activeCategory === index ? Typography.weightBold : Typography.weightMedium
                        onClicked: settingsView.activeCategory = index
                        background: Rectangle {
                            color: settingsView.activeCategory === index ? themePalette.primary : themePalette.surface
                            radius: Metrics.radiusSm
                            border.color: settingsView.activeCategory === index ? themePalette.primary : themePalette.border
                        }
                        contentItem: Text {
                            text: parent.text
                            font: parent.font
                            color: settingsView.activeCategory === index ? "#FFFFFF" : themePalette.textPrimary
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: themePalette.border }

            // ─── GENERAL ────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Metrics.spacingSm
                visible: settingsView.activeCategory === 0

                // Setting Card: Language Selection
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    color: themePalette.surface
                    radius: Metrics.radiusSm
                    border.color: themePalette.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Metrics.spacingMd
                        Label { text: "🌐 Application Language"; font.family: Typography.fontFamily; font.pixelSize: Typography.fontBody; color: themePalette.textPrimary; Layout.fillWidth: true }
                        ComboBox {
                            id: languageCombo
                            model: ["English", "German", "French", "Spanish", "Japanese", "Hindi"]
                            Layout.preferredWidth: 180
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontCaption
                            currentIndex: model.indexOf(sessionClient.currentLanguage) >= 0 ? model.indexOf(sessionClient.currentLanguage) : 0
                            onActivated: (index) => {
                                let selectedLang = model[index]
                                sessionClient.setLanguage(selectedLang)
                                if (typeof mainWindow !== "undefined" && typeof mainWindow.showToast === "function") {
                                    mainWindow.showToast("Language changed to " + selectedLang, "success")
                                }
                            }
                        }
                    }
                }

                // Setting Card: Theme Selection
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    color: themePalette.surface
                    radius: Metrics.radiusSm
                    border.color: themePalette.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Metrics.spacingMd
                        Label { text: "🎨 Application Color Theme"; font.family: Typography.fontFamily; font.pixelSize: Typography.fontBody; color: themePalette.textPrimary; Layout.fillWidth: true }
                        ComboBox {
                            id: themeCombo
                            model: ["Catppuccin Dark", "Tokyo Night", "Nord Dark", "Enterprise Light", "High Contrast"]
                            Layout.preferredWidth: 180
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontCaption
                            currentIndex: themePalette.currentTheme
                            onActivated: (index) => {
                                themePalette.setTheme(index)
                                if (typeof mainWindow !== "undefined" && typeof mainWindow.showToast === "function") {
                                    mainWindow.showToast("Theme changed to " + model[index], "info")
                                }
                            }
                        }
                    }
                }

                // Setting Card: Startup behavior
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    color: themePalette.surface
                    radius: Metrics.radiusSm
                    border.color: themePalette.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Metrics.spacingMd
                        Label { text: "🚀 Launch on System Startup"; font.family: Typography.fontFamily; font.pixelSize: Typography.fontBody; color: themePalette.textPrimary; Layout.fillWidth: true }
                        Switch { checked: false }
                    }
                }

                // Setting Card: Minimize to tray
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    color: themePalette.surface
                    radius: Metrics.radiusSm
                    border.color: themePalette.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Metrics.spacingMd
                        Label { text: "📥 Minimize to System Tray"; font.family: Typography.fontFamily; font.pixelSize: Typography.fontBody; color: themePalette.textPrimary; Layout.fillWidth: true }
                        Switch { checked: true }
                    }
                }

                // Setting Card: Check for updates
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    color: themePalette.surface
                    radius: Metrics.radiusSm
                    border.color: themePalette.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Metrics.spacingMd
                        Label { text: "🔄 Auto-Check for Updates"; font.family: Typography.fontFamily; font.pixelSize: Typography.fontBody; color: themePalette.textPrimary; Layout.fillWidth: true }
                        Switch { checked: true }
                    }
                }
            }

            // ─── DISPLAY ────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Metrics.spacingSm
                visible: settingsView.activeCategory === 1

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    color: themePalette.surface
                    radius: Metrics.radiusSm
                    border.color: themePalette.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Metrics.spacingMd
                        Label { text: "🎞️ Default Quality Preset"; font.family: Typography.fontFamily; font.pixelSize: Typography.fontBody; color: themePalette.textPrimary; Layout.fillWidth: true }
                        ComboBox {
                            model: ["Highest Quality", "Balanced", "Performance", "Low Bandwidth"]
                            Layout.preferredWidth: 200
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontCaption
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    color: themePalette.surface
                    radius: Metrics.radiusSm
                    border.color: themePalette.border

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Metrics.spacingMd
                        RowLayout {
                            Label { text: "⚡ Maximum FPS"; font.family: Typography.fontFamily; font.pixelSize: Typography.fontBody; color: themePalette.textPrimary; Layout.fillWidth: true }
                            Label { id: fpsLabel; text: fpsSlider.value + " fps"; font.family: Typography.fontFamily; font.pixelSize: Typography.fontCaption; font.weight: Typography.weightBold; color: themePalette.primary }
                        }
                        Slider {
                            id: fpsSlider
                            Layout.fillWidth: true
                            from: 10; to: 120; stepSize: 5; value: 60
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    color: themePalette.surface
                    radius: Metrics.radiusSm
                    border.color: themePalette.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Metrics.spacingMd
                        Label { text: "🎨 Color Depth"; font.family: Typography.fontFamily; font.pixelSize: Typography.fontBody; color: themePalette.textPrimary; Layout.fillWidth: true }
                        ComboBox {
                            model: ["32-bit (True Color)", "24-bit", "16-bit", "8-bit (Low)"]
                            Layout.preferredWidth: 200
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontCaption
                        }
                    }
                }
            }

            // ─── NETWORK ────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Metrics.spacingSm
                visible: settingsView.activeCategory === 2

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    color: themePalette.surface
                    radius: Metrics.radiusSm
                    border.color: themePalette.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Metrics.spacingMd
                        Label { text: "🌐 Custom Relay Server"; font.family: Typography.fontFamily; font.pixelSize: Typography.fontBody; color: themePalette.textPrimary; Layout.fillWidth: true }
                        TextField {
                            placeholderText: "relay.example.com:443"
                            Layout.preferredWidth: 220
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontCaption
                            color: themePalette.textPrimary
                            background: Rectangle { color: themePalette.surfaceVariant; radius: Metrics.radiusSm; border.color: themePalette.border }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    color: themePalette.surface
                    radius: Metrics.radiusSm
                    border.color: themePalette.border

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Metrics.spacingMd
                        RowLayout {
                            Label { text: "📊 Bandwidth Limit"; font.family: Typography.fontFamily; font.pixelSize: Typography.fontBody; color: themePalette.textPrimary; Layout.fillWidth: true }
                            Label { text: bwSlider.value + " Mbps"; font.family: Typography.fontFamily; font.pixelSize: Typography.fontCaption; font.weight: Typography.weightBold; color: themePalette.primary }
                        }
                        Slider {
                            id: bwSlider
                            Layout.fillWidth: true
                            from: 1; to: 100; stepSize: 1; value: 50
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    color: themePalette.surface
                    radius: Metrics.radiusSm
                    border.color: themePalette.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Metrics.spacingMd
                        Label { text: "🔌 Use SOCKS5 Proxy"; font.family: Typography.fontFamily; font.pixelSize: Typography.fontBody; color: themePalette.textPrimary; Layout.fillWidth: true }
                        Switch { checked: false }
                    }
                }
            }

            // ─── SECURITY ───────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Metrics.spacingSm
                visible: settingsView.activeCategory === 3

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    color: themePalette.surface
                    radius: Metrics.radiusSm
                    border.color: themePalette.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Metrics.spacingMd
                        Label { text: "📋 Clipboard Sync"; font.family: Typography.fontFamily; font.pixelSize: Typography.fontBody; color: themePalette.textPrimary; Layout.fillWidth: true }
                        Switch { checked: true }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    color: themePalette.surface
                    radius: Metrics.radiusSm
                    border.color: themePalette.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Metrics.spacingMd
                        Label { text: "📂 Allow File Transfers"; font.family: Typography.fontFamily; font.pixelSize: Typography.fontBody; color: themePalette.textPrimary; Layout.fillWidth: true }
                        Switch { checked: true }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    color: themePalette.surface
                    radius: Metrics.radiusSm
                    border.color: themePalette.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Metrics.spacingMd
                        Label { text: "🔒 Auto-Lock Timeout"; font.family: Typography.fontFamily; font.pixelSize: Typography.fontBody; color: themePalette.textPrimary; Layout.fillWidth: true }
                        ComboBox {
                            model: ["Never", "5 minutes", "15 minutes", "30 minutes", "1 hour"]
                            Layout.preferredWidth: 180
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontCaption
                        }
                    }
                }
            }

            // ─── SHORTCUTS ──────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Metrics.spacingSm
                visible: settingsView.activeCategory === 4

                Repeater {
                    model: [
                        { action: "Toggle Fullscreen", shortcut: "F11" },
                        { action: "Disconnect Session", shortcut: "Ctrl+Shift+D" },
                        { action: "Open File Transfer", shortcut: "Ctrl+Shift+F" },
                        { action: "Toggle Chat Panel", shortcut: "Ctrl+Shift+C" },
                        { action: "Toggle Performance HUD", shortcut: "Ctrl+Shift+P" },
                        { action: "Take Screenshot", shortcut: "Ctrl+Shift+S" },
                        { action: "Toggle Audio Mute", shortcut: "Ctrl+Shift+M" }
                    ]

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        color: themePalette.surface
                        radius: Metrics.radiusSm
                        border.color: themePalette.border

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Metrics.spacingMd
                            Label {
                                text: "⌨️ " + modelData.action
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.fontBody
                                color: themePalette.textPrimary
                                Layout.fillWidth: true
                            }
                            Rectangle {
                                Layout.preferredWidth: shortcutLabel.implicitWidth + Metrics.spacingMd * 2
                                Layout.preferredHeight: 28
                                color: themePalette.surfaceVariant
                                radius: Metrics.radiusSm
                                border.color: themePalette.border

                                Label {
                                    id: shortcutLabel
                                    anchors.centerIn: parent
                                    text: modelData.shortcut
                                    font.family: Typography.fontFamily
                                    font.pixelSize: Typography.fontCaption
                                    font.weight: Typography.weightBold
                                    color: themePalette.primary
                                }
                            }
                        }
                    }
                }
            }

            // ─── ABOUT ──────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Metrics.spacingSm
                visible: settingsView.activeCategory === 5

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 180
                    color: themePalette.surface
                    radius: Metrics.radiusMd
                    border.color: themePalette.border

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Metrics.spacingLg
                        spacing: Metrics.spacingSm

                        Label {
                            text: "🚀 Remote Access Platform"
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontTitle
                            font.weight: Typography.weightBold
                            color: themePalette.textPrimary
                        }

                        Label {
                            text: "Version: " + (typeof APP_VERSION !== "undefined" ? APP_VERSION : "0.3.1-dev")
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontBody
                            color: themePalette.textSecondary
                        }

                        Label {
                            text: "License: LGPLv3 (Dynamic Linking)"
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontBody
                            color: themePalette.textSecondary
                        }

                        Label {
                            text: "Built with Qt 6 / QML • C++20 • Rust Microservices"
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontCaption
                            color: themePalette.textSecondary
                        }

                        Label {
                            text: "© 2026 Remote Access Platform Contributors"
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.fontCaption
                            color: themePalette.textSecondary
                        }
                    }
                }
            }
        }
    }
}
