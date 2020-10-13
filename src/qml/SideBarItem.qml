import QtQml 2.12
import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Templates 2.12 as T
import QtGraphicalEffects 1.12
import '../js/utils.js' as CCTV_Viewer

T.GroupBox {
    id: root

    clip: true
    spacing: 6
    padding: contentHeight > 0 ? 12 : 0
    topPadding: implicitLabelHeight + padding
    implicitWidth: Math.max(implicitLabelWidth , contentWidth + leftPadding + rightPadding)
    implicitHeight: d.collapsed ? implicitLabelHeight : Math.max(implicitLabelHeight, contentHeight + topPadding + bottomPadding)

    property url icon: ''
    property bool mirrorIcon: false
    property color color: 'white'

    property alias collapsed: d.collapsed

    signal clicked()

    resources: QtObject {
        id: d

        property bool open: rootSideBar.open || !rootSideBar.compact
        property bool collapsed: true

        onOpenChanged: {
            var obj = loadItemsState();

            if (open) {
                if (!root.objectName.isEmpty() && obj[root.objectName] && obj[root.objectName].collapsed !== undefined) {
                    collapsed = obj[root.objectName].collapsed;
                }
            } else {
                collapsed = true;
            }
        }
        onCollapsedChanged: {
            var obj = loadItemsState();

            if (open) {
                if (!root.objectName.isEmpty()) {
                    obj[root.objectName] = { collapsed: collapsed };
                    sideBarSettings.itemsState = JSON.stringify(obj);
                }
            }
        }

        function loadItemsState() {
            var obj = {};

            try {
                if (!sideBarSettings.itemsState.isEmpty()) {
                    obj = JSON.parse(sideBarSettings.itemsState);
                }
            } catch(err) {
                CCTV_Viewer.log_error(qsTr('Error reading configuration!'));
            }

            return obj;
        }
    }

    Behavior on implicitHeight {
        PropertyAnimation {
            id: collapseAnimaton

            duration: 150
            easing.type: Easing.InSine
        }
    }

    label: Button {
        id: control

        hoverEnabled: true
        width: parent.width

        onClicked: {
            root.clicked();

            if (!holdClickTimer.running) {
                rootSideBar.open = true;
                d.collapsed = root.contentHeight > 0 ? !d.collapsed : true;
                delayOpenningTimer.stop();
            }
        }

        onHoveredChanged: hovered && d.collapsed ? delayOpenningTimer.start() : delayOpenningTimer.stop()
        Timer {
            id: delayOpenningTimer

            interval: 500

            onTriggered: {
                if (root.contentHeight > 0) {
                    rootSideBar.open = true;
                    d.collapsed = false;

                    holdClickTimer.start();
                }
            }
        }
        Timer {
            id: holdClickTimer

            interval: 300
        }

        contentItem: RowLayout {
            id: layout

            spacing: 0

            Item {
                implicitWidth: icon.width
                implicitHeight: icon.height

                Layout.leftMargin: iconMargins()
                Layout.rightMargin: iconMargins()

                Image {
                    id: icon

                    source: root.icon
                    mirror: root.mirrorIcon
                    layer.enabled: true
                }

                ColorOverlay {
                    source: icon
                    color: root.color
                    cached: true
                    anchors.fill: icon
                }

                function iconMargins() {
                    return (rootSideBar.compactWidth - icon.width - control.leftPadding - control.rightPadding) / 2;
                }
            }

            Text {
                text: root.title
                color: root.color
                font.pointSize: 12
                font.weight: Font.Medium
                verticalAlignment: Text.AlignVCenter
                opacity: d.open ? 1 : 0

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: control.padding

                Behavior on opacity {
                    PropertyAnimation {
                        duration: 100
                        easing.type: Easing.InExpo
                    }
                }
            }

            Item {
                implicitWidth: iconCollapse.width
                implicitHeight: iconCollapse.height
                opacity: d.open && root.contentHeight > 0 ? 1 : 0

                Image {
                    id: iconCollapse

                    source: 'qrc:/res/icons/menu-item-collapse.svg'
                    visible: false
                }

                ColorOverlay {
                    source: iconCollapse
                    color: root.color
                    anchors.fill: iconCollapse

                    transform: Rotation {
                        angle: !d.collapsed ? 0 : control.mirrored ? -90 : 90
                        origin.x: iconCollapse.width / 2
                        origin.y: iconCollapse.height / 2
                    }
                }
            }
        }

        background: Item {
            Rectangle {
                id: headerBackground

                color: '#17a9ca'
                visible: control.hovered || !d.collapsed || collapseAnimaton.running
                opacity: visible ? 1 : 0
                anchors.fill: parent

                Behavior on opacity {
                    PropertyAnimation {
                        duration: 100
                        easing.type: Easing.Linear
                    }
                }
            }

            Rectangle {
                id: visualFocus

                color: 'transparent'
                border.color: control.palette.highlight
                border.width: control.visualFocus ? 2 : 0
                anchors.fill: parent
            }

            Rectangle {
                id: visualHover

                color: root.color
                width: 4
                height: root.height
                visible: control.hovered
                anchors.right: parent.right
            }
        }
    }

    background: Rectangle {
        id: background

        color: Qt.darker(containerBackground.color, 0.6)
        visible: !d.collapsed || collapseAnimaton.running
        anchors.fill: parent

        onVisibleChanged: setContentChildrenVisible(visible)
    }

    function setContentChildrenVisible(visible) {
        for (var key in contentChildren) {
            contentChildren[key].visible = visible;
        }
    }
}
