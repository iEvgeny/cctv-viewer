import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import CCTV_Viewer.Core 1.0
import CCTV_Viewer.Themes 1.0

ThemedDialog {
    id: keyBindingsDialog

    title: qsTr("Key Bindings")
    width: 580
    height: 440
    minimumWidth: 480
    minimumHeight: 360

    onVisibleChanged: {
        if (visible) {
            loadBindings();
            actionList.currentIndex = 1;
        }
    }

    onAccepted: {
        if (hasConflicts()) {
            shake();
            return;
        }
        saveBindings();
        close();
    }

    // ── Action definitions — supplied by parent (e.g. RootWindow) ────
    property var actionDefs: []

    readonly property var categories: {
        var seen = {};
        var cats = [];
        for (var i = 0; i < actionDefs.length; ++i) {
            var cat = actionDefs[i].category;
            if (!seen[cat]) { seen[cat] = true; cats.push(cat); }
        }
        return cats;
    }

    // ── Config helpers — read/write individual INI keys ────────────
    readonly property string _group: "KeyBindings"

    function _readKey(key, defaultValue) {
        return Context.config.readSetting(_group, key, defaultValue || "");
    }

    function _writeKey(key, value) {
        Context.config.writeSetting(_group, key, value);
    }

    property var workingBindings: ({})
    property int captureSlot: -1

    showResetButton: true

    onReset: {
        resetToDefaults();
        loadBindings();
    }

    ListModel { id: displayModel }

    // ── Dialog content ───────────────────────────────────────────────
    RowLayout {
        anchors.fill: parent
        spacing: 10

        // ── Left pane: categorised action list ──────────────────
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 200
            color: Qt.lighter(Compact.paletteDark, 1.3)
            radius: 4

            ListView {
                id: actionList

                anchors.fill: parent
                anchors.margins: 2
                clip: true
                spacing: 0
                highlightFollowsCurrentItem: true

                ScrollBar.vertical: ScrollBar {
                    policy: actionList.contentHeight > actionList.height
                            ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
                }

                model: displayModel

                delegate: Item {
                    width: actionList.width
                    height: isHeader ? 22 : 26

                    Rectangle {
                        anchors.fill: parent
                        radius: isHeader ? 0 : 3
                        color: isHeader ? "transparent"
                             : actionList.currentIndex === index ? Compact.accentColor
                             : "transparent"
                    }

                    Label {
                        anchors.fill: parent
                        anchors.leftMargin: isHeader ? 6 : 14
                        anchors.rightMargin: 4
                        verticalAlignment: Text.AlignVCenter
                        text: displayName
                        font.bold: isHeader
                        font.pixelSize: isHeader ? 10 : 12
                        font.capitalization: isHeader ? Font.AllUppercase : Font.MixedCase
                        color: isHeader ? Compact.paletteMid
                             : actionList.currentIndex === index ? Compact.discoveryHighlightText
                             : Compact.sidebarText
                        opacity: isHeader ? 0.8 : 1.0
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !isHeader
                        onClicked: {
                            actionList.currentIndex = index;
                            captureSlot = -1;
                        }
                    }
                }

                onCurrentIndexChanged: captureSlot = -1
            }
        }

        // ── Right pane: binding editors ─────────────────────────
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            spacing: 6

            // Action title
            Label {
                text: {
                    var idx = actionList.currentIndex;
                    if (idx >= 0 && idx < displayModel.count && !displayModel.get(idx).isHeader) {
                        return displayModel.get(idx).displayName;
                    }
                    return qsTr("Select an action");
                }
                font.bold: true
                font.pixelSize: 15
                color: Compact.sidebarText
            }

            // Binding slot 1
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Label {
                    text: qsTr("Binding 1")
                    font.pixelSize: 10
                    font.capitalization: Font.AllUppercase
                    color: Compact.paletteMid
                }

                RowLayout {
                    Layout.fillWidth: true

                    ThemedButton {
                        id: slot1Button
                        property bool capturing: captureSlot === 1

                        text: {
                            if (capturing) return qsTr("Press key...");
                            var aid = currentActionId();
                            if (aid === "" || !workingBindings[aid]) return "";
                            return workingBindings[aid].b1 || qsTr("(unbound)");
                        }
                        Layout.fillWidth: true
                        active: capturing

                        onClicked: {
                            captureSlot = 1;
                            keyCapture.forceActiveFocus();
                        }
                    }

                    ThemedButton {
                        text: qsTr("Clear")
                        onClicked: {
                            setWorkingBinding(currentActionId(), 1, "");
                            captureSlot = -1;
                        }
                    }
                }

                Label {
                    visible: text !== ""
                    color: Compact.conflictText
                    font.pixelSize: 11
                    text: {
                        var aid = currentActionId();
                        if (aid === "" || !workingBindings[aid]) return "";
                        return conflictText(aid, workingBindings[aid].b1);
                    }
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            // Binding slot 2
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Label {
                    text: qsTr("Binding 2")
                    font.pixelSize: 10
                    font.capitalization: Font.AllUppercase
                    color: Compact.paletteMid
                }

                RowLayout {
                    Layout.fillWidth: true

                    ThemedButton {
                        id: slot2Button
                        property bool capturing: captureSlot === 2

                        text: {
                            if (capturing) return qsTr("Press key...");
                            var aid = currentActionId();
                            if (aid === "" || !workingBindings[aid]) return "";
                            return workingBindings[aid].b2 || qsTr("(unbound)");
                        }
                        Layout.fillWidth: true
                        active: capturing

                        onClicked: {
                            captureSlot = 2;
                            keyCapture.forceActiveFocus();
                        }
                    }

                    ThemedButton {
                        text: qsTr("Clear")
                        onClicked: {
                            setWorkingBinding(currentActionId(), 2, "");
                            captureSlot = -1;
                        }
                    }
                }

                Label {
                    visible: text !== ""
                    color: Compact.conflictText
                    font.pixelSize: 11
                    text: {
                        var aid = currentActionId();
                        if (aid === "" || !workingBindings[aid]) return "";
                        return conflictText(aid, workingBindings[aid].b2);
                    }
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            // Restore default for selected action
            ThemedButton {
                text: qsTr("Restore Defaults")
                enabled: currentActionId() !== ""

                onClicked: {
                    var aid = currentActionId();
                    var def = findActionDef(aid);
                    if (def) {
                        setWorkingBinding(aid, 1, def.default1);
                        setWorkingBinding(aid, 2, def.default2);
                    }
                    captureSlot = -1;
                }
            }

            Item { Layout.fillHeight: true }

            // Conflict warning
            Label {
                id: conflictWarning
                visible: hasConflicts()
                text: qsTr("Resolve all conflicts before saving.")
                color: Compact.conflictText
                font.pixelSize: 11
                font.bold: true
                Layout.fillWidth: true
            }
        }

        // ── Hidden key capture item ─────────────────────────────
        Item {
            id: keyCapture
            width: 0; height: 0

            Keys.onPressed: {
                if (captureSlot < 1) return;

                if (event.key === Qt.Key_Shift || event.key === Qt.Key_Control
                        || event.key === Qt.Key_Alt || event.key === Qt.Key_Meta) {
                    return;
                }

                if (event.key === Qt.Key_Escape && event.modifiers === Qt.NoModifier) {
                    captureSlot = -1;
                    return;
                }

                var seq = keyEventToString(event);
                if (seq !== "") {
                    var aid = currentActionId();
                    if (aid !== "") {
                        setWorkingBinding(aid, captureSlot, seq);
                    }
                    captureSlot = -1;
                }

                event.accepted = true;
            }

            function keyEventToString(event) {
                var parts = [];
                if (event.modifiers & Qt.ControlModifier) parts.push("Ctrl");
                if (event.modifiers & Qt.AltModifier) parts.push("Alt");
                if (event.modifiers & Qt.ShiftModifier) parts.push("Shift");
                if (event.modifiers & Qt.MetaModifier) parts.push("Meta");

                var keyName = keyToString(event.key, event.text);
                if (keyName !== "") parts.push(keyName);
                return parts.join("+");
            }

            function keyToString(key, text) {
                var keyMap = {};
                keyMap[Qt.Key_F1] = "F1";   keyMap[Qt.Key_F2] = "F2";
                keyMap[Qt.Key_F3] = "F3";   keyMap[Qt.Key_F4] = "F4";
                keyMap[Qt.Key_F5] = "F5";   keyMap[Qt.Key_F6] = "F6";
                keyMap[Qt.Key_F7] = "F7";   keyMap[Qt.Key_F8] = "F8";
                keyMap[Qt.Key_F9] = "F9";   keyMap[Qt.Key_F10] = "F10";
                keyMap[Qt.Key_F11] = "F11"; keyMap[Qt.Key_F12] = "F12";
                keyMap[Qt.Key_Space] = "Space";
                keyMap[Qt.Key_Return] = "Return";
                keyMap[Qt.Key_Enter] = "Enter";
                keyMap[Qt.Key_Tab] = "Tab";
                keyMap[Qt.Key_Backspace] = "Backspace";
                keyMap[Qt.Key_Delete] = "Delete";
                keyMap[Qt.Key_Escape] = "Escape";
                keyMap[Qt.Key_Home] = "Home";
                keyMap[Qt.Key_End] = "End";
                keyMap[Qt.Key_PageUp] = "PgUp";
                keyMap[Qt.Key_PageDown] = "PgDown";
                keyMap[Qt.Key_Left] = "Left";
                keyMap[Qt.Key_Right] = "Right";
                keyMap[Qt.Key_Up] = "Up";
                keyMap[Qt.Key_Down] = "Down";
                keyMap[Qt.Key_Insert] = "Ins";

                if (keyMap[key] !== undefined) return keyMap[key];
                if (text !== "" && text.trim() !== "") return text.toUpperCase();
                return "";
            }
        }
    }

    // ── Helper functions ─────────────────────────────────────────────

    function currentActionId() {
        var idx = actionList.currentIndex;
        if (idx >= 0 && idx < displayModel.count && !displayModel.get(idx).isHeader) {
            return displayModel.get(idx).actionId;
        }
        return "";
    }

    function findActionDef(actionId) {
        for (var i = 0; i < actionDefs.length; ++i) {
            if (actionDefs[i].id === actionId) return actionDefs[i];
        }
        return null;
    }

    function setWorkingBinding(actionId, slot, value) {
        if (!workingBindings[actionId]) return;
        var copy = JSON.parse(JSON.stringify(workingBindings));
        if (slot === 1) copy[actionId].b1 = value;
        else            copy[actionId].b2 = value;
        workingBindings = copy;
    }

    function conflictText(actionId, binding) {
        if (!binding || binding === "") return "";
        for (var otherId in workingBindings) {
            if (otherId === actionId) continue;
            var other = workingBindings[otherId];
            if (other.b1 === binding || other.b2 === binding) {
                var def = findActionDef(otherId);
                return qsTr("Conflicts with: %1").arg(def ? def.name : otherId);
            }
        }
        return "";
    }

    function hasConflicts() {
        for (var actionId in workingBindings) {
            var wb = workingBindings[actionId];
            if (wb.b1 && conflictText(actionId, wb.b1) !== "") return true;
            if (wb.b2 && conflictText(actionId, wb.b2) !== "") return true;
        }
        return false;
    }

    function loadBindings() {
        var wb = {};
        var firstRun = (_readKey("_initialized") !== "true");
        for (var i = 0; i < actionDefs.length; ++i) {
            var def = actionDefs[i];
            wb[def.id] = {
                b1: firstRun ? def.default1 : (_readKey(def.id + "_1") || ""),
                b2: firstRun ? def.default2 : (_readKey(def.id + "_2") || "")
            };
        }
        workingBindings = wb;

        displayModel.clear();
        for (var ci = 0; ci < categories.length; ++ci) {
            var cat = categories[ci];
            displayModel.append({ isHeader: true, displayName: cat, actionId: "" });
            for (var ai = 0; ai < actionDefs.length; ++ai) {
                if (actionDefs[ai].category === cat) {
                    displayModel.append({
                        isHeader: false,
                        displayName: actionDefs[ai].name,
                        actionId: actionDefs[ai].id
                    });
                }
            }
        }
        captureSlot = -1;
    }

    function saveBindings() {
        for (var id in workingBindings) {
            _writeKey(id + "_1", workingBindings[id].b1);
            _writeKey(id + "_2", workingBindings[id].b2);
        }
        _writeKey("_initialized", "true");
    }

    function resetToDefaults() {
        var wb = {};
        for (var i = 0; i < actionDefs.length; ++i) {
            var def = actionDefs[i];
            wb[def.id] = { b1: def.default1, b2: def.default2 };
        }
        workingBindings = wb;
    }

    // ── Public API ───────────────────────────────────────────────────

    function getBinding(actionId) {
        var firstRun = (_readKey("_initialized") !== "true");
        if (firstRun) {
            var def = findActionDef(actionId);
            return def ? def.default1 : "";
        }
        var s1 = _readKey(actionId + "_1");
        if (s1 !== undefined && s1 !== "") return s1;
        var s2 = _readKey(actionId + "_2");
        if (s2 !== undefined && s2 !== "") return s2;
        return "";
    }

    function getBindingSlot(actionId, slot) {
        var firstRun = (_readKey("_initialized") !== "true");
        if (firstRun) {
            var def = findActionDef(actionId);
            if (!def) return "";
            return slot === 1 ? def.default1 : def.default2;
        }
        return _readKey(actionId + "_" + slot) || "";
    }
}
