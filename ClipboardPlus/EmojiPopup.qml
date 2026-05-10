import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Widgets

PanelWindow {
    id: root

    required property ShellScreen screen
    property var pluginApi: null
    property real lastMouseX: 0
    property real lastMouseY: 0
    property real popupX: 0
    property real popupY: 0

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true
    visible: false
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "dms-clipboardPlus-emoji-" + (screen?.name || "unknown")
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    readonly property real popupWidth: Math.min((screen?.width || 480) - Theme.spacingL * 2, Math.max(320, pluginApi?.pluginSettings?.emojiPopupWidth ?? 420))
    readonly property real popupHeight: Math.min((screen?.height || 560) - Theme.spacingL * 2, Math.max(320, pluginApi?.pluginSettings?.emojiPopupHeight ?? 520))

    function updatePopupPosition() {
        const sx = (screen && screen.width) ? screen.width : (Screen.width || 0);
        const sy = (screen && screen.height) ? screen.height : (Screen.height || 0);
        const rawX = mouseCapture.mouseX || root.lastMouseX || Math.round(sx / 2);
        const rawY = mouseCapture.mouseY || root.lastMouseY || Math.round(sy / 2);
        const px = Math.max(Theme.spacingL, Math.min(Math.max(Theme.spacingL, sx - popupWidth - Theme.spacingL), rawX - popupWidth * 0.25));
        const py = Math.max(Theme.spacingL, Math.min(Math.max(Theme.spacingL, sy - popupHeight - Theme.spacingL), rawY - 24));
        popupX = isFinite(px) ? px : Math.max(Theme.spacingL, (sx - popupWidth) / 2);
        popupY = isFinite(py) ? py : Math.max(Theme.spacingL, (sy - popupHeight) / 2);
    }

    function setOpen(state) {
        visible = state;
        if (state) {
            updatePopupPosition();
            repositionTimer.restart();
            Qt.callLater(() => emojiSelector.focusSearchField());
        } else {
            repositionTimer.stop();
        }
    }

    Timer {
        id: repositionTimer
        interval: 16
        repeat: true
        property int ticks: 0

        onTriggered: {
            updatePopupPosition();
            ticks++;
            if (ticks >= 3)
                stop();
        }

        onRunningChanged: {
            if (running)
                ticks = 0;
        }
    }

    MouseArea {
        id: mouseCapture
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        z: 0

        onPositionChanged: function(mouse) {
            root.lastMouseX = mouse.x;
            root.lastMouseY = mouse.y;
        }

        onClicked: {
            root.pluginApi?.closePanel(screen);
        }
    }

    Rectangle {
        id: popupContainer
        x: root.popupX
        y: root.popupY
        z: 1
        width: root.popupWidth
        height: root.popupHeight
        color: Theme.withAlpha(Theme.surfaceContainer, Theme.popupTransparency)
        radius: Theme.cornerRadius
        border.color: Theme.outlineMedium
        border.width: 1
        visible: root.visible
        focus: root.visible

        Keys.onEscapePressed: {
            root.pluginApi?.closePanel(screen);
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    text: "Emoji & Unicode"
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                }

                Item {
                    Layout.fillWidth: true
                }

                DankActionButton {
                    iconName: "close"
                    tooltipText: "Close"
                    backgroundColor: Theme.surfaceContainerHigh
                    iconColor: Theme.surfaceText
                    onClicked: root.pluginApi?.closePanel(screen)
                }
            }

            EmojiUnicodePanel {
                id: emojiSelector
                Layout.fillWidth: true
                Layout.fillHeight: true
                pluginApi: root.pluginApi
                screen: root.screen
                standaloneMode: true
                trapTabNavigation: true
                focusSearchOnOpen: root.visible
                onTabForwardRequested: focusSearchField()
                onTabBackwardRequested: focusSearchField()
            }
        }
    }
}
