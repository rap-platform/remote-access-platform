import QtQuick

QtObject {
    id: tokens

    // Animation Duration Tokens (milliseconds)
    readonly property int durationFast: 150
    readonly property int durationNormal: 250
    readonly property int durationSlow: 400

    // Opacity Tokens
    readonly property real opacityDisabled: 0.38
    readonly property real opacityMuted: 0.60
    readonly property real opacityFull: 1.00

    // Easing Curves
    readonly property int easingStandard: Easing.InOutQuad
    readonly property int easingEmphasized: Easing.OutCubic
}
