import QtQuick 2.6
import QtQuick.Controls 2.0  // For Qt 5.6: import Qt.labs.controls 1.0
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0
import '../js/script.js' as CCTV_Viewer

FocusScope {
    id: root

    implicitWidth: 220

    property bool open: false
    property int interval: 1000

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
            root.open = mouseCaptureArea.containsMouse || mouseHoldArea.containsMouse;
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
                            anchors.fill: parent
                        }
                    }

                    GroupBox {
                        label: RowLayout {
                            width: parent.width

                            Label {
                                text: qsTr('Window division')
                                font.pixelSize: 14
                                color: 'white'
                            }
                        }

                        // Disable controls when one of the viewports is in full-screen mode.
                        enabled: !(viewportsLayout.fullScreenIndex >= 0)

                        Layout.fillWidth: true

                        GridLayout {
                            columns: 2
                            anchors.fill: parent

                            Repeater {
                                model: 4
                                delegate: Button {
                                    text: qsTr('%1x%1').arg(index + 1)
                                    enabled: !highlighted
                                    highlighted: viewportsLayout.division == index + 1

                                    Layout.fillWidth: true

                                    onClicked: viewportsLayout.division = index + 1
                                }
                            }
                        }
                    }

                    GroupBox {
                        label: RowLayout {
                            width: parent.width
                            Label {
                                text: qsTr('Geometry')
                                font.pixelSize: 14
                                color: 'white'
                            }
                        }

                        Layout.fillWidth: true

                        GridLayout {
                            columns: 2
                            anchors.fill: parent

                            Button {
                                text: qsTr('16:9')
                                enabled: !rootWindow.fullScreen  // Disable control when application window is full-screen.
                                highlighted: viewportsLayout.aspectRatio == '16:9'

                                Layout.fillWidth: true

                                onClicked: {
                                    var size = Math.round(rootWindow.width / 16);

                                    rootWindow.width = size * 16;
                                    rootWindow.height = size * 9;

                                    viewportsLayout.aspectRatio = '16:9';
                                }
                            }
                            Button {
                                text: qsTr('4:3')
                                enabled: !rootWindow.fullScreen  // Disable control when application window is full-screen.
                                highlighted: viewportsLayout.aspectRatio == '4:3'

                                Layout.fillWidth: true

                                onClicked: {
                                    var size = Math.round(rootWindow.width / 4);

                                    rootWindow.width = size * 4;
                                    rootWindow.height = size * 3;

                                    viewportsLayout.aspectRatio = '4:3';
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

                        label: RowLayout {
                            width: parent.width
                            Label {
                                text: qsTr('Tools')
                                font.pixelSize: 14
                                color: 'white'
                            }
                        }

                        Layout.fillWidth: true

                        RowLayout {
                            anchors.fill: parent

                            Button {
                                text: qsTr('Merging cells')
                                enabled: viewportsLayout.mergeCells(true)

                                Layout.fillWidth: true

                                onClicked: viewportsLayout.mergeCells()
                            }
                        }
                    }

                    GroupBox {
                        id: viewportGroup

                        label: RowLayout {
                            width: parent.width
                            Label {
                                text: qsTr('Viewport%1').arg(viewportsLayout.focusIndex >= 0 ? qsTr(' #%1').arg(viewportsLayout.focusIndex + 1) : '')
                                font.pixelSize: 14
                                color: 'white'
                            }
                        }

                        // Enabled only when one of the viewports is active.
                        enabled: viewportsLayout.focusIndex >= 0

                        Layout.fillWidth: true

                        ColumnLayout {
                            anchors.fill: parent

                            TextField {
                                text: viewportGroup.enabled ? viewportsLayout.itemAt(viewportsLayout.focusIndex).url : ''
                                placeholderText: qsTr('Url')
                                selectByMouse: true

                                Layout.fillWidth: true

                                onEditingFinished: viewportsLayout.model.get(viewportsLayout.focusIndex).url = text
                            }

                            Button {
                                text: (viewportsLayout.focusIndex >= 0 && viewportsLayout.itemAt(viewportsLayout.focusIndex).volume > 0) ? qsTr('Mute audio') : qsTr('Enable audio')

                                Layout.fillWidth: true

                                onClicked: {
                                    if (viewportsLayout.model.get(viewportsLayout.focusIndex).volume > 0) {
                                        viewportsLayout.model.get(viewportsLayout.focusIndex).volume = 0;
                                    } else {
                                        viewportsLayout.model.get(viewportsLayout.focusIndex).volume = 1;
                                    }
                                }
                            }
                        }
                    }

                    GroupBox {
                        id: presetsGroup

                        label: RowLayout {
                            width: parent.width
                            Label {
                                text: qsTr('Presets')
                                font.pixelSize: 14
                                color: 'white'
                            }
                        }

                        Layout.fillWidth: true

                        GridLayout {
                            columns: 4
                            anchors.fill: parent

                            Repeater {
                                model: viewportsLayoutsCollection.count
                                delegate: Button {
                                    text: hold ? '➖' : index + 1
                                    highlighted: viewportsLayoutsCollection.currentIndex == index

                                    property bool hold: false

                                    Layout.fillWidth: true

                                    onClicked: {
                                        if (hold) {
                                            viewportsLayoutsCollection.remove(index);
                                        } else {
                                            viewportsLayoutsCollection.currentIndex = index;
                                        }
                                    }
                                    onPressAndHold: hold = !hold
                                }
                            }

                            Button {
                                text: '➕'

                                Layout.fillWidth: true

                                onClicked: viewportsLayoutsCollection.append()
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
}
