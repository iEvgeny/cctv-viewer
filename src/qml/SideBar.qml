import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import Qt.labs.settings 1.0
import '../js/utils.js' as CCTV_Viewer

FocusScope {
    id: rootSideBar

    implicitWidth: rootWindow.fullScreen && d.compact ? 0 :
                   d.compact ? d.compactWidth : container.implicitWidth
    implicitHeight: flickable.contentHeight

    property alias open: d.open
    property alias compact: d.compact

    onFocusChanged: {
        if (!focus) {
            d.open = false;
        }
    }

    Keys.onPressed: {
        if (event.key === Qt.Key_Escape) {
            d.open = false;
        }
    }

    resources: QtObject {
        id: d

        property bool open: false
        property bool compact: true

        // Constants
        readonly property real compactWidth: 52
        readonly property real expandedWidth: 250
    }

    Settings {
        id: sideBarSettings

        category: 'SideBar'

        property alias compact: d.compact

        // Items settings
        property string windowDivision
        property string itemsState
    }

    Item {
        id: container

        opacity: rootWindow.fullScreen && !d.open && d.compact ? 0 : 1
        implicitWidth: !d.open && d.compact ? d.compactWidth : d.expandedWidth
        implicitHeight: rootSideBar.height
        anchors.right: parent.right

        Behavior on opacity {
            enabled: !rootWindow.fullScreen || d.compact && rootSideBar.focus

            PropertyAnimation {
                easing.type: Easing.Linear
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
                    d.open = true;
                    rootSideBar.forceActiveFocus();
                }
            }

            Rectangle {
                id: containerBackground

                color: '#343434'
                width: container.width
                height: container.height
            }

            Flickable {
                id: flickable

                contentHeight: Math.max(parent.height, layout.implicitHeight + footer.implicitHeight)
                anchors.fill: parent

                ColumnLayout {
                    anchors.fill: parent

                    ColumnLayout {
                        id: layout

                        spacing: 0

                        Layout.topMargin: 7
                        Layout.alignment: Qt.AlignTop

                        SideBarItem {
                            id: header

                            icon: 'qrc:/res/icons/menu.svg'
                            title: Qt.application.name

                            Layout.fillWidth: true

                            Frame {
                                anchors.fill: parent

                                Text {
                                    text: String('&gt;&gt; <a href="https://github.com/iEvgeny/cctv-viewer" style="color: white;">Version %2</a> &lt;&lt;').arg(Qt.application.version)
                                    color: 'white'
                                    font.pixelSize: 14
                                    textFormat: Text.RichText
                                    horizontalAlignment: Text.AlignHCenter
                                    width: parent.width

                                    onLinkHovered: {
                                        if (link.length > 0) {
                                            cursorShapeArea.setCursor(Qt.PointingHandCursor);
                                        } else {
                                            cursorShapeArea.unsetCursor();
                                        }
                                    }
                                    onLinkActivated: Qt.openUrlExternally(link)

                                    MouseArea {
                                        id: cursorShapeArea

                                        acceptedButtons: Qt.NoButton
                                        anchors.fill: parent

                                        function setCursor(cursorShape) {
                                            cursorShapeArea.cursorShape = cursorShape;
                                        }
                                        function unsetCursor() {
                                            cursorShapeArea.cursorShape = Qt.ArrowCursor;
                                        }
                                    }
                                }
                            }
                        }

                        SideBarItem {
                            objectName: 'tools'
                            icon: 'qrc:/res/icons/menu-tools.svg'
                            title: qsTr('Tools')

                            Layout.fillWidth: true

                            ColumnLayout {
                                anchors.fill: parent

                                GroupBox {
                                    label: Text {
                                        text: qsTr('Window division')
                                        color: 'white'
                                        font.pixelSize: 14
                                        anchors.left: parent.left
                                    }

                                    // Disable controls when one of the viewports is in full-screen mode.
                                    enabled: !(currentLayout().fullScreenIndex >= 0)

                                    Layout.fillWidth: true

                                    GridLayout {
                                        columns: 2
                                        anchors.fill: parent

                                        ListModel {
                                            id: divisionModel

                                            ListElement {
                                                size: '1x1'
                                            }
                                            ListElement {
                                                size: '2x2'
                                            }
                                            ListElement {
                                                size: '3x3'
                                            }
                                            ListElement {
                                                size: '4x4'
                                            }

                                            Component.onCompleted: {
                                                fromJSValue(sideBarSettings.windowDivision);

                                                divisionModel.dataChanged.connect(function () {
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
                                                    CCTV_Viewer.log_error(qsTr('Error reading configuration'));
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

                                                Keys.onEscapePressed: divisionTextField.cancel()
                                                Keys.onPressed: {
                                                    if (event.key === Qt.Key_F2) {
                                                        divisionTextField.edit();
                                                    }
                                                }

                                                Button {
                                                    text: size
                                                    highlighted: {
                                                        currentModel().size === str2size(size);
                                                    }
                                                    anchors.fill: parent

                                                    onClicked: currentModel().size = str2size(size)
                                                    onPressAndHold: divisionTextField.edit()
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
                                                    var separatorTr = qsTr('x');
                                                    var regexp = new RegExp('^[1-9][x%1][1-9]$'.arg(separatorTr));
                                                    if (regexp.test(str)) {
                                                        var size = str.split(new RegExp('[x%1]'.arg(separatorTr)));
                                                        return Qt.size(size[0], size[1]);
                                                    }

                                                    return null;
                                                }
                                            }
                                        }
                                    }
                                }

                                GroupBox {
                                    label: Text {
                                        text: qsTr('Geometry')
                                        color: 'white'
                                        font.pixelSize: 14
                                        anchors.left: parent.left
                                    }

                                    Layout.fillWidth: true

                                    GridLayout {
                                        id: geometryLayout

                                        columns: 2
                                        anchors.fill: parent

                                        Button {
                                            text: '16:9'
                                            highlighted: currentModel().aspectRatio === Qt.size(16, 9)

                                            Layout.fillWidth: true

                                            onClicked: {
                                                currentModel().aspectRatio = Qt.size(16, 9);
                                                setRootWindowRatio(currentModel().aspectRatio);
                                            }
                                        }
                                        Button {
                                            text: '4:3'
                                            highlighted: currentModel().aspectRatio === Qt.size(4, 3)

                                            Layout.fillWidth: true

                                            onClicked: {
                                                currentModel().aspectRatio = Qt.size(4, 3);
                                                setRootWindowRatio(currentModel().aspectRatio);
                                            }
                                        }
                                        Button {
                                            text: qsTr('Full Screen')
                                            highlighted: rootWindow.fullScreen

                                            Layout.columnSpan: 2
                                            Layout.fillWidth: true

                                            onClicked: rootWindow.fullScreen = !rootWindow.fullScreen
                                        }
                                    }
                                }

                                GroupBox {
                                    label: Text {
                                        text: qsTr('Other')
                                        color: 'white'
                                        font.pixelSize: 14
                                        anchors.left: parent.left
                                    }

                                    Layout.fillWidth: true

                                    RowLayout {
                                        anchors.fill: parent

                                        Button {
                                            text: qsTr('Merging cells')
                                            enabled: currentLayout().mergeCells(true)

                                            Layout.fillWidth: true

                                            onClicked: currentLayout().mergeCells()
                                        }
                                    }
                                }
                            }
                        }
                        SideBarItem {
                            objectName: 'viewport'
                            icon: 'qrc:/res/icons/menu-viewport.svg'
                            title: qsTr('Viewport%1').arg(currentLayout().focusIndex >= 0 ? qsTr(' #%1').arg(currentLayout().focusIndex + 1) : '')

                            Layout.fillWidth: true

                            Frame {
                                id: viewportFrame

                                // Enabled only when one of the viewports is active.
                                enabled: currentLayout().focusIndex >= 0
                                anchors.fill: parent

                                ColumnLayout {
                                    anchors.fill: parent

                                    TextField {
                                        text: viewportFrame.enabled ? currentModel().get(currentLayout().focusIndex).url : ''
                                        placeholderText: qsTr('Url')
                                        selectByMouse: true

                                        Layout.fillWidth: true

                                        onEditingFinished: currentModel().get(currentLayout().focusIndex).url = text
                                    }

                                    Button {
                                        text: qsTr('Mute')
                                        enabled: currentLayout().focusIndex >= 0 ? currentLayout().get(currentLayout().focusIndex).hasAudio : false
                                        highlighted: currentLayout().focusIndex >= 0 && currentModel().get(currentLayout().focusIndex).volume <= 0

                                        Layout.fillWidth: true

                                        onClicked: {
                                            if (currentModel().get(currentLayout().focusIndex).volume > 0) {
                                                currentModel().get(currentLayout().focusIndex).volume = 0;
                                            } else {
                                                currentModel().get(currentLayout().focusIndex).volume = 1;
                                            }
                                        }
                                    }


                                    ColumnLayout {
                                        Layout.fillWidth: true

                                        Text {
                                            text: qsTr('AVFormat options')
                                            color: 'white'
                                            font.pixelSize: 14
                                        }

                                        TextField {
                                            text: viewportFrame.enabled ? getString(currentModel().get(currentLayout().focusIndex).avFormatOptions) : ''
                                            selectByMouse: true

                                            Layout.fillWidth: true

                                            onEditingFinished: {
                                                var options = parseString(text);
                                                var defaultAVFormatOptions = layoutsCollectionSettings.fromJSON('defaultAVFormatOptions');

                                                if (Object.keys(options).length == Object.keys(defaultAVFormatOptions).length) {
                                                    for (var key in options) {
                                                        if (defaultAVFormatOptions[key] === undefined || String(defaultAVFormatOptions[key]) !== String(options[key])) {
                                                            currentModel().get(currentLayout().focusIndex).avFormatOptions = options;
                                                            return;
                                                        }
                                                    }

                                                    currentModel().get(currentLayout().focusIndex).avFormatOptions = {};
                                                } else {
                                                    currentModel().get(currentLayout().focusIndex).avFormatOptions = options;
                                                }
                                            }

                                            function parseString(str) {
                                                var obj = {};
                                                var regexp = /-([a-z0-9_]+)\s([a-z0-9_.]+)/g;
                                                var pairs = str.match(regexp);

                                                if (Array.isArray(pairs)) {
                                                    for (var i = 0; i < pairs.length; ++i) {
                                                        var arr = pairs[i].split(/\s/);
                                                        obj[arr[0].slice(1)] = arr[1];
                                                    }
                                                }

                                                return obj;
                                            }

                                            function getString(options) {
                                                var str = '';

                                                Object.assignDefault(options, layoutsCollectionSettings.fromJSON('defaultAVFormatOptions'));

                                                for (var key in options) {
                                                    if (typeof options[key] === 'string' || typeof options[key] === 'number') {
                                                        str += '-%1 %2 '.arg(key).arg(options[key]);
                                                    }
                                                }

                                                return str.trim();
                                            }

                                        }
                                    }
                                }
                            }
                        }
                        SideBarItem {
                            objectName: 'presets'
                            icon: 'qrc:/res/icons/menu-presets.svg'
                            title: qsTr('Presets')

                            Layout.fillWidth: true

                            Frame {
                                anchors.fill: parent

                                GridLayout {
                                    id: presetsLayout

                                    columns: 4
                                    anchors.fill: parent

                                    Repeater {
                                        model: layoutsCollectionModel.count
                                        delegate: Button {
                                            text: deleteMode ? '➖' : index + 1
                                            highlighted: stackLayout.currentIndex === index

                                            property bool deleteMode: false

                                            Keys.onEscapePressed: deleteMode = false
                                            Keys.onDeletePressed: deleteMode = true

                                            Layout.fillWidth: true

                                            onClicked: {
                                                if (deleteMode) {
                                                    layoutsCollectionModel.remove(index);
                                                } else {
                                                    stackLayout.currentIndex = index;
                                                }
                                            }
                                            onPressAndHold: {
                                                if (layoutsCollectionModel.count > 1) {
                                                    deleteMode = !deleteMode;
                                                }
                                            }
                                        }
                                    }

                                    Button {
                                        id: addButton

                                        text: '➕'

                                        Layout.fillWidth: true

                                        onClicked: layoutsCollectionModel.append().size = Qt.size(3, 3)
                                    }
                                }
                            }
                        }
//                        SideBarItem {
//                            icon: 'qrc:/res/icons/menu-settings.svg'
//                            title: qsTr('Settings')

//                            Layout.fillWidth: true
//                        }
                    }

                    SideBarItem {
                        id: footer

                        icon: 'qrc:/res/icons/menu-collapse.svg'
                        mirrorIcon: mirrored ^ d.compact
                        title: d.compact ? qsTr('Expand') : qsTr('Collapse')

                        Layout.fillWidth: true
                        Layout.bottomMargin: 7
                        Layout.alignment: Qt.AlignBottom

                        onClicked: d.compact = !d.compact
                    }
                }
            }
        }
    }

    function currentModel() {
        return layoutsCollectionModel.get(stackLayout.currentIndex);
    }

    function currentLayout() {
        return swipeViewRepeater.itemAt(stackLayout.currentIndex);
    }

    function setRootWindowRatio(ratio) {
        var horzRatio = currentModel().size.width * ratio.width;
        var vertRatio = currentModel().size.height * ratio.height;
        var pixels = Math.round((rootWindow.width - rootSideBar.width) / horzRatio);

        if (!rootWindow.fullScreen) {
            rootWindow.width = horzRatio * pixels + rootSideBar.width;
            rootWindow.height = vertRatio * pixels;
        }
    }
}
