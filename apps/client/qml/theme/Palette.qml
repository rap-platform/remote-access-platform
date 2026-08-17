pragma Singleton
import QtQuick

QtObject {
    id: palette

    // Dark Mode Semantic Palette Tokens (Default)
    readonly property color background: "#121418"
    readonly property color surface: "#1a1d24"
    readonly property color surfaceVariant: "#242832"
    readonly property color border: "#323846"
    readonly property color borderFocused: "#4f86f7"

    // Primary & Accent Colors
    readonly property color primary: "#3b82f6"
    readonly property color primaryHover: "#2563eb"
    readonly property color accent: "#8b5cf6"

    // Text & Content Tokens
    readonly property color textPrimary: "#f3f4f6"
    readonly property color textSecondary: "#9ca3af"
    readonly property color textMuted: "#6b7280"
    readonly property color textOnPrimary: "#ffffff"

    // State Colors
    readonly property color success: "#10b981"
    readonly property color warning: "#f59e0b"
    readonly property color error: "#ef4444"
    readonly property color info: "#06b6d4"
}
