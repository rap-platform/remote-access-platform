import QtQuick

QtObject {
    id: palette

    // Active Theme Mode (0: Catppuccin Dark, 1: Tokyo Night, 2: Nordic Frost, 3: GitHub Dark, 4: Enterprise Light)
    property int currentTheme: 0
    property string currentThemeName: "Catppuccin Dark"

    // Active Theme Token Properties Initialized with Valid Catppuccin Dark Defaults
    property color background: "#181825"
    property color surface: "#1e1e2e"
    property color surfaceVariant: "#313244"
    property color border: "#45475a"
    property color primary: "#89b4fa"
    property color accent: "#cba6f7"
    property color textPrimary: "#cdd6f4"
    property color textSecondary: "#a6adc8"
    property color error: "#f38ba8"
    property color success: "#a6e3a1"
    property color warning: "#f9e2af"
    readonly property color transparent: "transparent"

    function setTheme(mode) {
        currentTheme = mode
        if (mode === 1) {
            currentThemeName = "Tokyo Night"
            background = "#1a1b26"; surface = "#24283b"; surfaceVariant = "#414868"
            border = "#565f89"; primary = "#7aa2f7"; accent = "#bb9af7"
            textPrimary = "#c0caf5"; textSecondary = "#9aa5ce"
            error = "#f7768e"; success = "#9ece6a"; warning = "#e0af68"
        } else if (mode === 2) {
            currentThemeName = "Nordic Frost"
            background = "#2e3440"; surface = "#3b4252"; surfaceVariant = "#434c5e"
            border = "#4c566a"; primary = "#88c0d0"; accent = "#81a1c1"
            textPrimary = "#eceff4"; textSecondary = "#d8dee9"
            error = "#bf616a"; success = "#a3be8c"; warning = "#ebcb8b"
        } else if (mode === 3) {
            currentThemeName = "GitHub Dark"
            background = "#0d1117"; surface = "#161b22"; surfaceVariant = "#21262d"
            border = "#30363d"; primary = "#58a6ff"; accent = "#bc8cff"
            textPrimary = "#c9d1d9"; textSecondary = "#8b949e"
            error = "#f85149"; success = "#3fb950"; warning = "#d29922"
        } else if (mode === 4) {
            currentThemeName = "Enterprise Light"
            background = "#f8f9fa"; surface = "#ffffff"; surfaceVariant = "#e9ecef"
            border = "#ced4da"; primary = "#0d6efd"; accent = "#6f42c1"
            textPrimary = "#212529"; textSecondary = "#6c757d"
            error = "#dc3545"; success = "#198754"; warning = "#ffc107"
        } else {
            currentThemeName = "Catppuccin Dark"
            background = "#181825"; surface = "#1e1e2e"; surfaceVariant = "#313244"
            border = "#45475a"; primary = "#89b4fa"; accent = "#cba6f7"
            textPrimary = "#cdd6f4"; textSecondary = "#a6adc8"
            error = "#f38ba8"; success = "#a6e3a1"; warning = "#f9e2af"
        }
    }
}
