import QtQuick 2.12
import QtQuick.Controls 2.12

PageIndicator {
    id: root

    interactive: true

    property string carouselState: "disabled"
    signal carouselControlClicked()

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
                id: defaultControl
                visible: root.carouselState === "disabled" || root.currentIndex !== index
                radius: width / 2
                color: root.palette.dark
                anchors.fill: parent
            }

            Image {
                id: carouselControl
                visible: !defaultControl.visible
                source: root.carouselState === "running" ? "qrc:/images/pause.svg" : "qrc:/images/play.svg"
                anchors.fill: parent

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    onClicked: root.carouselControlClicked()
                }
            }
        }
    }
}
