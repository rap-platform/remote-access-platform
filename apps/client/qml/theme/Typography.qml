pragma Singleton
import QtQuick

QtObject {
    id: typography

    // Font Family
    readonly property string fontFamily: "Inter, Roboto, sans-serif"

    // Size Scale (sp/pt equivalents)
    readonly property int fontCaption: 11
    readonly property int fontBody: 13
    readonly property int fontSubtitle: 15
    readonly property int fontSubheader: 16
    readonly property int fontTitle: 18
    readonly property int fontHeadline: 20
    readonly property int fontHeader: 24
    readonly property int fontDisplay: 32

    // Font Weights
    readonly property int weightNormal: Font.Normal
    readonly property int weightRegular: Font.Normal
    readonly property int weightMedium: Font.Medium
    readonly property int weightBold: Font.Bold
}
