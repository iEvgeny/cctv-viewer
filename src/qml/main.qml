import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.1
import Qt.labs.settings 1.0
import CCTV_Viewer.Models 1.0
import '../js/utils.js' as CCTV_Viewer

ApplicationWindow {
    id: rootWindow

    title: qsTr('CCTV Viewer')

    visible: true
    visibility: rootWindow.fullScreen ? Window.FullScreen : Window.Windowed
    width: rootWindowSettings.width
    height: rootWindowSettings.height

    property bool fullScreen: false

    // Right-to-left User Interfaces support
    LayoutMirroring.enabled: CCTV_Viewer.ifRightToLeft(true)
    LayoutMirroring.childrenInherit: CCTV_Viewer.ifRightToLeft(true)

//    Settings {
//        id: generalSettings
//    }

    Settings {
        id: rootWindowSettings

        category: 'RootWindow'
        property int width: 960
        property int height: 540
        property alias fullScreen: rootWindow.fullScreen
    }

    Binding {
        target: rootWindowSettings
        property: 'width'
        value: rootWindow.width
        when: !rootWindow.fullScreen
    }

    Binding {
        target: rootWindowSettings
        property: 'height'
        value: rootWindow.height
        when: !rootWindow.fullScreen
    }

    Settings {
        id: layoutsCollectionSettings

        category: 'ViewportsLayoutsCollection'

        property int currentIndex
        property string models
        property string collection  // Old property
    }

    Shortcut {
        sequence: StandardKey.FullScreen
        onActivated: rootWindow.fullScreen = !rootWindow.fullScreen
    }
    Shortcut {
        sequence: StandardKey.Quit
        onActivated: Qt.quit()
    }

    ViewportsLayoutsCollectionModel {
        id: layoutsCollectionModel

        ViewportsLayoutModel {
            size: Qt.size(2, 2)
            Component.onCompleted: changed.connect(function() { layoutsCollectionModel.changed() })
        }
        ViewportsLayoutModel {
            size: Qt.size(3, 3)
            Component.onCompleted: changed.connect(function() { layoutsCollectionModel.changed() })
        }
        ViewportsLayoutModel {
            size: Qt.size(1, 1)
            Component.onCompleted: changed.connect(function() { layoutsCollectionModel.changed() })
        }

        Component.onCompleted: {
            var models = '';
            if (!layoutsCollectionSettings.models.isEmpty()) {
                models = layoutsCollectionSettings.models;
            } else {
                // Use old property
                models = layoutsCollectionSettings.collection;
            }

            try {
                if (!models.isEmpty()) {
                    fromJSValue(JSON.parse(models));
                }
            } catch(err) {
                CCTV_Viewer.log_error(qsTr('Error parse data model'));
            }

            stackLayout.currentIndex = layoutsCollectionSettings.currentIndex;
        }
        onChanged: layoutsCollectionSettings.models = JSON.stringify(toJSValue())
        onCountChanged: stackLayout.currentIndex = stackLayout.currentIndex.clamp(0, layoutsCollectionModel.count - 1)
    }

    Item {
        anchors.fill: parent

        Rectangle {
            color: 'black'
            anchors.fill: parent
        }

        StackLayout {
            id: stackLayout

            anchors.fill: parent

            onCurrentIndexChanged: layoutsCollectionSettings.currentIndex = currentIndex

            Repeater {
                id: swipeViewRepeater
                model: layoutsCollectionModel

                ViewportsLayout {
                    model: layoutModel
                    focus: true

                    visible: SwipeView.isCurrentItem
                }
            }
        }

        PageIndicator {
            interactive: true
            visible: stackLayout.count > 1
            currentIndex: stackLayout.currentIndex
            count: stackLayout.count
            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
            }

            onCurrentIndexChanged: stackLayout.currentIndex = currentIndex
        }

        SideMenu {
            height: parent.height
            anchors.right: parent.right
        }
    }
}
