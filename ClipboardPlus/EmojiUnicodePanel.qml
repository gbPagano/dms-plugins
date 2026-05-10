import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Common
import qs.Widgets

FocusScope {
    id: root

    property var pluginApi: null
    property var screen: null
    property bool standaloneMode: false
    property bool focusSearchOnOpen: false
    property bool trapTabNavigation: false
    property bool compactSidebarMode: false
    property string searchText: ""
    property var filteredEntries: []
    property alias searchFieldItem: searchField
    property alias recentFocusTarget: recentsGrid
    property alias gridFocusTarget: resultsGrid
    property alias resultsView: resultsGrid

    signal tabForwardRequested
    signal tabBackwardRequested

    readonly property var catalogEntries: pluginApi?.mainInstance?.emojiCatalog || []
    readonly property var recentEntries: pluginApi?.mainInstance?.recentEmojiEntries || []
    readonly property var recentIndexMap: {
        const map = {};
        const recent = recentEntries || [];
        for (let i = 0; i < recent.length; i++)
            map[recent[i].id] = i;
        return map;
    }
    readonly property var currentEntry: {
        if (resultsGrid.currentIndex < 0 || resultsGrid.currentIndex >= filteredEntries.length)
            return null;
        return filteredEntries[resultsGrid.currentIndex] || null;
    }
    readonly property int tileSize: Math.max(28, Math.min(64, pluginApi?.pluginSettings?.emojiTileSize ?? (standaloneMode ? 42 : 38)))
    readonly property int tileGap: Math.max(2, Math.min(16, pluginApi?.pluginSettings?.emojiTileGap ?? Theme.spacingXS))
    readonly property int recentRows: standaloneMode ? 2 : 1
    readonly property bool hideRecentsWhileSearching: pluginApi?.pluginSettings?.emojiHideRecentsWhileSearching ?? false
    readonly property bool showRecents: recentEntries.length > 0 && (!hideRecentsWhileSearching || String(searchText || "").trim().length === 0)

    function focusSearchField() {
        searchField.forceActiveFocus();
        searchField.selectAll();
    }

    function tokenize(text) {
        const trimmed = String(text || "").trim().toLowerCase();
        return trimmed.length === 0 ? [] : trimmed.split(/\s+/).filter(Boolean);
    }

    function tokenMatches(entry, token) {
        if (!entry || !token)
            return false;
        if (String(entry.glyph || "").toLowerCase() === token)
            return true;
        const nameLower = String(entry.name || "").toLowerCase();
        if (nameLower.indexOf(token) !== -1)
            return true;
        const keywords = Array.isArray(entry.keywords) ? entry.keywords : [];
        for (let i = 0; i < keywords.length; i++) {
            if (String(keywords[i]).toLowerCase().indexOf(token) !== -1)
                return true;
        }
        return false;
    }

    function entryScore(entry, query, tokens) {
        if (!entry)
            return -1;
        const glyph = String(entry.glyph || "");
        const nameLower = String(entry.name || "").toLowerCase();
        const keywords = Array.isArray(entry.keywords) ? entry.keywords : [];
        const lowerQuery = String(query || "").trim().toLowerCase();
        const recentBoost = recentIndexMap[entry.id] !== undefined ? (400 - recentIndexMap[entry.id] * 5) : 0;

        if (!lowerQuery)
            return recentBoost;

        for (let i = 0; i < tokens.length; i++) {
            if (!tokenMatches(entry, tokens[i]))
                return -1;
        }

        let score = recentBoost;
        if (glyph.toLowerCase() === lowerQuery)
            score += 10000;
        if (nameLower === lowerQuery)
            score += 9000;
        else if (nameLower.startsWith(lowerQuery))
            score += 7000;
        else if (nameLower.indexOf(lowerQuery) !== -1)
            score += 5000;

        for (let i = 0; i < keywords.length; i++) {
            const keyword = String(keywords[i]).toLowerCase();
            if (keyword === lowerQuery)
                score += 8000 - i;
            else if (keyword.startsWith(lowerQuery))
                score += 6500 - i;
            else if (keyword.indexOf(lowerQuery) !== -1)
                score += 4500 - i;
        }

        score += Math.max(0, 200 - tokens.length * 10);
        return score;
    }

    function rebuildResults() {
        const source = Array.isArray(catalogEntries) ? catalogEntries.slice() : [];
        const query = searchText;
        const tokens = tokenize(query);
        const dedupe = {};
        const matches = [];

        for (let i = 0; i < source.length; i++) {
            const entry = source[i];
            if (!entry || dedupe[entry.id])
                continue;
            const score = entryScore(entry, query, tokens);
            if (score < 0)
                continue;
            dedupe[entry.id] = true;
            matches.push({
                entry: entry,
                score: score,
                order: i
            });
        }

        matches.sort((a, b) => {
            if (b.score !== a.score)
                return b.score - a.score;
            return a.order - b.order;
        });

        filteredEntries = matches.map(item => item.entry);
        if (filteredEntries.length === 0) {
            resultsGrid.currentIndex = -1;
        } else if (resultsGrid.currentIndex < 0 || resultsGrid.currentIndex >= filteredEntries.length) {
            resultsGrid.currentIndex = 0;
        }
    }

    function selectEntry(entry) {
        if (!entry || !pluginApi?.mainInstance)
            return;
        pluginApi.mainInstance.recordRecentEmoji(entry);
        pluginApi.mainInstance.copyTextToClipboard(entry.glyph);
        pluginApi.closePanel(screen);
    }

    function activateCurrent() {
        if (currentEntry)
            selectEntry(currentEntry);
    }

    function focusRecents() {
        if (!recentEntries.length)
            return;
        recentsGrid.forceActiveFocus();
        if (recentsGrid.count > 0 && recentsGrid.currentIndex < 0)
            recentsGrid.currentIndex = 0;
    }

    function focusResults() {
        resultsGrid.forceActiveFocus();
        if (resultsGrid.count > 0 && resultsGrid.currentIndex < 0)
            resultsGrid.currentIndex = 0;
    }

    Component.onCompleted: {
        rebuildResults();
        if (focusSearchOnOpen)
            Qt.callLater(focusSearchField);
    }
    onCatalogEntriesChanged: rebuildResults()
    onRecentEntriesChanged: rebuildResults()
    onSearchTextChanged: rebuildResults()
    onFocusSearchOnOpenChanged: {
        if (focusSearchOnOpen)
            Qt.callLater(focusSearchField);
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.spacingM

        StyledRect {
            id: searchInput
            Layout.fillWidth: true
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh
            border.color: Theme.outline
            border.width: 1
            height: Math.round(Theme.fontSizeMedium * 2.2)

            TextInput {
                id: searchField
                anchors.fill: parent
                anchors.margins: Theme.spacingS
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceText
                text: root.searchText
                selectByMouse: true
                onTextChanged: root.searchText = text
                Keys.onTabPressed: event => {
                    if (root.trapTabNavigation) {
                        if (recentEntries.length > 0)
                            root.focusRecents();
                        else
                            root.focusResults();
                    } else {
                        root.tabForwardRequested();
                    }
                    event.accepted = true;
                }
                Keys.onBacktabPressed: event => {
                    if (root.trapTabNavigation)
                        root.tabBackwardRequested();
                    else
                        root.tabBackwardRequested();
                    event.accepted = true;
                }
                Keys.onDownPressed: event => {
                    if (recentEntries.length > 0)
                        root.focusRecents();
                    else
                        root.focusResults();
                    event.accepted = true;
                }
            }

            StyledText {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Theme.spacingS
                text: "Search..."
                color: Theme.surfaceVariantText
                visible: searchField.text.length === 0
                font.pixelSize: Theme.fontSizeSmall
            }
        }

        FocusScope {
            id: recentFocus
            Layout.fillWidth: true
            Layout.preferredHeight: recentsGrid.implicitHeight
            Layout.minimumHeight: recentsGrid.implicitHeight
            Layout.maximumHeight: recentsGrid.implicitHeight
            visible: showRecents
            implicitHeight: recentsGrid.implicitHeight

            GridView {
                id: recentsGrid
                anchors.fill: parent
                implicitHeight: (root.tileSize * root.recentRows) + (root.tileGap * Math.max(0, root.recentRows - 1))
                clip: true
                interactive: false
                readonly property int visibleColumns: Math.max(1, Math.floor(width / cellWidth))
                readonly property int visibleCapacity: Math.max(1, visibleColumns * root.recentRows)
                model: recentEntries.slice(0, visibleCapacity)
                cellWidth: root.tileSize + root.tileGap
                cellHeight: root.tileSize + root.tileGap
                flow: GridView.FlowLeftToRight
                boundsBehavior: Flickable.StopAtBounds
                keyNavigationWraps: true
                currentIndex: model.length > 0 ? 0 : -1
                focus: true

                Keys.onTabPressed: event => {
                    if (root.trapTabNavigation)
                        root.focusResults();
                    else
                        root.tabForwardRequested();
                    event.accepted = true;
                }
                Keys.onBacktabPressed: event => {
                    if (root.trapTabNavigation)
                        root.focusSearchField();
                    else
                        root.tabBackwardRequested();
                    event.accepted = true;
                }
                Keys.onReturnPressed: root.selectEntry(root.recentEntries[currentIndex] || null)
                Keys.onEnterPressed: root.selectEntry(root.recentEntries[currentIndex] || null)
                Keys.onEscapePressed: {
                    pluginApi?.closePanel(screen);
                }
                Keys.onDownPressed: event => {
                    root.focusResults();
                    event.accepted = true;
                }
                Keys.onLeftPressed: event => {
                    if (currentIndex > 0) {
                        currentIndex--;
                        event.accepted = true;
                    }
                }
                Keys.onRightPressed: event => {
                    if (currentIndex < count - 1) {
                        currentIndex++;
                        event.accepted = true;
                    }
                }

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: root.tileSize
                    height: root.tileSize
                    radius: Theme.cornerRadius
                    readonly property bool selected: GridView.isCurrentItem && recentFocus.activeFocus
                    color: recentMouse.containsMouse ? Theme.surfaceContainerHighest : (selected ? Theme.primaryContainer : Theme.surfaceContainerHigh)
                    border.width: 1
                    border.color: selected ? Theme.primary : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.25)

                    StyledText {
                        anchors.centerIn: parent
                        text: modelData.glyph || ""
                        font.pixelSize: root.standaloneMode ? 22 : 20
                        color: selected ? Theme.primaryText : Theme.surfaceText
                    }

                    MouseArea {
                        id: recentMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: recentsGrid.currentIndex = index
                        onClicked: root.selectEntry(parent.modelData)
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh
            border.width: 1
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.22)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingS
                spacing: 0

                FocusScope {
                    id: resultsFocus
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Keys.onTabPressed: event => {
                        if (root.trapTabNavigation)
                            root.focusSearchField();
                        else
                            root.tabForwardRequested();
                        event.accepted = true;
                    }
                    Keys.onBacktabPressed: event => {
                        if (root.trapTabNavigation) {
                            if (recentEntries.length > 0)
                                root.focusRecents();
                            else
                                root.focusSearchField();
                        } else {
                            root.tabBackwardRequested();
                        }
                        event.accepted = true;
                    }
                    Keys.onReturnPressed: {
                        root.activateCurrent();
                    }
                    Keys.onEnterPressed: {
                        root.activateCurrent();
                    }
                    Keys.onUpPressed: event => {
                        if (resultsGrid.currentIndex >= 0 && resultsGrid.currentIndex < resultsGrid.columns) {
                            if (recentEntries.length > 0)
                                root.focusRecents();
                            else
                                root.focusSearchField();
                        }
                    }

                    GridView {
                        id: resultsGrid
                        anchors.fill: parent
                        clip: true
                        model: root.filteredEntries
                        cellWidth: root.tileSize + root.tileGap
                        cellHeight: root.tileSize + root.tileGap
                        boundsBehavior: Flickable.StopAtBounds
                        keyNavigationWraps: true
                        currentIndex: -1
                        focus: true

                        property int columns: Math.max(1, Math.floor(width / cellWidth))

                        Keys.onTabPressed: event => {
                            if (root.trapTabNavigation)
                                root.focusSearchField();
                            else
                                root.tabForwardRequested();
                            event.accepted = true;
                        }
                        Keys.onBacktabPressed: event => {
                            if (root.trapTabNavigation) {
                                if (recentEntries.length > 0)
                                    root.focusRecents();
                                else
                                    root.focusSearchField();
                            } else {
                                root.tabBackwardRequested();
                            }
                            event.accepted = true;
                        }
                        Keys.onReturnPressed: {
                            root.activateCurrent();
                        }
                        Keys.onEnterPressed: {
                            root.activateCurrent();
                        }
                        Keys.onEscapePressed: {
                            pluginApi?.closePanel(screen);
                        }

                        ScrollBar.vertical: ScrollBar {
                            policy: resultsGrid.contentHeight > resultsGrid.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                            width: 10
                            contentItem: Rectangle {
                                radius: width / 2
                                color: Theme.primary
                                opacity: parent.pressed ? 0.95 : (parent.hovered ? 0.8 : 0.65)
                            }
                            background: Rectangle {
                                radius: width / 2
                                color: Theme.surfaceContainerHighest
                                opacity: 0.75
                            }
                        }

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: root.tileSize
                            height: root.tileSize
                            radius: Theme.cornerRadius
                            readonly property bool selected: GridView.isCurrentItem && resultsFocus.activeFocus
                            color: emojiMouse.containsMouse ? Theme.surfaceContainerHighest : (selected ? Theme.primaryContainer : Theme.surfaceContainer)
                            border.width: selected ? 1 : 0
                            border.color: selected ? Theme.primary : "transparent"

                            StyledText {
                                anchors.centerIn: parent
                                text: modelData.glyph || ""
                                font.pixelSize: root.standaloneMode ? 22 : 20
                                color: selected ? Theme.primaryText : Theme.surfaceText
                            }

                            MouseArea {
                                id: emojiMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: resultsGrid.currentIndex = index
                                onClicked: root.selectEntry(parent.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
