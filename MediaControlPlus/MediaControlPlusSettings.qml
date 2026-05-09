import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root

    pluginId: "mediaControlPlus"

    property int currentTab: 0
    readonly property var colorOptions: [
        {
            label: "Widget Text",
            value: "widgetText"
        },
        {
            label: "Primary",
            value: "primary"
        },
        {
            label: "Primary Text",
            value: "primaryText"
        },
        {
            label: "Primary Container",
            value: "primaryContainer"
        },
        {
            label: "Secondary",
            value: "secondary"
        },
        {
            label: "Surface",
            value: "surface"
        },
        {
            label: "Surface Text",
            value: "surfaceText"
        },
        {
            label: "Surface Variant",
            value: "surfaceVariant"
        },
        {
            label: "Surface Variant Text",
            value: "surfaceVariantText"
        },
        {
            label: "Surface Tint",
            value: "surfaceTint"
        },
        {
            label: "Background",
            value: "background"
        },
        {
            label: "Background Text",
            value: "backgroundText"
        },
        {
            label: "Outline",
            value: "outline"
        },
        {
            label: "Surface Container",
            value: "surfaceContainer"
        },
        {
            label: "Surface Container High",
            value: "surfaceContainerHigh"
        },
        {
            label: "Surface Container Highest",
            value: "surfaceContainerHighest"
        },
        {
            label: "Error",
            value: "error"
        },
        {
            label: "Warning",
            value: "warning"
        },
        {
            label: "Info",
            value: "info"
        },
        {
            label: "Custom",
            value: "custom"
        }
    ]

    function reloadNestedSettings(item) {
        if (!item)
            return;
        if (item !== root && item.loadValue)
            item.loadValue();

        const children = item.children || [];
        for (let i = 0; i < children.length; i++)
            reloadNestedSettings(children[i]);

        const data = item.data || [];
        for (let i = 0; i < data.length; i++) {
            const child = data[i];
            if (child && children.indexOf(child) === -1)
                reloadNestedSettings(child);
        }
    }

    function refreshSettingsUi() {
        root.reloadNestedSettings(root);
        initLayoutOrderModel(horizontalLayoutOrderModel, loadValue("horizontalLayoutOrder", "visualizer,title,controls"));
        initLayoutOrderModel(verticalLayoutOrderModel, loadValue("verticalLayoutOrder", "visualizer,title,controls"));
        settingsTabBar.currentIndex = root.currentTab;
        Qt.callLater(() => settingsTabBar.updateIndicator());
    }

    function resetVisualizerSettings(prefix) {
        const defaults = {
            SourceMode: "mediaOnly",
            AlwaysVisible: false,
            Style: "bars",
            BarAlignment: "center",
            ColorKey: "primary",
            UseGradient: false,
            GradientStartKey: "primary",
            GradientEndKey: "secondary",
            CustomColor: Theme.primary.toString(),
            GradientStartCustomColor: Theme.primary.toString(),
            GradientEndCustomColor: Theme.secondary.toString(),
            ChannelMode: "mono",
            ResponseCurve: 50,
            Attack: 75,
            Release: 35,
            PeakHold: false,
            PeakHoldMs: 450
        };
        for (const suffix in defaults)
            root.saveValue(prefix + suffix, defaults[suffix]);
        Qt.callLater(() => root.refreshSettingsUi());
    }

    readonly property var visualizerSourceOptions: [
        {
            label: "Media Only",
            value: "mediaOnly"
        },
        {
            label: "All Audio",
            value: "allAudio"
        }
    ]

    readonly property var visualizerStyleOptions: [
        {
            label: "Bar Mode",
            value: "bars"
        },
        {
            label: "Dotted Particles",
            value: "dottedParticles"
        },
        {
            label: "Line Wave",
            value: "lineWave"
        }
    ]

    readonly property var visualizerAlignmentOptions: [
        {
            label: "Top",
            value: "top"
        },
        {
            label: "Center",
            value: "center"
        },
        {
            label: "Bottom",
            value: "bottom"
        }
    ]

    readonly property var visualizerChannelOptions: [
        {
            label: "Mono",
            value: "mono"
        },
        {
            label: "Mock Stereo Split",
            value: "split"
        },
        {
            label: "Mock Stereo Mirrored",
            value: "splitReverse"
        },
        {
            label: "Center Out",
            value: "centerOut"
        },
        {
            label: "Outside In",
            value: "outsideIn"
        }
    ]

    ListModel {
        id: horizontalLayoutOrderModel
    }

    ListModel {
        id: verticalLayoutOrderModel
    }

    function defaultLayoutOrder() {
        return ["visualizer", "title", "controls"];
    }

    function labelForLayoutKey(key) {
        switch (key) {
        case "visualizer":
            return "Visualizer";
        case "title":
            return "Title";
        case "controls":
            return "Controls";
        default:
            return key;
        }
    }

    function initLayoutOrderModel(model, rawOrder) {
        const defaultOrder = defaultLayoutOrder();
        const parsedOrder = rawOrder ? rawOrder.split(/[,\s]+/).filter(Boolean) : [];
        const seen = {};
        const finalOrder = [];
        for (let i = 0; i < parsedOrder.length; i++) {
            const key = parsedOrder[i];
            if (defaultOrder.indexOf(key) === -1 || seen[key])
                continue;
            seen[key] = true;
            finalOrder.push(key);
        }
        for (let i = 0; i < defaultOrder.length; i++) {
            const key = defaultOrder[i];
            if (!seen[key])
                finalOrder.push(key);
        }
        model.clear();
        for (let i = 0; i < finalOrder.length; i++) {
            const key = finalOrder[i];
            model.append({
                key: key,
                label: labelForLayoutKey(key)
            });
        }
    }

    function saveLayoutOrderModel(model, settingKey) {
        const order = [];
        for (let i = 0; i < model.count; i++)
            order.push(model.get(i).key);
        saveValue(settingKey, order.join(","));
    }

    function moveLayoutOrderItem(model, settingKey, fromIndex, toIndex) {
        if (fromIndex === toIndex || fromIndex < 0 || toIndex < 0)
            return;
        if (fromIndex >= model.count || toIndex >= model.count)
            return;
        const items = [];
        for (let i = 0; i < model.count; i++) {
            const item = model.get(i);
            items.push({
                key: item.key,
                label: item.label
            });
        }
        const moved = items.splice(fromIndex, 1)[0];
        items.splice(toIndex, 0, moved);
        model.clear();
        for (let i = 0; i < items.length; i++)
            model.append(items[i]);
        saveLayoutOrderModel(model, settingKey);
    }

    Component.onCompleted: Qt.callLater(() => root.refreshSettingsUi())
    onVisibleChanged: {
        if (visible)
            Qt.callLater(() => root.refreshSettingsUi());
    }

    Connections {
        target: root.pluginService
        enabled: root.pluginService !== null

        function onPluginDataChanged(changedPluginId) {
            if (changedPluginId === root.pluginId)
                Qt.callLater(root.refreshSettingsUi);
        }
    }

    component SectionCard: StyledRect {
        id: card
        required property string title
        required property string description
        default property alias sectionContent: contentColumn.data

        width: parent.width
        height: contentColumn.implicitHeight + Theme.spacingL * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainerHigh

        Column {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM

            Column {
                width: parent.width
                spacing: Theme.spacingXS

                StyledText {
                    text: card.title
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                }

                StyledText {
                    width: parent.width
                    text: card.description
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    StyledText {
        width: parent.width
        text: "Media Control Plus Settings"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Split between horizontal, vertical, visualizer, and popout settings so it is easier to tune."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    Item {
        width: parent.width
        height: 45 + Theme.spacingM

        DankTabBar {
            id: settingsTabBar
            width: Math.min(parent.width, 420)
            height: 45
            anchors.horizontalCenter: parent.horizontalCenter
            model: [
                {
                    "text": "General",
                    "icon": "tune"
                },
                {
                    "text": "Horizontal",
                    "icon": "view_stream"
                },
                {
                    "text": "Vertical",
                    "icon": "view_week"
                },
                {
                    "text": "Popout",
                    "icon": "open_in_full"
                }
            ]

            Component.onCompleted: Qt.callLater(updateIndicator)

            onTabClicked: index => {
                root.currentTab = index;
                currentIndex = index;
            }
        }
    }

    Column {
        width: parent.width
        spacing: Theme.spacingM
        visible: root.currentTab === 0

        SectionCard {
            title: "Widget"
            description: "General widget behavior shared across horizontal and vertical bars."

            ToggleSetting {
                settingKey: "showWhenNoPlayer"
                label: "Show When No Player"
                description: "Keep the widget visible even when no active media player is available"
                defaultValue: false
            }

            ToggleSetting {
                settingKey: "rightClickOpensSettings"
                label: "Right Click Opens Settings"
                description: "Open the plugin settings page when the widget is right clicked"
                defaultValue: true
            }

            SelectionSetting {
                settingKey: "scrollVolumeMode"
                label: "Scroll Volume Control"
                description: "Choose whether mouse wheel scrolling changes the system output volume or the active app volume"
                defaultValue: "none"
                options: [
                    {
                        label: "Disabled",
                        value: "none"
                    },
                    {
                        label: "System Volume",
                        value: "sink"
                    },
                    {
                        label: "App Volume",
                        value: "player"
                    }
                ]
            }

            SliderSetting {
                settingKey: "scrollVolumeStep"
                label: "Scroll Volume Step"
                description: "How much volume changes on each mouse wheel step"
                defaultValue: 2
                minimum: 1
                maximum: 20
                unit: "%"
                leftIcon: "swap_vert"
            }
        }
    }

    Column {
        width: parent.width
        spacing: Theme.spacingM
        visible: root.currentTab === 1

        SectionCard {
            title: "Horizontal Layout"
            description: "Settings for the horizontal bar widget."

            ToggleSetting {
                settingKey: "showHorizontalVisualizer"
                label: "Show Horizontal Visualizer"
                description: "Display the audio visualizer in horizontal bars when possible"
                defaultValue: true
            }

            ToggleSetting {
                id: horizontalAlwaysVisualizerToggle
                settingKey: "horizontalVisualizerAlwaysVisible"
                label: "Always Show Horizontal Visualizer"
                description: "Keep the horizontal visualizer visible even when no media player is active"
                defaultValue: false
            }

            ToggleSetting {
                settingKey: "horizontalShowTitleWhenIdle"
                label: "Show Horizontal Title When Idle"
                description: "When the visualizer stays visible without media, also show the title area"
                defaultValue: false
                visible: horizontalAlwaysVisualizerToggle.value
            }

            ToggleSetting {
                settingKey: "horizontalShowControlsWhenIdle"
                label: "Show Horizontal Controls When Idle"
                description: "When the visualizer stays visible without media, also show the control buttons"
                defaultValue: false
                visible: horizontalAlwaysVisualizerToggle.value
            }

            Column {
                width: parent.width
                spacing: Theme.spacingS

                StyledText {
                    text: "Horizontal Element Order"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceText
                }

                StyledText {
                    text: "Rearrange the visualizer, title, and controls in the horizontal widget."
                    font.pixelSize: Theme.fontSizeSmall * 0.9
                    opacity: 0.6
                    width: parent.width
                    wrapMode: Text.Wrap
                }

                ListView {
                    id: horizontalLayoutOrderList
                    width: parent.width
                    height: contentHeight
                    spacing: Theme.spacingS
                    interactive: false
                    model: horizontalLayoutOrderModel

                    delegate: RowLayout {
                        width: horizontalLayoutOrderList.width
                        height: 28
                        spacing: Theme.spacingS
                        readonly property int delegateIndex: index

                        StyledText {
                            text: model.label
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        DankActionButton {
                            width: 26
                            height: 26
                            iconName: "keyboard_arrow_up"
                            backgroundColor: Theme.surfaceContainer
                            iconColor: Theme.surfaceText
                            enabled: delegateIndex > 0
                            onClicked: root.moveLayoutOrderItem(horizontalLayoutOrderModel, "horizontalLayoutOrder", delegateIndex, delegateIndex - 1)
                        }

                        DankActionButton {
                            width: 26
                            height: 26
                            iconName: "keyboard_arrow_down"
                            backgroundColor: Theme.surfaceContainer
                            iconColor: Theme.surfaceText
                            enabled: delegateIndex < horizontalLayoutOrderModel.count - 1
                            onClicked: root.moveLayoutOrderItem(horizontalLayoutOrderModel, "horizontalLayoutOrder", delegateIndex, delegateIndex + 1)
                        }
                    }
                }
            }

            ToggleSetting {
                settingKey: "showHorizontalTitle"
                label: "Show Horizontal Title"
                description: "Display track title and artist in horizontal bars"
                defaultValue: true
            }

            ToggleSetting {
                settingKey: "showHorizontalTitleBackground"
                label: "Horizontal Title Background"
                description: "Add a background behind the horizontal title to improve readability"
                defaultValue: false
            }

            ToggleSetting {
                settingKey: "showHorizontalSkipControls"
                label: "Show Horizontal Previous/Next"
                description: "Show previous and next buttons in horizontal bars"
                defaultValue: true
            }

            ToggleSetting {
                settingKey: "showHorizontalPlayPause"
                label: "Show Horizontal Play/Pause"
                description: "Show the play or pause button in horizontal bars"
                defaultValue: true
            }
        }

        SectionCard {
            title: "Horizontal Title"
            description: "Control how the horizontal title looks and behaves when the text is longer than the available width."

            SliderSetting {
                settingKey: "horizontalTitleExtent"
                label: "Horizontal Title Max Width"
                description: "Maximum width the horizontal title area can use"
                defaultValue: 160
                minimum: 72
                maximum: 420
                unit: "px"
                leftIcon: "width"
            }

            SelectionSetting {
                settingKey: "horizontalTitleScrollBehavior"
                label: "Horizontal Title Scroll"
                description: "Choose when the horizontal title should scroll"
                defaultValue: "never"
                options: [
                    {
                        label: "Never",
                        value: "never"
                    },
                    {
                        label: "Always Scroll",
                        value: "always"
                    },
                    {
                        label: "Scroll On Hover",
                        value: "hover"
                    },
                    {
                        label: "Pause On Hover",
                        value: "pauseOnHover"
                    }
                ]
            }

            SliderSetting {
                settingKey: "horizontalTitleScrollSpeed"
                label: "Horizontal Title Scroll Speed"
                description: "How fast the horizontal title scrolls when scrolling is enabled"
                defaultValue: 28
                minimum: 8
                maximum: 80
                unit: "px/s"
                leftIcon: "swap_horiz"
            }

            SliderSetting {
                settingKey: "horizontalTitlePadding"
                label: "Horizontal Title Padding"
                description: "Inner padding for the horizontal title background"
                defaultValue: 4
                minimum: 0
                maximum: 20
                unit: "px"
                leftIcon: "padding"
            }

            SliderSetting {
                settingKey: "horizontalTitleRadius"
                label: "Horizontal Title Radius"
                description: "Corner radius for the horizontal title background"
                defaultValue: 12
                minimum: 0
                maximum: 32
                unit: "px"
                leftIcon: "rounded_corner"
            }

            SelectionSetting {
                settingKey: "horizontalTitleBackgroundColorKey"
                label: "Horizontal Title Background Color"
                description: "Theme color used for the horizontal title background"
                defaultValue: "surfaceContainer"
                options: root.colorOptions
            }

            SelectionSetting {
                settingKey: "horizontalTitleTextColorKey"
                label: "Horizontal Title Text Color"
                description: "Theme color used for the horizontal title text"
                defaultValue: "widgetText"
                options: root.colorOptions
            }
        }

        SectionCard {
            title: "Horizontal Visualizer Layout"
            description: "Adjust structure, source, and style for the horizontal visualizer."

            Row {
                spacing: Theme.spacingS

                DankActionButton {
                    iconName: "restart_alt"
                    tooltipText: "Reset horizontal visualizer"
                    onClicked: root.resetVisualizerSettings("horizontalVisualizer")
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Reset to defaults"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }

            SliderSetting {
                settingKey: "horizontalVisualizerWidth"
                label: "Horizontal Visualizer Width"
                description: "Adjust the width of the horizontal visualizer"
                defaultValue: 20
                minimum: 12
                maximum: 300
                unit: "px"
                leftIcon: "graphic_eq"
            }

            SliderSetting {
                settingKey: "horizontalVisualizerBars"
                label: "Horizontal Visualizer Bars"
                description: "How many bars to show in the horizontal visualizer"
                defaultValue: 6
                minimum: 3
                maximum: 60
                unit: ""
                leftIcon: "equalizer"
            }

            ToggleSetting {
                settingKey: "horizontalVisualizerStretchToWidth"
                label: "Stretch Horizontal Visualizer"
                description: "Stretch the bars to fill the configured horizontal visualizer width"
                defaultValue: false
            }

            SelectionSetting {
                settingKey: "horizontalVisualizerSourceMode"
                label: "Horizontal Visualizer Source"
                description: "Choose whether the visualizer only reacts to media playback or all system audio"
                defaultValue: "mediaOnly"
                options: root.visualizerSourceOptions
            }

            SelectionSetting {
                settingKey: "horizontalVisualizerStyle"
                label: "Horizontal Visualizer Style"
                description: "Choose between solid bars, dotted bars, or line wave rendering"
                defaultValue: "bars"
                options: root.visualizerStyleOptions
            }

            SelectionSetting {
                settingKey: "horizontalVisualizerBarAlignment"
                label: "Horizontal Bar Alignment"
                description: "Align bar-style rendering to the top, center, or bottom of the visualizer lane"
                defaultValue: "center"
                options: root.visualizerAlignmentOptions
            }

            SelectionSetting {
                settingKey: "horizontalVisualizerChannelMode"
                label: "Horizontal Visualizer Channels"
                description: "Use mono or mock stereo-style layouts for the horizontal visualizer"
                defaultValue: "mono"
                options: root.visualizerChannelOptions
            }
        }

        SectionCard {
            title: "Horizontal Visualizer Colors"
            description: "Control solid and gradient colors for the horizontal visualizer."

            ToggleSetting {
                id: horizontalVisualizerGradientToggle
                settingKey: "horizontalVisualizerUseGradient"
                label: "Use Horizontal Visualizer Gradient"
                description: "Blend the horizontal visualizer between a start and end color"
                defaultValue: false
            }

            SelectionSetting {
                id: horizontalVisualizerColorSetting
                settingKey: "horizontalVisualizerColorKey"
                label: "Horizontal Visualizer Color"
                description: "Theme color used when the horizontal visualizer gradient is disabled"
                defaultValue: "primary"
                options: root.colorOptions
                visible: !horizontalVisualizerGradientToggle.value
            }

            ColorSetting {
                settingKey: "horizontalVisualizerCustomColor"
                label: "Horizontal Custom Visualizer Color"
                description: "Pick a custom solid color for the horizontal visualizer"
                defaultValue: Theme.primary
                visible: !horizontalVisualizerGradientToggle.value && horizontalVisualizerColorSetting.value === "custom"
            }

            SelectionSetting {
                id: horizontalVisualizerGradientStartSetting
                settingKey: "horizontalVisualizerGradientStartKey"
                label: "Horizontal Gradient Start"
                description: "Starting color for the horizontal visualizer gradient"
                defaultValue: "primary"
                options: root.colorOptions
                visible: horizontalVisualizerGradientToggle.value
            }

            ColorSetting {
                settingKey: "horizontalVisualizerGradientStartCustomColor"
                label: "Horizontal Custom Gradient Start"
                description: "Pick a custom start color for the horizontal visualizer gradient"
                defaultValue: Theme.primary
                visible: horizontalVisualizerGradientToggle.value && horizontalVisualizerGradientStartSetting.value === "custom"
            }

            SelectionSetting {
                id: horizontalVisualizerGradientEndSetting
                settingKey: "horizontalVisualizerGradientEndKey"
                label: "Horizontal Gradient End"
                description: "Ending color for the horizontal visualizer gradient"
                defaultValue: "secondary"
                options: root.colorOptions
                visible: horizontalVisualizerGradientToggle.value
            }

            ColorSetting {
                settingKey: "horizontalVisualizerGradientEndCustomColor"
                label: "Horizontal Custom Gradient End"
                description: "Pick a custom end color for the horizontal visualizer gradient"
                defaultValue: Theme.secondary
                visible: horizontalVisualizerGradientToggle.value && horizontalVisualizerGradientEndSetting.value === "custom"
            }
        }

        SectionCard {
            title: "Horizontal Visualizer Motion"
            description: "Tune how quickly the horizontal visualizer responds and settles."

            SliderSetting {
                settingKey: "horizontalVisualizerResponseCurve"
                label: "Horizontal Visualizer Response"
                description: "Shape how strongly quiet versus loud sounds affect the visualizer"
                defaultValue: 50
                minimum: 20
                maximum: 120
                unit: "%"
                leftIcon: "show_chart"
            }

            SliderSetting {
                settingKey: "horizontalVisualizerAttack"
                label: "Horizontal Visualizer Attack"
                description: "How quickly the visualizer rises when the sound gets louder"
                defaultValue: 75
                minimum: 5
                maximum: 100
                unit: "%"
                leftIcon: "trending_up"
            }

            SliderSetting {
                settingKey: "horizontalVisualizerRelease"
                label: "Horizontal Visualizer Release"
                description: "How quickly the visualizer falls when the sound gets quieter"
                defaultValue: 35
                minimum: 5
                maximum: 100
                unit: "%"
                leftIcon: "trending_down"
            }

            ToggleSetting {
                settingKey: "horizontalVisualizerPeakHold"
                label: "Horizontal Peak Hold"
                description: "Show small held peak markers above the horizontal visualizer bars"
                defaultValue: false
            }

            SliderSetting {
                settingKey: "horizontalVisualizerPeakHoldMs"
                label: "Horizontal Peak Hold Time"
                description: "How long the horizontal peak markers stay visible before falling"
                defaultValue: 450
                minimum: 100
                maximum: 1200
                unit: "ms"
                leftIcon: "timer"
            }
        }
    }

    Column {
        width: parent.width
        spacing: Theme.spacingM
        visible: root.currentTab === 2

        SectionCard {
            title: "Vertical Layout"
            description: "Settings for the vertical bar widget."

            ToggleSetting {
                settingKey: "showVerticalVisualizer"
                label: "Show Vertical Visualizer"
                description: "Display the audio visualizer in vertical bars when possible"
                defaultValue: true
            }

            ToggleSetting {
                id: verticalAlwaysVisualizerToggle
                settingKey: "verticalVisualizerAlwaysVisible"
                label: "Always Show Vertical Visualizer"
                description: "Keep the vertical visualizer visible even when no media player is active"
                defaultValue: false
            }

            ToggleSetting {
                settingKey: "verticalShowTitleWhenIdle"
                label: "Show Vertical Title When Idle"
                description: "When the visualizer stays visible without media, also show the title area"
                defaultValue: false
                visible: verticalAlwaysVisualizerToggle.value
            }

            ToggleSetting {
                settingKey: "verticalShowControlsWhenIdle"
                label: "Show Vertical Controls When Idle"
                description: "When the visualizer stays visible without media, also show the control buttons"
                defaultValue: false
                visible: verticalAlwaysVisualizerToggle.value
            }

            Column {
                width: parent.width
                spacing: Theme.spacingS

                StyledText {
                    text: "Vertical Element Order"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceText
                }

                StyledText {
                    text: "Rearrange the visualizer, title, and controls in the vertical widget."
                    font.pixelSize: Theme.fontSizeSmall * 0.9
                    opacity: 0.6
                    width: parent.width
                    wrapMode: Text.Wrap
                }

                ListView {
                    id: verticalLayoutOrderList
                    width: parent.width
                    height: contentHeight
                    spacing: Theme.spacingS
                    interactive: false
                    model: verticalLayoutOrderModel

                    delegate: RowLayout {
                        width: verticalLayoutOrderList.width
                        height: 28
                        spacing: Theme.spacingS
                        readonly property int delegateIndex: index

                        StyledText {
                            text: model.label
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        DankActionButton {
                            width: 26
                            height: 26
                            iconName: "keyboard_arrow_up"
                            backgroundColor: Theme.surfaceContainer
                            iconColor: Theme.surfaceText
                            enabled: delegateIndex > 0
                            onClicked: root.moveLayoutOrderItem(verticalLayoutOrderModel, "verticalLayoutOrder", delegateIndex, delegateIndex - 1)
                        }

                        DankActionButton {
                            width: 26
                            height: 26
                            iconName: "keyboard_arrow_down"
                            backgroundColor: Theme.surfaceContainer
                            iconColor: Theme.surfaceText
                            enabled: delegateIndex < verticalLayoutOrderModel.count - 1
                            onClicked: root.moveLayoutOrderItem(verticalLayoutOrderModel, "verticalLayoutOrder", delegateIndex, delegateIndex + 1)
                        }
                    }
                }
            }

            ToggleSetting {
                settingKey: "showVerticalTitle"
                label: "Show Vertical Title"
                description: "Display track title and artist in vertical bars"
                defaultValue: true
            }

            ToggleSetting {
                settingKey: "showVerticalTitleBackground"
                label: "Vertical Title Background"
                description: "Add a subtle background behind the vertical title to improve readability"
                defaultValue: false
            }

            ToggleSetting {
                settingKey: "showVerticalSkipControls"
                label: "Show Vertical Previous/Next"
                description: "Add previous and next buttons around the play button in vertical bars"
                defaultValue: true
            }

            ToggleSetting {
                settingKey: "showVerticalPlayPause"
                label: "Show Vertical Play/Pause"
                description: "Show the play or pause button in vertical bars"
                defaultValue: true
            }
        }

        SectionCard {
            title: "Vertical Title"
            description: "Control how the vertical title looks and behaves when the text is longer than the available space."

            SliderSetting {
                settingKey: "verticalTitleExtent"
                label: "Vertical Title Max Height"
                description: "Maximum height the vertical title area can use"
                defaultValue: 88
                minimum: 48
                maximum: 320
                unit: "px"
                leftIcon: "height"
            }

            SelectionSetting {
                settingKey: "verticalTitleScrollBehavior"
                label: "Vertical Title Scroll"
                description: "Choose when the vertical title should scroll"
                defaultValue: "never"
                options: [
                    {
                        label: "Never",
                        value: "never"
                    },
                    {
                        label: "Always Scroll",
                        value: "always"
                    },
                    {
                        label: "Scroll On Hover",
                        value: "hover"
                    },
                    {
                        label: "Pause On Hover",
                        value: "pauseOnHover"
                    }
                ]
            }

            SliderSetting {
                settingKey: "verticalTitleScrollSpeed"
                label: "Vertical Title Scroll Speed"
                description: "How fast the vertical title scrolls when scrolling is enabled"
                defaultValue: 28
                minimum: 8
                maximum: 80
                unit: "px/s"
                leftIcon: "swap_vert"
            }

            SliderSetting {
                settingKey: "verticalTitlePadding"
                label: "Vertical Title Padding"
                description: "Inner padding for the vertical title background"
                defaultValue: 4
                minimum: 0
                maximum: 20
                unit: "px"
                leftIcon: "padding"
            }

            SliderSetting {
                settingKey: "verticalTitleRadius"
                label: "Vertical Title Radius"
                description: "Corner radius for the vertical title background"
                defaultValue: 12
                minimum: 0
                maximum: 32
                unit: "px"
                leftIcon: "rounded_corner"
            }

            SelectionSetting {
                settingKey: "verticalTitleBackgroundColorKey"
                label: "Vertical Title Background Color"
                description: "Theme color used for the vertical title background"
                defaultValue: "surfaceContainer"
                options: root.colorOptions
            }

            SelectionSetting {
                settingKey: "verticalTitleTextColorKey"
                label: "Vertical Title Text Color"
                description: "Theme color used for the vertical title text"
                defaultValue: "widgetText"
                options: root.colorOptions
            }
        }

        SectionCard {
            title: "Vertical Visualizer Layout"
            description: "Adjust structure, source, and style for the vertical visualizer."

            Row {
                spacing: Theme.spacingS

                DankActionButton {
                    iconName: "restart_alt"
                    tooltipText: "Reset vertical visualizer"
                    onClicked: root.resetVisualizerSettings("verticalVisualizer")
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Reset to defaults"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }

            SliderSetting {
                settingKey: "verticalVisualizerWidth"
                label: "Vertical Visualizer Height"
                description: "Adjust the height of the vertical visualizer"
                defaultValue: 20
                minimum: 12
                maximum: 300
                unit: "px"
                leftIcon: "graphic_eq"
            }

            SliderSetting {
                settingKey: "verticalVisualizerBars"
                label: "Vertical Visualizer Bars"
                description: "How many bars to show in the vertical visualizer"
                defaultValue: 6
                minimum: 3
                maximum: 60
                unit: ""
                leftIcon: "equalizer"
            }

            ToggleSetting {
                settingKey: "verticalVisualizerStretchToWidth"
                label: "Stretch Vertical Visualizer"
                description: "Stretch the bars to fill the configured vertical visualizer height"
                defaultValue: false
            }

            SelectionSetting {
                settingKey: "verticalVisualizerSourceMode"
                label: "Vertical Visualizer Source"
                description: "Choose whether the visualizer only reacts to media playback or all system audio"
                defaultValue: "mediaOnly"
                options: root.visualizerSourceOptions
            }

            SelectionSetting {
                settingKey: "verticalVisualizerStyle"
                label: "Vertical Visualizer Style"
                description: "Choose between solid bars, dotted bars, or line wave rendering"
                defaultValue: "bars"
                options: root.visualizerStyleOptions
            }

            SelectionSetting {
                settingKey: "verticalVisualizerBarAlignment"
                label: "Vertical Bar Alignment"
                description: "Align bar-style rendering to the top, center, or bottom of the visualizer lane"
                defaultValue: "center"
                options: root.visualizerAlignmentOptions
            }

            SelectionSetting {
                settingKey: "verticalVisualizerChannelMode"
                label: "Vertical Visualizer Channels"
                description: "Use mono or mock stereo-style layouts for the vertical visualizer"
                defaultValue: "mono"
                options: root.visualizerChannelOptions
            }
        }

        SectionCard {
            title: "Vertical Visualizer Colors"
            description: "Control solid and gradient colors for the vertical visualizer."

            ToggleSetting {
                id: verticalVisualizerGradientToggle
                settingKey: "verticalVisualizerUseGradient"
                label: "Use Vertical Visualizer Gradient"
                description: "Blend the vertical visualizer between a start and end color"
                defaultValue: false
            }

            SelectionSetting {
                id: verticalVisualizerColorSetting
                settingKey: "verticalVisualizerColorKey"
                label: "Vertical Visualizer Color"
                description: "Theme color used when the vertical visualizer gradient is disabled"
                defaultValue: "primary"
                options: root.colorOptions
                visible: !verticalVisualizerGradientToggle.value
            }

            ColorSetting {
                settingKey: "verticalVisualizerCustomColor"
                label: "Vertical Custom Visualizer Color"
                description: "Pick a custom solid color for the vertical visualizer"
                defaultValue: Theme.primary
                visible: !verticalVisualizerGradientToggle.value && verticalVisualizerColorSetting.value === "custom"
            }

            SelectionSetting {
                id: verticalVisualizerGradientStartSetting
                settingKey: "verticalVisualizerGradientStartKey"
                label: "Vertical Gradient Start"
                description: "Starting color for the vertical visualizer gradient"
                defaultValue: "primary"
                options: root.colorOptions
                visible: verticalVisualizerGradientToggle.value
            }

            ColorSetting {
                settingKey: "verticalVisualizerGradientStartCustomColor"
                label: "Vertical Custom Gradient Start"
                description: "Pick a custom start color for the vertical visualizer gradient"
                defaultValue: Theme.primary
                visible: verticalVisualizerGradientToggle.value && verticalVisualizerGradientStartSetting.value === "custom"
            }

            SelectionSetting {
                id: verticalVisualizerGradientEndSetting
                settingKey: "verticalVisualizerGradientEndKey"
                label: "Vertical Gradient End"
                description: "Ending color for the vertical visualizer gradient"
                defaultValue: "secondary"
                options: root.colorOptions
                visible: verticalVisualizerGradientToggle.value
            }

            ColorSetting {
                settingKey: "verticalVisualizerGradientEndCustomColor"
                label: "Vertical Custom Gradient End"
                description: "Pick a custom end color for the vertical visualizer gradient"
                defaultValue: Theme.secondary
                visible: verticalVisualizerGradientToggle.value && verticalVisualizerGradientEndSetting.value === "custom"
            }
        }

        SectionCard {
            title: "Vertical Visualizer Motion"
            description: "Tune how quickly the vertical visualizer responds and settles."

            SliderSetting {
                settingKey: "verticalVisualizerResponseCurve"
                label: "Vertical Visualizer Response"
                description: "Shape how strongly quiet versus loud sounds affect the visualizer"
                defaultValue: 50
                minimum: 20
                maximum: 120
                unit: "%"
                leftIcon: "show_chart"
            }

            SliderSetting {
                settingKey: "verticalVisualizerAttack"
                label: "Vertical Visualizer Attack"
                description: "How quickly the visualizer rises when the sound gets louder"
                defaultValue: 75
                minimum: 5
                maximum: 100
                unit: "%"
                leftIcon: "trending_up"
            }

            SliderSetting {
                settingKey: "verticalVisualizerRelease"
                label: "Vertical Visualizer Release"
                description: "How quickly the visualizer falls when the sound gets quieter"
                defaultValue: 35
                minimum: 5
                maximum: 100
                unit: "%"
                leftIcon: "trending_down"
            }

            ToggleSetting {
                settingKey: "verticalVisualizerPeakHold"
                label: "Vertical Peak Hold"
                description: "Show small held peak markers above the vertical visualizer bars"
                defaultValue: false
            }

            SliderSetting {
                settingKey: "verticalVisualizerPeakHoldMs"
                label: "Vertical Peak Hold Time"
                description: "How long the vertical peak markers stay visible before falling"
                defaultValue: 450
                minimum: 100
                maximum: 1200
                unit: "ms"
                leftIcon: "timer"
            }
        }
    }

    Column {
        width: parent.width
        spacing: Theme.spacingM
        visible: root.currentTab === 3

        SectionCard {
            title: "Popout Size"
            description: "Adjust the media popout dimensions separately for horizontal and vertical bars."

            SliderSetting {
                settingKey: "popoutPanelWidthHorizontal"
                label: "Horizontal Popout Width"
                description: "Adjust the width of the media popout when the widget is used in horizontal bars"
                defaultValue: 560
                minimum: 420
                maximum: 800
                unit: "px"
                leftIcon: "width"
            }

            SliderSetting {
                settingKey: "popoutPanelHeightHorizontal"
                label: "Horizontal Popout Height"
                description: "Adjust the height of the media popout when the widget is used in horizontal bars"
                defaultValue: 420
                minimum: 320
                maximum: 720
                unit: "px"
                leftIcon: "height"
            }

            SliderSetting {
                settingKey: "popoutPanelWidthVertical"
                label: "Vertical Popout Width"
                description: "Adjust the width of the media popout when the widget is used in vertical bars"
                defaultValue: 560
                minimum: 420
                maximum: 800
                unit: "px"
                leftIcon: "width"
            }

            SliderSetting {
                settingKey: "popoutPanelHeightVertical"
                label: "Vertical Popout Height"
                description: "Adjust the height of the media popout when the widget is used in vertical bars"
                defaultValue: 420
                minimum: 320
                maximum: 720
                unit: "px"
                leftIcon: "height"
            }

            ToggleSetting {
                settingKey: "showPopoutInnerBackground"
                label: "Show Inner Popout Background"
                description: "Draw the extra rounded background panel behind the media content"
                defaultValue: false
            }

            ToggleSetting {
                settingKey: "showPopoutArtworkBackdrop"
                label: "Show Artwork Backdrop"
                description: "Use the track artwork as a blurred background behind the popout content when available"
                defaultValue: true
            }
        }

        SectionCard {
            title: "Popout Title"
            description: "Control how many lines the media title can use inside the popout."

            SelectionSetting {
                settingKey: "popoutTitleMaxLines"
                label: "Popout Title Max Lines"
                description: "Choose how many lines the popout title may use"
                defaultValue: "1"
                options: [
                    {
                        label: "1 Line",
                        value: "1"
                    },
                    {
                        label: "2 Lines",
                        value: "2"
                    },
                    {
                        label: "3 Lines",
                        value: "3"
                    },
                    {
                        label: "4 Lines",
                        value: "4"
                    },
                    {
                        label: "Unlimited",
                        value: "0"
                    }
                ]
            }
        }
    }
}
