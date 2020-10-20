import QtQml 2.12
import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Templates 2.12 as T
import QtGraphicalEffects 1.12
import CCTV_Viewer.Themes 1.0
import CCTV_Viewer.Utils 1.0

T.Page {
    id: root

    enum State {
        Compact,
        Collapsed,
        Expanded
    }

    clip: true
    spacing: 0
    padding: contentHeight > 0 ? Compact.contentPadding : 0
    implicitWidth: Math.max(header.implicitWidth, contentWidth + leftPadding + rightPadding)
    implicitHeight: state !== SideBarItem.Expanded ? header.implicitHeight : header.implicitHeight + contentHeight + topPadding + bottomPadding

    property url icon: ''
    property bool mirrorIcon: false
    property color color: 'white'

    property int state: SideBarItem.Compact

    signal clicked()

    onStateChanged: {
        if (root.state !== SideBarItem.Compact) {
            var obj = d.loadItemsState();

            if (!root.objectName.isEmpty()) {
                obj[root.objectName] = { collapsed: root.state === SideBarItem.Collapsed };
                sideBarSettings.itemsState = JSON.stringify(obj);
            }

            if (rootSideBar.state === SideBar.Compact) {
                rootSideBar.state = SideBar.Popup;
            }
        }
    }

    Behavior on implicitHeight {
        PropertyAnimation {
            id: collapseAnimaton

            duration: 150
            easing.type: Easing.InSine
        }
    }

    QtObject {
        id: d

        property int rootState: rootSideBar.state

        onRootStateChanged: {
            if (rootState === SideBar.Compact) {
                root.state = SideBarItem.Compact;
            } else {
                var obj = d.loadItemsState();

                if (!root.objectName.isEmpty() && obj[root.objectName] && obj[root.objectName].collapsed !== undefined) {
                    root.state = obj[root.objectName].collapsed ? SideBarItem.Collapsed : SideBarItem.Expanded;
                } else {
                    root.state = SideBarItem.Collapsed;
                }
            }
        }

        function setContentChildrenVisible(visible) {
            for (var key in root.contentChildren) {
                root.contentChildren[key].visible = visible;
            }
        }

        function loadItemsState() {
            var obj = {};

            try {
                if (!sideBarSettings.itemsState.isEmpty()) {
                    obj = JSON.parse(sideBarSettings.itemsState);
                }
            } catch(err) {
                Utils.log_error(qsTr('Error reading configuration!'));
            }

            return obj;
        }
    }

    header: Button {
        id: header

        hoverEnabled: true
        width: root.width

        onClicked: {
            root.clicked();

            if (!holdClickTimer.running) {
                if (root.contentHeight > 0) {
                    if (root.state !== SideBarItem.Expanded) {
                        root.state = SideBarItem.Expanded;
                    } else {
                        root.state = SideBarItem.Collapsed;
                    }
                }
                delayOpenningTimer.stop();
            }
        }

        onHoveredChanged: hovered && root.state !== SideBarItem.Expanded ? delayOpenningTimer.start() : delayOpenningTimer.stop()
        Timer {
            id: delayOpenningTimer

            interval: 500

            onTriggered: {
                if (root.contentHeight > 0 ) {
                    root.state = SideBarItem.Expanded;
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
                    return (rootSideBar.compactWidth - icon.width - header.leftPadding - header.rightPadding) / 2;
                }
            }

            Text {
                text: root.title
                color: root.color
                font.pointSize: rootWindow.font.pointSize * 1.2
                verticalAlignment: Text.AlignVCenter
                opacity: root.state !== SideBarItem.Compact ? 1 : 0

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: header.padding

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
                opacity: root.state !== SideBarItem.Compact && root.contentHeight > 0 ? 1 : 0

                Image {
                    id: iconCollapse

                    source: 'qrc:/images/menu-item-collapse.svg'
                    visible: false
                }

                ColorOverlay {
                    source: iconCollapse
                    color: root.color
                    anchors.fill: iconCollapse

                    transform: Rotation {
                        angle: root.state !== SideBarItem.Collapsed ? 0 : header.mirrored ? -90 : 90
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
                visible: header.hovered || root.state === SideBarItem.Expanded || collapseAnimaton.running
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
                border.color: header.palette.highlight
                border.width: header.visualFocus ? 2 : 0
                anchors.fill: parent
            }

            Rectangle {
                id: visualHover

                color: root.color
                width: 4
                height: root.height
                visible: header.hovered
                anchors.right: parent.right
            }
        }
    }

    background: Rectangle {
        id: background

        color: Qt.lighter(containerBackground.color, 1.6)
        visible: root.state === SideBarItem.Expanded || collapseAnimaton.running

        onVisibleChanged: d.setContentChildrenVisible(visible)
    }
}
