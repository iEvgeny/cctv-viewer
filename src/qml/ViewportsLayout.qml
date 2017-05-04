import QtQuick 2.7
import QtMultimedia 5.0
import QtQuick.Layouts 1.3
import CCTV_Viewer.Enums 1.0
import '../js/script.js' as CCTV_Viewer

FocusScope {
    id: root

    property int division: 1
    property string aspectRatio: '16x9'
    property var model: ViewportsListModel {}
    property string color: 'black'

    readonly property alias fullScreenIndex: d.fullScreenIndex
    readonly property alias focusIndex: d.focusIndex
    readonly property alias activeFocusIndex: d.activeFocusIndex
    readonly property alias multiselect: d.multiselect

    onDivisionChanged: model.normalize(division, true)
    Component.onCompleted: {
        model.changed.connect(function() { model.normalize(division, true); });
    }

    QtObject {
        id: d

        property var aspectRatio: {
            var arr = root.aspectRatio.split(':', 2);

            if (arr.length != 2 || !CCTV_Viewer.isNumeric(arr[0]) || !CCTV_Viewer.isNumeric(arr[1])) {
                // Return default value
                return {x: 16, y: 9, ratio: 16 / 9};
            }

            return {x: arr[0], y: arr[1], ratio: arr[0] / arr[1]};
        }

        property int fullScreenIndex: -1
        property int focusIndex: -1
        property int activeFocusIndex: -1
        property int selectionIndex1: focusIndex
        property int selectionIndex2
        property bool multiselect: selectionIndex2 != selectionIndex1
        property int keyModifiers: 0

        onSelectionIndex1Changed: selectionReset()

        function columnFromIndex(index) {
            return model.columnFromIndex(index, root.division);
        }

        function rowFromIndex(index) {
            return model.rowFromIndex(index, root.division);
        }

        function indexFromAddress(column, row) {
            return model.indexFromAddress(column, row, root.division);
        }

        function selectionTop() {
            var top1 = rowFromIndex(selectionIndex1);
            var top2 = rowFromIndex(selectionIndex2);

            return Math.min(top1, top2);
        }

        function selectionRight() {
            var item1 = root.itemAt(selectionIndex1);
            var item2 = root.itemAt(selectionIndex2);
            var right1 = columnFromIndex(selectionIndex1);
            var right2 = columnFromIndex(selectionIndex2);

            if (item1 !== undefined) {
                right1 += root.itemAt(selectionIndex1).columnSpan;
            }
            if (item2 !== undefined) {
                right2 += root.itemAt(selectionIndex2).columnSpan;
            }

            return Math.max(right1, right2);
        }

        function selectionBottom() {
            var item1 = root.itemAt(selectionIndex1);
            var item2 = root.itemAt(selectionIndex2);
            var bottom1 = rowFromIndex(selectionIndex1);
            var bottom2 = rowFromIndex(selectionIndex2);

            if (item1 !== undefined) {
                bottom1 += root.itemAt(selectionIndex1).rowSpan;
            }
            if (item2 !== undefined) {
                bottom2 += root.itemAt(selectionIndex2).rowSpan;
            }

            return Math.max(bottom1, bottom2);
        }

        function selectionLeft() {
            var left1 = columnFromIndex(selectionIndex1);
            var left2 = columnFromIndex(selectionIndex2);

            return Math.min(left1, left2);
        }

        function selectionWidth() {
            return selectionRight() - selectionLeft();
        }

        function selectionHeight() {
            return selectionBottom() - selectionTop();
        }

        function selectionContains(index) {
            var column = columnFromIndex(index);
            var row = rowFromIndex(index);

            if (column >= selectionLeft() && column < selectionRight() &&
                    row >= selectionTop() && row < selectionBottom()) {
                return true;
            }

            return false;
        }

        function selectionReset() {
            selectionIndex2 = selectionIndex1;
        }
    }

    Rectangle {
        color: root.color
        anchors.fill: parent
    }

    GridLayout {
        id: layout

        width: (root.width / root.height <= d.aspectRatio.ratio) ? root.width : root.height * d.aspectRatio.ratio;
        height: (root.width / root.height < d.aspectRatio.ratio) ? root.width / d.aspectRatio.ratio : root.height;
        columns: root.division
        rows: root.division
        columnSpacing: 0
        rowSpacing: 0
        anchors.centerIn: parent

        Repeater {
            id: repeater

            model: root.model.listModel

            delegate: Item {
                id: container

                implicitWidth: (layout.width / root.division) * Math.max(viewport.columnSpan, 0)
                implicitHeight: (layout.height / root.division) * Math.max(viewport.rowSpan, 0)
                visible: (model.visible === Viewport.Visible) ? true : false

                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.columnSpan: Math.max(viewport.columnSpan, 1);
                Layout.rowSpan: Math.max(viewport.rowSpan, 1);

                Item {
                    id: viewport

                    x: 0
                    y: 0
                    width: parent.width
                    height: parent.height
                    activeFocusOnTab: d.fullScreenIndex < 0 || d.fullScreenIndex === model.index

                    property int cursorColumnOffset: 0
                    property int cursorRowOffset: 0
                    property bool fullScreen: false

                    readonly property alias selected: d2.selected

                    readonly property alias url: d2.url
                    readonly property alias column: d2.column
                    readonly property alias row: d2.row
                    readonly property alias columnSpan: d2.columnSpan
                    readonly property alias rowSpan: d2.rowSpan
                    readonly property alias volume: d2.volume

                    readonly property alias topIndex: d2.topIndex
                    readonly property alias rightIndex: d2.rightIndex
                    readonly property alias bottomIndex: d2.bottomIndex
                    readonly property alias leftIndex: d2.leftIndex

                    states: [
                        State {
                            name: 'fullScreen'
                            when: viewport.fullScreen

                            PropertyChanges {
                                target: viewport
                                // HACK: Вводим зависимость от размера элемента родителя для того,
                                // чтобы инициировать пересчет позиции дочернего элемента при изменении размера GridLayout.
                                x: viewport.parent.width ? -parent.mapToItem(layout, 0, 0).x : 0
                                y: viewport.parent.height ? -parent.mapToItem(layout, 0, 0).y : 0
                                width: layout.width
                                height: layout.height
                            }
                            PropertyChanges {
                                target: viewport.parent
                                z: 1
                            }
                        }
                    ]

                    transitions: [
                        Transition {
                            ParallelAnimation {
                                PropertyAnimation {
                                    properties: 'x, y, z, width, height'
                                    easing.type: Easing.Linear
                                    duration: 250
                                }
                            }
                        }
                    ]

                    onFullScreenChanged: d2.setCurrentIndex('fullScreenIndex', fullScreen)
                    onFocusChanged: d2.setCurrentIndex('focusIndex', focus)
                    onActiveFocusChanged: d2.setCurrentIndex('activeFocusIndex', activeFocus)
                    onSelectedChanged: {
                        if (!selected) {
                            cursorColumnOffset = 0;
                            cursorRowOffset = 0;
                        }
                    }

                    Keys.onPressed: {
                        var fullScreenKey = QT_TR_NOOP('F', 'Shortcut');
                        if (event.text.toUpperCase() === fullScreenKey ||
                            event.text.toUpperCase() === qsTr(fullScreenKey)) {
                            fullScreen = !fullScreen;
                            d.selectionReset();
                        }

                        switch (event.key) {
                        case Qt.Key_Escape:
                            focus = false;
                            fullScreen = false;
                            break;
                        case Qt.Key_Up:
                            keyNavigationHandler(keyUpCallback);

                            function keyUpCallback(index) {
                                var topIndex = root.itemAt(index).topIndex;

                                if (topIndex !== index) {
                                    root.itemAt(topIndex).cursorColumnOffset =
                                            d.columnFromIndex(index) + root.itemAt(index).cursorColumnOffset - d.columnFromIndex(topIndex);
                                } else {
                                    root.itemAt(index).cursorRowOffset = Math.max(root.itemAt(index).cursorRowOffset - 1, 0);
                                }

                                return topIndex;
                            }

                            break;
                        case Qt.Key_Right:
                            keyNavigationHandler(keyRightCallback);

                            function keyRightCallback(index) {
                                var rightIndex = root.itemAt(index).rightIndex;

                                if (rightIndex !== index) {
                                    root.itemAt(rightIndex).cursorRowOffset =
                                            d.rowFromIndex(index) + root.itemAt(index).cursorRowOffset - d.rowFromIndex(rightIndex);
                                } else {
                                    root.itemAt(index).cursorColumnOffset = Math.min(root.itemAt(index).cursorColumnOffset + 1, root.itemAt(index).columnSpan - 1);
                                }

                                return rightIndex;
                            }

                            break;
                        case Qt.Key_Down:
                            keyNavigationHandler(keyDownCallback);

                            function keyDownCallback(index) {
                                var bottomIndex = root.itemAt(index).bottomIndex;

                                if (bottomIndex !== index) {
                                    root.itemAt(bottomIndex).cursorColumnOffset =
                                            d.columnFromIndex(index) + root.itemAt(index).cursorColumnOffset - d.columnFromIndex(bottomIndex);
                                } else {
                                    root.itemAt(index).cursorRowOffset = Math.min(root.itemAt(index).cursorRowOffset + 1, root.itemAt(index).rowSpan - 1);
                                }

                                return bottomIndex;
                            }

                            break;
                        case Qt.Key_Left:
                            keyNavigationHandler(keyLeftCallback);

                            function keyLeftCallback(index) {
                                var leftIndex = root.itemAt(index).leftIndex;

                                if (leftIndex !== index) {
                                    root.itemAt(leftIndex).cursorRowOffset =
                                            d.rowFromIndex(index) + root.itemAt(index).cursorRowOffset - d.rowFromIndex(leftIndex);
                                } else {
                                    root.itemAt(index).cursorColumnOffset = Math.max(root.itemAt(index).cursorColumnOffset - 1, 0);
                                }

                                return leftIndex;
                            }

                            break;
                        }

                        function keyNavigationHandler(keyNavigationCallback) {
                            if (!fullScreen) {
                                if (d.activeFocusIndex >= 0 && d.keyModifiers & Qt.ShiftModifier) {
                                    d.selectionIndex2 = keyNavigationCallback(d.selectionIndex2);
                                } else {
                                    root.itemAt(keyNavigationCallback(model.index)).forceActiveFocus();
                                }
                            }
                        }
                    }

                    QtObject {
                        id: d2

                        property bool selected: d.selectionContains(model.index)

                        property url url: model.url
                        property int column: d.columnFromIndex(model.index)
                        property int row: d.rowFromIndex(model.index)
                        property int columnSpan: model.columnSpan
                        property int rowSpan: model.rowSpan
                        property real volume: model.volume

                        property int topIndex: spanningIndex(viewport.column + viewport.cursorColumnOffset,
                                                             CCTV_Viewer.clamp(viewport.row - 1, 0, root.division - 1))

                        property int rightIndex: spanningIndex(CCTV_Viewer.clamp(viewport.column + viewport.columnSpan, 0, root.division - 1),
                                                               viewport.row + viewport.cursorRowOffset)

                        property int bottomIndex: spanningIndex(viewport.column + viewport.cursorColumnOffset,
                                                                CCTV_Viewer.clamp(viewport.row + viewport.rowSpan, 0, root.division - 1))

                        property int leftIndex: spanningIndex(CCTV_Viewer.clamp(viewport.column - 1, 0, root.division - 1),
                                                              viewport.row + viewport.cursorRowOffset)


                        function setCurrentIndex(key, current) {
                            if (current === true) {
                                d[key] = model.index;
                            } else if (d[key] === model.index) {
                                d[key] = -1;
                            }
                        }

                        function spanningIndex(column, row) {
                            var spanningIndex = d.indexFromAddress(column, row);

                            if (spanningIndex !== model.index) {
                                var spanningItem = root.itemAt(spanningIndex);

                                if (spanningItem !== undefined && !spanningItem.visible) {
                                    spanningIndex = d.indexFromAddress(d.columnFromIndex(spanningIndex) + spanningItem.columnSpan,
                                                                       d.rowFromIndex(spanningIndex) + spanningItem.rowSpan);
                                }
                            }

                            return spanningIndex;
                        }
                    }

                    Player {
                        id: player

                        keepAlive: true
                        color: root.color
                        autoLoad: visible
                        autoPlay: visible
                        loops: MediaPlayer.Infinite
                        volume: viewport.volume
                        anchors.fill: parent

                        onVisibleChanged: setPlaybackState()
                        Component.onCompleted: {
                            viewport.urlChanged.connect(function() { setPlaybackState(); });
                        }

                        function setPlaybackState() {
                            // NOTE: Здесь приходится обнулять медиаисточник, иначе на потоковых форматах stop() работает как pause().
                            if (visible) {
                                source = viewport.url;
                                play();
                            } else {
                                stop();
                                source = '';
                            }
                        }
                    }

                    Rectangle {
                        id: selectionRect

                        color: 'transparent'
                        anchors.fill: parent

                        states: [
                            State {
                                name: 'multiselect'
                                when: root.multiselect && viewport.selected

                                PropertyChanges {
                                    target: selectionRect
                                    color: "#4000a8ff"
                                }
                            }
                        ]
                    }

                    Rectangle {
                        id: selectionFrame

                        color: 'transparent'
                        border.color: 'transparent'
                        anchors.fill: parent

                        states: [
                            State {
                                name: 'active'
                                when: viewport.activeFocus

                                PropertyChanges {
                                    target: selectionFrame
                                    border.width: 1
                                    border.color: '#00dd00'
                                }
                            }
                        ]
                    }

                    MouseArea {
                        anchors.fill: parent

                        onPressed: {
                            if (d.activeFocusIndex >= 0 && d.keyModifiers & Qt.ShiftModifier) {
                                d.selectionIndex2 = model.index;
                            } else {
                                viewport.forceActiveFocus();
                                d.selectionReset();
                            }
                        }

                        onDoubleClicked: {
                            viewport.fullScreen = !viewport.fullScreen;
                            d.selectionReset();
                        }

                        onMouseXChanged: mouseMoveHandler()
                        onMouseYChanged: mouseMoveHandler()

                        function mouseMoveHandler() {
                            if (!containsMouse) {
                                var selectionIndex2 = viewport.indexAt(mouseX, mouseY);

                                if (selectionIndex2 >= 0) {
                                    d.selectionIndex2 = selectionIndex2;
                                }
                            } else {
                                if (!(d.keyModifiers & Qt.ShiftModifier)) {
                                    d.selectionReset();
                                }
                            }
                        }
                    }

                    function indexAt(x, y) {
                        for (var i = 0; i < repeater.count; ++i) {
                            var itemTo = repeater.itemAt(i);

                            if (i === model.index) {
                                if (contains(Qt.point(x, y))) {
                                    return i;
                                }
                            } else {
                                var mappedPoint = mapToItem(itemTo, x, y);

                                if (itemTo.contains(mappedPoint)) {
                                    return i;
                                }
                            }
                        }

                        return -1;
                    }
                }
            }
        }
    }

    Keys.onPressed: d.keyModifiers = event.modifiers
    Keys.onReleased: d.keyModifiers = event.modifiers

    function itemAt(index) {
        if (index >= 0 && index < repeater.count) {
            return repeater.itemAt(index).children[0];
        }

        return;
    }

    function indexAt(x, y) {
        for (var i = 0; i < repeater.count; ++i) {
            var itemTo = repeater.itemAt(i);
            var mappedPoint = mapToItem(itemTo, x, y);

            if (itemTo.contains(mappedPoint)) {
                return i;
            }
        }

        return -1;
    }

    function mergeCells(testMode) {
        var topLeftIndex = d.indexFromAddress(d.selectionLeft(), d.selectionTop());
        var topLeftElement = model.get(topLeftIndex);

        if (d.selectionWidth() !== d.selectionHeight() ||
            d.selectionWidth() <= 0 || d.selectionHeight() <= 0 ||
            d.selectionWidth() >= root.division || d.selectionHeight() >= root.division) {
            return false;
        }

        if (!testMode) {
            if (topLeftElement.columnSpan > 1 || topLeftElement.rowSpan > 1) {
                topLeftElement.columnSpan = 1;
                topLeftElement.rowSpan = 1;
            } else {
                topLeftElement.columnSpan = d.selectionWidth();
                topLeftElement.rowSpan = d.selectionHeight();
            }

            d.selectionReset();
        }

        return true;
    }
}
