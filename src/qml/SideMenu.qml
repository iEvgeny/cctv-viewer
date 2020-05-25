import QtQuick 2.6
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0
import '../js/utils.js' as CCTV_Viewer

FocusScope {
    id: root

    implicitWidth: 220

    property bool open: false
    property int interval: 1000

    readonly property alias pinned: d.pinned

    QtObject {
        id: d

        property bool pinned: false
    }

    states: [
        State {
            name: 'open'
            when: root.open

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

    Timer {
        id: timer

        interval: root.interval

        onTriggered: {
            root.open = d.pinned || mouseCaptureArea.containsMouse || mouseHoldArea.containsMouse;
        }
    }

    MouseArea {
        id: mouseCaptureArea

        hoverEnabled: true
        x: CCTV_Viewer.ifLeftToRight(root.width - width, 0)
        width: 20
        height: root.height

        onContainsMouseChanged: timer.restart()
    }

    Rectangle {
        id: background

        color: '#17a9ca'
        x: CCTV_Viewer.ifLeftToRight(root.width + 10, -(root.width + 10))
        width: root.width
        height: root.height

        // Disable the menu when it is not active to prevent the capture of keyboard focus.
        enabled: root.open

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
                if (containsMouse) {
                    root.open = true;
                } else {
                    timer.restart();
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

                            Repeater {
                                model: 4
                                delegate: Button {
                                    text: qsTr('%1x%1').arg(index + 1)
                                    enabled: !highlighted
                                    highlighted: {
                                        var division = index + 1;
                                        currentModel().size === Qt.size(division, division);
                                    }

                                    Layout.fillWidth: true

                                    onClicked: {
                                        var division = index + 1;
                                        currentModel().size = Qt.size(division, division);
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
                            columns: 2
                            anchors.fill: parent

                            Button {
                                text: qsTr('16:9')
                                highlighted: currentModel().aspectRatio === Qt.size(16, 9)

                                Layout.fillWidth: true

                                onClicked: {
                                    var size = Math.round(rootWindow.width / 16);

                                    if (!rootWindow.fullScreen) {
                                        rootWindow.width = size * 16;
                                        rootWindow.height = size * 9;
                                    }

                                    currentModel().aspectRatio = Qt.size(16, 9);
                                }
                            }
                            Button {
                                text: qsTr('4:3')
                                highlighted: currentModel().aspectRatio === Qt.size(4, 3)

                                Layout.fillWidth: true

                                onClicked: {
                                    var size = Math.round(rootWindow.width / 4);

                                    if (!rootWindow.fullScreen) {
                                        rootWindow.width = size * 4;
                                        rootWindow.height = size * 3;
                                    }

                                    currentModel().aspectRatio = Qt.size(4, 3);
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

                                onClicked: {
                                    layoutsCollectionModel.append().size = Qt.size(3, 3);
                                }
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
}
