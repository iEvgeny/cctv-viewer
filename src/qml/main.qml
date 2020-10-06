import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import Qt.labs.settings 1.0
import CCTV_Viewer.Utils 1.0
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
    LayoutMirroring.enabled: Qt.application.layoutDirection == Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    SingleApplicationDialog {
        onVisibleChanged: {
            if (!visible) {
                if (singleApplication) {
                    Qt.quit();
                } else {
                    generalSettings.singleApplication = false;
                }
            }
        }
        Component.onCompleted: {
            if (generalSettings.singleApplication && SingleApplication.isRunning()) {
                open();
            }
        }
    }

    Settings {
        id: generalSettings

        property bool intro: true
        property bool singleApplication: true
    }

    Settings {
        id: rootWindowSettings

        category: 'RootWindow'
        property int width: 1280 + sideBar.compactWidth
        property int height: 720
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
        property string collection  // DEPRECATED: Old property
        property string defaultAVFormatOptions: JSON.stringify({
            'analyzeduration': 0, // 0 µs
            'probesize': 500000 // 500 KB
        })

        function fromJSON(key) {
            var obj = {};

            try {
                obj = JSON.parse(layoutsCollectionSettings[String(key)]);
            } catch(err) {
                CCTV_Viewer.log_error(qsTr('Error reading configuration'));
            }

            return obj;
        }
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

        // Demo group
        ViewportsLayoutModel {
            size: Qt.size(2, 2)
        }
        ViewportsLayoutModel {
            size: Qt.size(3, 3)
        }
        ViewportsLayoutModel {
            size: Qt.size(1, 1)
        }

        onCountChanged: stackLayout.currentIndex = stackLayout.currentIndex.clamp(0, layoutsCollectionModel.count - 1)
        Component.onCompleted: {
            // Demo stream
            get(0).get(0).url = 'rtmp://live.a71.ru/demo/0';

            layoutsCollectionModel.changed.connect(function () {
                layoutsCollectionSettings.models = JSON.stringify(toJSValue());
            });

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
                CCTV_Viewer.log_error(qsTr('Error reading configuration'));
            }

            stackLayout.currentIndex = layoutsCollectionSettings.currentIndex;
        }
    }

    Item {
        height: parent.height
        anchors.left: parent.left
        anchors.right: sideBar.left

        Rectangle {
            color: 'black'
            anchors.fill: parent
        }

        StackLayout {
            id: stackLayout

            currentIndex: -1
            visible: !(generalSettings.singleApplication && SingleApplication.isRunning())
            anchors.fill: parent

            onCurrentIndexChanged: layoutsCollectionSettings.currentIndex = currentIndex

            Repeater {
                id: swipeViewRepeater
                model: layoutsCollectionModel

                ViewportsLayout {
                    model: layoutModel
                    focus: true
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
    }

    SideBar {
        id: sideBar

        height: parent.height
        anchors.right: parent.right

        //            // Intro
        //            onPinnedChanged: {
        //                if (!pinned && generalSettings.intro) {
        //                    generalSettings.intro = false;

        //                    // TODO: Show help for using the sidebar
        //                }
        //            }
        //            Component.onCompleted: {
        //                if (generalSettings.intro) {
        //                    pinned = true;
        //                }
        //            }
    }
}
