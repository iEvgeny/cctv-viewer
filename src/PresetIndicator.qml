import QtQml 2.12
import QtQuick 2.12
import QtQuick.Controls 2.12

PageIndicator {
    id: root

    interactive: true

    property string carouselState: "disabled"
    Binding on carouselState {
        id: carouselStateUpdater

        when: false
        // restoreMode: Binding.RestoreBinding // Qt6
        function set(newValue) { value = newValue; when = true; when = false; }
    }

    delegate: Control {
        implicitWidth: 12
        implicitHeight: 12

        opacity: hovered || root.currentIndex === index ? 0.95 : pressed ? 0.7 : 0.45

        Item {
            scale: parent.hovered ? 1.5 : 1.0
            transformOrigin: Item.Bottom
            anchors.fill: parent

            Behavior on scale {
                ScaleAnimator {
                    duration: 150
                }
            }

            Rectangle {
                id: defaultView
                visible: root.carouselState === "disabled" || root.currentIndex !== index
                radius: width / 2
                color: root.palette.dark
                anchors.fill: parent
            }

            Image {
                visible: !defaultView.visible
                source: root.carouselState === "running" ? "qrc:/images/pause.svg" : "qrc:/images/play.svg"
                anchors.fill: parent

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent

                    onClicked: carouselStateUpdater.set(root.carouselState === "running" ? "paused" : "running")
                }
            }
        }
    }
}
