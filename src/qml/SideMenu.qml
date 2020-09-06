import QtQuick 2.6
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0
import Qt.labs.settings 1.0
import '../js/utils.js' as CCTV_Viewer

FocusScope {
    id: root

    implicitWidth: 220

    property bool open: false
    property int openInterval: 300
    property int closeInterval: 2000
    readonly property alias pinned: d.pinned

    states: [
        State {
            name: 'open'
            when: d.open

            PropertyChanges {
                target: background
                x: 0
            }
        }
    ]

    transitions: [
        Transition {
            ParallelAnimation {
                PropertyAnimation {
                    property: 'x'
                    easing.type: Easing.Linear
                    duration: 250
                }
            }
        }
    ]

    QtObject {
        id: d

        property bool open: root.open || d.pinned || (currentLayout().pressAndHoldIndex >= 0) ||
                            (mouseCaptureArea.containsMouse && !openTimer.running) || (mouseHoldArea.containsMouse || closeTimer.running)
        property bool pinned: false
    }

    Settings {
        id: sideMenuSettings

        category: 'SideMenu'

        property string windowDivision
    }

    Timer {
        id: openTimer

        interval: root.openInterval
    }
    Timer {
        id: closeTimer

        interval: root.closeInterval
    }

    MouseArea {
        id: mouseCaptureArea

        hoverEnabled: true
        x: CCTV_Viewer.ifLeftToRight(root.width - width, 0)
        width: 20
        height: root.height

        onContainsMouseChanged: openTimer.restart()
    }

    Rectangle {
        id: background

        color: '#17a9ca'
        x: CCTV_Viewer.ifLeftToRight(root.width + 10, -(root.width + 10))
        width: root.width
        height: root.height

        // Disable the menu when it is not active to prevent the capture of keyboard focus.
        enabled: d.open

        layer.enabled: true
        layer.effect: DropShadow {
            id: menuShadow

            color: '#5f000000'
            transparentBorder: true
            samples: 17
            horizontalOffset: CCTV_Viewer.ifLeftToRight(-3, 3)
        }

        MouseArea {
            id: mouseHoldArea

            hoverEnabled: true
            anchors.fill: parent

            onContainsMouseChanged: {
                if (!containsMouse) {
                    closeTimer.restart();
                }
            }

            Flickable {
                id: flickable

                contentHeight: Math.max(parent.height, layout.height + about.height + layout.spacing * 2)
                anchors.fill: parent

                ColumnLayout {
                    id: layout

                    spacing: 10

                    anchors {
                        topMargin: layout.spacing
                        rightMargin: layout.spacing
                        leftMargin: layout.spacing
                        top: parent.top
                        right: parent.right
                        left: parent.left
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Label {
                            id: menuLabel

                            text: qsTr('Settings')
                            color: 'white'
                            font {
                                pixelSize: 24
                                underline: true
                            }

                            Layout.fillWidth: true
                        }

                        RoundButton {
                            id: pin

                            highlighted: d.pinned
                            contentItem: Image {
                                source: 'qrc:/res/icons/pin-white.svg'
                            }
                            background: Rectangle {
                                id: pinBackground

                                color: 'transparent'
                                border.width: 0
                                radius: pin.radius
                                states: [
                                    State {
                                        name: 'pinned'
                                        when: pin.highlighted

                                        PropertyChanges {
                                            target: pinBackground
                                            color: Qt.lighter(background.color, 1.2)
                                        }
                                    },
                                    State {
                                        name: 'hovered'
                                        when: pin.hovered

                                        PropertyChanges {
                                            target: pinBackground
                                            border.color: 'white'
                                            border.width: 1
                                        }
                                    }
                                ]
                            }

                            onClicked: d.pinned = !d.pinned
                        }
                    }

                    GroupBox {
                        label: Label {
                            text: qsTr('Window division')
                            color: 'white'
                            font.pixelSize: 14
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
                                    fromJSValue(sideMenuSettings.windowDivision);

                                    divisionModel.dataChanged.connect(function () {
                                        sideMenuSettings.windowDivision = JSON.stringify(toJSValue());
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
                        label: Label {
                            text: qsTr('Geometry')
                            color: 'white'
                            font.pixelSize: 14
                        }

                        Layout.fillWidth: true

                        GridLayout {
                            id: geometryLayout

                            columns: 2
                            anchors.fill: parent

                            Button {
                                text: qsTr('16:9')
                                highlighted: currentModel().aspectRatio === Qt.size(16, 9)

                                Layout.fillWidth: true

                                onClicked: {
                                    currentModel().aspectRatio = Qt.size(16, 9);
                                    setRootWindowRatio(currentModel().aspectRatio);
                                }
                            }
                            Button {
                                text: qsTr('4:3')
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
                        id: toolsGroup

                        label: Label {
                            text: qsTr('Tools')
                            color: 'white'
                            font.pixelSize: 14
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

                    GroupBox {
                        id: viewportGroup

                        label: Label {
                            text: qsTr('Viewport%1').arg(viewportNumber)
                            color: 'white'
                            font.pixelSize: 14

                            // HACK: External argument for fix GroupBox geometry calculation
                            property string viewportNumber: currentLayout().focusIndex >= 0 ? qsTr(' #%1').arg(currentLayout().focusIndex + 1) : ''
                        }

                        // Enabled only when one of the viewports is active.
                        enabled: currentLayout().focusIndex >= 0

                        Layout.fillWidth: true

                        ColumnLayout {
                            anchors.fill: parent

                            TextField {
                                text: viewportGroup.enabled ? currentModel().get(currentLayout().focusIndex).url : ''
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

                                Label {
                                    text: qsTr('AVFormat options')
                                    color: 'white'
                                    font.pixelSize: 14
                                }

                                TextField {
                                    text: viewportGroup.enabled ? getString(currentModel().get(currentLayout().focusIndex).avFormatOptions) : ''
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

                    GroupBox {
                        id: presetsGroup

                        label: Label {
                            text: qsTr('Presets')
                            color: 'white'
                            font.pixelSize: 14
                        }

                        Layout.fillWidth: true

                        GridLayout {
                            columns: 4
                            anchors.fill: parent

                            Repeater {
                                model: layoutsCollectionModel.count
                                delegate: Button {
                                    text: hold ? '➖' : index + 1
                                    highlighted: stackLayout.currentIndex === index

                                    property bool hold: false

                                    Keys.onEscapePressed: hold = false;

                                    Layout.fillWidth: true

                                    onClicked: {
                                        if (hold) {
                                            layoutsCollectionModel.remove(index);
                                        } else {
                                            stackLayout.currentIndex = index;
                                        }
                                    }
                                    onPressAndHold: {
                                        if (layoutsCollectionModel.count > 1) {
                                            hold = !hold;
                                        }
                                    }
                                }
                            }

                            Button {
                                text: '➕'

                                Layout.fillWidth: true

                                onClicked: layoutsCollectionModel.append().size = Qt.size(3, 3)
                            }
                        }
                    }
                }

                Label {
                    id: about

                    text: String('<a href="https://github.com/iEvgeny/cctv-viewer" style="color: white; text-decoration: none;">%1 v%2</a>').arg(Qt.application.name).arg(Qt.application.version)
                    textFormat: Text.RichText
                    horizontalAlignment: Text.AlignRight
                    anchors {
                        rightMargin: layout.spacing
                        bottomMargin: layout.spacing / 2
                        leftMargin: layout.spacing
                        right: parent.right
                        bottom: parent.bottom
                        left: parent.left
                    }

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
        var pixels = Math.round(rootWindow.width / horzRatio);

        if (!rootWindow.fullScreen) {
            rootWindow.width = horzRatio * pixels;
            rootWindow.height = vertRatio * pixels;
        }
    }
}
