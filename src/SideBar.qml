import QtQml 2.12
import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.3
import Qt.labs.settings 1.0
import CCTV_Viewer.Core 1.0
import CCTV_Viewer.Themes 1.0
import CCTV_Viewer.Utils 1.0

FocusScope {
    id: rootSideBar

    enum State {
        Compact,
        Popup,
        Expanded
    }

    implicitWidth: Context.config.fullScreen && state !== SideBar.Expanded ? 0 :
                   state === SideBar.Expanded ? container.implicitWidth : compactWidth
    implicitHeight: flickable.contentHeight

    property int state: SideBar.Compact
    property int currentViewportIndex: Utils.currentLayout().focusIndex

    // Constants
    readonly property real compactWidth: 48
    readonly property real expandedWidth: 230

    onCurrentViewportIndexChanged: {
        if (rootSideBar.currentViewportIndex < 0  && state === SideBar.Popup) {
            rootSideBar.forceActiveFocus();
        }
    }
    Keys.onPressed: {
        if (event.key === Qt.Key_Escape && state === SideBar.Popup) {
            state = SideBar.Compact;
        }
    }
    Component.onCompleted: {
        state = sideBarSettings.compact ? SideBar.Compact : SideBar.Expanded;

        rootSideBar.stateChanged.connect(() => {
            sideBarSettings.compact = (state !== SideBar.Expanded);
        });
    }

    Settings {
        id: sideBarSettings

        fileName: Context.config.fileName
        category: "SideBar"

        property bool compact: true

        // Items settings
        property string windowDivision
        property string itemsState
    }

    Item {
        id: container

        opacity: Context.config.fullScreen && rootSideBar.state === SideBar.Compact ? 0 : 1
        implicitWidth: rootSideBar.state === SideBar.Compact ? compactWidth : expandedWidth
        implicitHeight: rootSideBar.height
        anchors.right: parent.right

        Behavior on opacity {
            enabled: !Context.config.fullScreen || rootSideBar.state !== SideBar.Compact

            OpacityAnimator {
                duration: 1500
            }
        }

        Behavior on implicitWidth {
            PropertyAnimation {
                easing.type: Easing.InSine
                duration: 250
            }
        }

        MouseArea {
            hoverEnabled: true
            anchors.fill: parent

            onContainsMouseChanged: {
                if (containsMouse) {
                    delayOpenningTimer.start();
                    delayAutoCollapseTimer.stop();
                } else {
                    delayOpenningTimer.stop();
                    delayAutoCollapseTimer.start();
                }
            }

            Timer {
                id: delayOpenningTimer

                interval: 150

                onTriggered: {
                    if (rootSideBar.state === SideBar.Compact) {
                        rootSideBar.state = SideBar.Popup
                        rootSideBar.forceActiveFocus();
                    }
                }
            }
            Timer {
                id: delayAutoCollapseTimer

                interval: 1500

                onTriggered: {
                    if (rootWindowSettings.sidebarAutoCollapse &&
                        rootSideBar.state === SideBar.Popup) {
                        rootSideBar.state = SideBar.Compact;
                    }
                }
            }

            Rectangle {
                id: containerBackground

                color: rootWindow.palette.dark
                width: container.width
                height: container.height
            }

            Flickable {
                id: flickable

                contentHeight: Math.max(parent.height, layout.implicitHeight + footer.implicitHeight + layout.verticalMargins * 2)
                anchors.fill: parent

                ColumnLayout {
                    id: layout

                    spacing: 0

                    width: parent.width

                    anchors.top: parent.top
                    anchors.topMargin: verticalMargins

                    readonly property real verticalMargins: 7

                    SideBarItem {
                        id: header

                        icon: "qrc:/images/menu.svg"
                        title: Qt.application.name

                        Layout.fillWidth: true

                        Frame {
                            anchors.fill: parent

                            ColumnLayout {
                                anchors.fill: parent

                                Text {
                                    text: {
                                        var v = `<b style=\"font-size: ${rootWindow.font.pointSize * 1.4}pt;\">v${Qt.application.version.replace(/\s/, "</b><br />")}`;
                                        return `<a href=\"#\" style=\"color: white; text-decoration: none;\">${v}</a>`;
                                    }
                                    color: "white"
                                    textFormat: Text.RichText
                                    horizontalAlignment: Text.AlignHCenter

                                    Layout.fillWidth: true

                                    onLinkHovered: header.linkHovered(link)
                                    onLinkActivated: {
                                        toolTip.visible = true;
                                        Clipboard.setText(Qt.application.version);
                                    }

                                    ToolTip {
                                        id: toolTip

                                        delay: 0
                                        timeout: Compact.toolTipTimeout
                                        text: qsTr("Copied to clipboard")
                                    }
                                }

                                Text {
                                    text: "<a href=\"https://github.com/iEvgeny/cctv-viewer\"><img src=\"qrc:/images/github.svg\" width=\"180\"></a>"
                                    color: "white"
                                    font.pointSize: rootWindow.font.pointSize * 1.05
                                    textFormat: Text.RichText
                                    horizontalAlignment: Text.AlignHCenter

                                    Layout.fillWidth: true

                                    onLinkHovered: header.linkHovered(link)
                                    onLinkActivated: Qt.openUrlExternally(link)
                                }
                            }
                        }

                        function linkHovered(link) {
                            if (link !== "") {
                                cursorShape.set(Qt.PointingHandCursor);
                            } else {
                                cursorShape.reset();
                            }
                        }
                    }

                    SideBarItem {
                        objectName: "tools"
                        icon: "qrc:/images/menu-tools.svg"
                        title: qsTr("Tools")

                        Layout.fillWidth: true

                        ColumnLayout {
                            anchors.fill: parent

                            GroupBox {
                                title: qsTr("Window division")
                                palette.windowText: "white"

                                // Disable controls when one of the viewports is in full-screen mode.
                                enabled: !(Utils.currentLayout().fullScreenIndex >= 0)

                                Layout.fillWidth: true

                                GridLayout {
                                    columns: 2
                                    anchors.fill: parent

                                    ListModel {
                                        id: divisionModel

                                        ListElement {
                                            size: "1x1"
                                        }
                                        ListElement {
                                            size: "2x2"
                                        }
                                        ListElement {
                                            size: "3x3"
                                        }
                                        ListElement {
                                            size: "4x4"
                                        }

                                        Component.onCompleted: {
                                            fromJSValue(sideBarSettings.windowDivision);

                                            divisionModel.dataChanged.connect(() => {
                                                sideBarSettings.windowDivision = JSON.stringify(toJSValue());
                                            });
                                        }

                                        function fromJSValue(model) {
                                            var arr;

                                            try {
                                                if (!model.isEmpty()) {
                                                    arr = JSON.parse(model);
                                                }
                                            } catch(err) {
                                                Utils.log_error(qsTr("Error reading configuration!"));
                                            }

                                            if (arr instanceof Array) {
                                                for (var i = 0; i < arr.length; ++i) {
                                                    divisionModel.set(i, arr[i]);
                                                }
                                            }
                                        }

                                        function toJSValue() {
                                            var arr = [];
                                            for (var i = 0; i < divisionModel.count; ++i) {
                                                arr[i] = divisionModel.get(i)
                                            }
                                            return arr;
                                        }
                                    }

                                    Repeater {
                                        model: divisionModel
                                        delegate: Item {
                                            id: divisionItem

                                            implicitWidth: divisionTextField.implicitWidth
                                            implicitHeight: divisionTextField.implicitHeight

                                            Layout.fillWidth: true

                                            Keys.onEscapePressed: {
                                                event.accepted = divisionTextField.visible;
                                                divisionTextField.cancel();
                                            }
                                            Keys.onPressed: {
                                                if (event.key === Qt.Key_F2) {
                                                    divisionTextField.edit();
                                                }
                                            }

                                            Button {
                                                text: size
                                                highlighted: {
                                                    Utils.currentModel().size === str2size(size);
                                                }
                                                anchors.fill: parent

                                                onClicked: Utils.currentModel().size = str2size(size)
                                                onPressAndHold: divisionTextField.edit()

                                                ToolTip.delay: Compact.toolTipDelay
                                                ToolTip.timeout: Compact.toolTipTimeout
                                                ToolTip.visible: hovered
                                                ToolTip.text: qsTr("Press and hold to enter edit mode")
                                            }

                                            TextField {
                                                id: divisionTextField

                                                visible: false
                                                anchors.fill: parent
                                                horizontalAlignment: TextInput.AlignHCenter
                                                selectByMouse: true

                                                onEditingFinished: {
                                                    visible = false;
                                                    if(str2size(text)) {
                                                        size = text;
                                                    }
                                                }

                                                function edit() {
                                                    text = size;
                                                    visible = true;
                                                    forceActiveFocus();
                                                }

                                                function cancel() {
                                                    text = size;
                                                    visible = false;
                                                }
                                            }

                                            function str2size(str) {
                                                var separatorTr = qsTr("x");
                                                var regexp = new RegExp("^[1-9][x%1][1-9]$".arg(separatorTr));
                                                if (regexp.test(str)) {
                                                    var size = str.split(new RegExp("[x%1]".arg(separatorTr)));
                                                    return Qt.size(size[0], size[1]);
                                                }

                                                return null;
                                            }
                                        }
                                    }
                                }
                            }

                            GroupBox {
                                title: qsTr("Geometry")
                                palette.windowText: "white"

                                Layout.fillWidth: true

                                GridLayout {
                                    id: geometryLayout

                                    columns: 2
                                    anchors.fill: parent

                                    Button {
                                        text: "16:9"
                                        highlighted: Utils.currentModel().aspectRatio === Qt.size(16, 9)

                                        Layout.fillWidth: true

                                        onClicked: {
                                            Utils.currentModel().aspectRatio = Qt.size(16, 9);
                                            setRootWindowRatio(Utils.currentModel().aspectRatio);
                                        }
                                    }
                                    Button {
                                        text: "4:3"
                                        highlighted: Utils.currentModel().aspectRatio === Qt.size(4, 3)

                                        Layout.fillWidth: true

                                        onClicked: {
                                            Utils.currentModel().aspectRatio = Qt.size(4, 3);
                                            setRootWindowRatio(Utils.currentModel().aspectRatio);
                                        }
                                    }
                                    Button {
                                        text: qsTr("Full Screen")
                                        highlighted: Context.config.fullScreen

                                        Layout.columnSpan: 2
                                        Layout.fillWidth: true

                                        onClicked: Context.config.fullScreen = !Context.config.fullScreen
                                    }
                                }
                            }

                            GroupBox {
                                title: qsTr("Other")
                                palette.windowText: "white"

                                Layout.fillWidth: true

                                RowLayout {
                                    anchors.fill: parent

                                    Button {
                                        text: qsTr("Merging cells")
                                        enabled: Utils.currentLayout().mergeCells(true)

                                        Layout.fillWidth: true

                                        onClicked: Utils.currentLayout().mergeCells()
                                    }
                                }
                            }
                        }
                    }
                    SideBarItem {
                        objectName: "viewport"
                        icon: "qrc:/images/menu-viewport.svg"
                        title: qsTr("Viewport%1").arg(currentViewportIndex >= 0 ? qsTr(" #%1").arg(currentViewportIndex + 1) : "")

                        Layout.fillWidth: true

                        Frame {
                            id: viewportFrame

                            hoverEnabled: true
                            anchors.fill: parent

                            ToolTip {
                                visible: !viewportLayout.enabled && viewportFrame.hovered
                                text: qsTr("Select viewport!")
                                anchors.centerIn: parent
                            }

                            ColumnLayout {
                                id: viewportLayout

                                // Enabled only when any of the viewports are active.
                                enabled: rootSideBar.currentViewportIndex >= 0
                                anchors.fill: parent

                                TextField {
                                    text: enabled ? Utils.currentModel().get(currentViewportIndex).url : ""
                                    placeholderText: qsTr("Url")
                                    selectByMouse: true

                                    Layout.fillWidth: true

                                    onEditingFinished: Utils.currentModel().get(currentViewportIndex).url = text
                                }

                                Button {
                                    text: qsTr("Mute")
                                    enabled: currentViewportIndex >= 0 ? Utils.currentLayout().get(currentViewportIndex).hasAudio : false
                                    highlighted: !(currentViewportIndex >= 0 && Utils.currentModel().get(currentViewportIndex).volume > 0 || viewportSettings.unmuteWhenFullScreen && Utils.currentLayout().fullScreenIndex >= 0)

                                    Layout.fillWidth: true

                                    onClicked: {
                                        if (Utils.currentModel().get(currentViewportIndex).volume > 0) {
                                            Utils.currentModel().get(currentViewportIndex).volume = 0;
                                        } else {
                                            Utils.currentModel().get(currentViewportIndex).volume = 1;
                                        }
                                    }
                                }


                                ColumnLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        text: qsTr("FFmpeg options")
                                        color: "white"
                                        font.pointSize: rootWindow.font.pointSize * 1.05
                                    }

                                    TextField {
                                        text: enabled ? getOptionsString(Utils.currentModel().get(currentViewportIndex).avFormatOptions) : ""
                                        selectByMouse: true

                                        Layout.fillWidth: true

                                        onEditingFinished: {
                                            var options = Utils.parseOptions(text);
                                            var defaultAVFormatOptions = layoutsCollectionSettings.toJSValue("defaultAVFormatOptions");

                                            if (Object.keys(options).length == Object.keys(defaultAVFormatOptions).length) {
                                                for (var key in options) {
                                                    if (defaultAVFormatOptions[key] === undefined || String(defaultAVFormatOptions[key]) !== String(options[key])) {
                                                        Utils.currentModel().get(currentViewportIndex).avFormatOptions = options;
                                                        return;
                                                    }
                                                }

                                                Utils.currentModel().get(currentViewportIndex).avFormatOptions = {};
                                            } else {
                                                Utils.currentModel().get(currentViewportIndex).avFormatOptions = options;
                                            }
                                        }

                                        function getOptionsString(options) {
                                            Object.assignDefault(options, layoutsCollectionSettings.toJSValue("defaultAVFormatOptions"));
                                            return Utils.stringifyOptions(options);
                                        }

                                    }
                                }
                            }
                        }
                    }
                    SideBarItem {
                        objectName: "presets"
                        icon: "qrc:/images/menu-presets.svg"
                        title: qsTr("Presets")

                        Layout.fillWidth: true

                        Frame {
                            anchors.fill: parent

                            GridLayout {
                                columns: 4
                                anchors.fill: parent

                                Repeater {
                                    model: layoutsCollectionModel.count
                                    delegate: Button {
                                        text: deleteMode ? "➖" : index + 1
                                        highlighted: stackLayout.currentIndex === index

                                        property bool deleteMode: false

                                        Keys.onEscapePressed: {
                                            event.accepted = deleteMode;
                                            deleteMode = false;
                                        }
                                        Keys.onDeletePressed: deleteMode = true

                                        Layout.fillWidth: true

                                        onClicked: {
                                            if (deleteMode) {
                                                presetDeleteDialog.index = index;
                                                presetDeleteDialog.open();
                                            } else {
                                                stackLayout.currentIndex = index;
                                            }
                                        }
                                        onPressAndHold: {
                                            if (layoutsCollectionModel.count > 1) {
                                                deleteMode = !deleteMode;
                                            }
                                        }

                                        ToolTip.delay: Compact.toolTipDelay
                                        ToolTip.timeout: Compact.toolTipTimeout
                                        ToolTip.visible: hovered
                                        ToolTip.text: deleteMode ? qsTr("Press and hold to exit delete mode") : qsTr("Press and hold to enter delete mode")
                                    }
                                }

                                Button {
                                    id: addButton

                                    text: "➕"

                                    Layout.fillWidth: true

                                    onClicked: layoutsCollectionModel.append().size = Qt.size(3, 3)
                                }
                            }
                        }

                        MessageDialog {
                            id: presetDeleteDialog

                            title: qsTr("Are you sure?")
                            icon: StandardIcon.Question
                            text: qsTr("Are you sure you want to delete preset #%1?").arg(index + 1)
                            informativeText: qsTr("It's an irreversible procedure. Be careful!")
                            standardButtons: MessageDialog.Yes | MessageDialog.No

                            property int index: -1

                            onYes: layoutsCollectionModel.remove(index)
                        }
                    }
                    SideBarItem {
                        icon: "qrc:/images/menu-settings.svg"
                        title: qsTr("Settings")

                        Layout.fillWidth: true

                        onClicked: settingsDialog.open()
                    }
                }

                SideBarItem {
                    id: footer

                    icon: "qrc:/images/menu-collapse.svg"
                    mirrorIcon: rootSideBar.state !== SideBar.Expanded ^ mirrored
                    title: rootSideBar.state !== SideBar.Expanded ? qsTr("Expand") : qsTr("Collapse")
                    width: parent.width
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: layout.verticalMargins

                    onClicked: {
                        if (rootSideBar.state !== SideBar.Expanded) {
                            rootSideBar.state = SideBar.Expanded
                        } else {
                            rootSideBar.state = SideBar.Compact
                        }
                    }
                }
            }
        }
    }

    function setRootWindowRatio(ratio) {
        var horzRatio = Utils.currentModel().size.width * ratio.width;
        var vertRatio = Utils.currentModel().size.height * ratio.height;
        var pixels = Math.round((rootWindow.width - rootSideBar.width) / horzRatio);

        if (!Context.config.fullScreen) {
            rootWindow.width = horzRatio * pixels + rootSideBar.width;
            rootWindow.height = vertRatio * pixels;
        }
    }
}
