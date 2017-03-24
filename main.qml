import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0

ApplicationWindow {
    visible: true
    width: 640
    height: 480
    title: qsTr("CCTV Viewer")

    header: TabBar {
        id: tabBar
        currentIndex: swipeView.currentIndex
        TabButton {
            text: qsTr("Mosaic")
        }
        TabButton {
            text: qsTr("Settings")
        }
    }

    SwipeView {
        id: swipeView
        anchors.fill: parent
        currentIndex: tabBar.currentIndex

        Page {
            Label {
                text: qsTr("Mosaic view")
                anchors.centerIn: parent
            }
        }

        Page {
            Label {
                text: qsTr("Settings page")
                anchors.centerIn: parent
            }
        }
    }
}
