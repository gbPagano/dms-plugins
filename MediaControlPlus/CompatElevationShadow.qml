import QtQuick

// A component with fallback
Item {
    id: root

    property var level: null
    property real fallbackOffset: 1
    property real targetRadius: 0
    property color targetColor: "black"
    property real shadowOpacity: 0.2
    property bool shadowEnabled: true

    function syncNative() {
        if (!nativeShadowLoader.item)
            return;
        nativeShadowLoader.item.level = Qt.binding(() => root.level);
        nativeShadowLoader.item.fallbackOffset = Qt.binding(() => root.fallbackOffset);
        nativeShadowLoader.item.targetRadius = Qt.binding(() => root.targetRadius);
        nativeShadowLoader.item.targetColor = Qt.binding(() => root.targetColor);
        nativeShadowLoader.item.shadowOpacity = Qt.binding(() => root.shadowOpacity);
        nativeShadowLoader.item.shadowEnabled = Qt.binding(() => root.shadowEnabled);
    }

    Loader {
        id: nativeShadowLoader
        anchors.fill: parent
        source: Qt.resolvedUrl("NativeElevationShadow.qml")
        asynchronous: false
        visible: status === Loader.Ready

        onLoaded: root.syncNative()
    }

    Rectangle {
        anchors.fill: parent
        anchors.verticalCenterOffset: root.fallbackOffset
        visible: nativeShadowLoader.status !== Loader.Ready
        radius: root.targetRadius
        color: root.targetColor
        opacity: root.shadowEnabled ? root.shadowOpacity : 0
        scale: 1.04
    }
}
