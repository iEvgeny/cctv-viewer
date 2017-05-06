import QtQuick 2.7
import QtQuick.Window 2.2
import QtQuick.Controls 2.0
import Qt.labs.settings 1.0
import '../js/script.js' as Script

ApplicationWindow {
    id: rootWindow

    visible: true
    visibility: rootWindow.fullScreen ? Window.FullScreen : Window.Windowed
    width: rootWindowSettings.width
    height: rootWindowSettings.height
    title: qsTr('CCTV Viewer')

    property bool fullScreen: false

    // Right-to-left User Interfaces support
    LayoutMirroring.enabled: Script.ifRightToLeft(true)
    LayoutMirroring.childrenInherit: Script.ifRightToLeft(true)

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
        id: viewportsLayoutSettings

        category: 'ViewportsLayout'
        property alias division: viewportsLayout.division
        property alias aspectRatio: viewportsLayout.aspectRatio
        property string model

        Component.onCompleted: {
            function stringifyModel() {
                model = viewportsLayout.model.stringify();
            }

            // Load model
            viewportsLayout.model.parse(viewportsLayoutSettings.model);
            // Save model
            stringifyModel();
            viewportsLayout.model.changed.connect(function() { stringifyModel(); });
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

    ViewportsLayout {
        id: viewportsLayout

        focus: true
        division: 3
        anchors.fill: parent
    }

    SideMenu {
        id: submenu

        height: parent.height
        anchors.right: parent.right
    }
}
