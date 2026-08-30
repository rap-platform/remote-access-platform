pragma Singleton
import QtQuick

QtObject {
    id: metrics

    // Spacing Scale
    readonly property int spacingXs: 4
    readonly property int spacingSm: 8
    readonly property int spacingMd: 16
    readonly property int spacingLg: 24
    readonly property int spacingXl: 32
    readonly property int spacingXxl: 48

    // Padding Scale
    readonly property int paddingCard: 16
    readonly property int paddingModal: 24

    // Border Radius Scale
    readonly property real radiusSm: 4.0
    readonly property real radiusMd: 8.0
    readonly property real radiusLg: 12.0
    readonly property real radiusFull: 999.0
    readonly property real radiusPill: 999.0
}
