import QtQuick
import qs.Common

Item {
    id: root

    property var level: null
    property real fallbackOffset: 1
    property real targetRadius: 0
    property color targetColor: "black"
    property real shadowOpacity: 0.2
    property bool shadowEnabled: true

    // elevation shadow from dms, but only in git version currently
    ElevationShadow {
        anchors.fill: parent
        level: root.level
        fallbackOffset: root.fallbackOffset
        targetRadius: root.targetRadius
        targetColor: root.targetColor
        shadowOpacity: root.shadowOpacity
        shadowEnabled: root.shadowEnabled
    }
}
