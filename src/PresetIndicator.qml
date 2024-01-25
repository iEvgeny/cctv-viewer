import QtQuick 2.12
import QtQuick.Controls 2.12

PageIndicator {
    id: root

    enum CarouselState {
        Disabled,
        Running,
        Paused
    }

    interactive: true

    property int carouselState: PresetIndicator.Disabled
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
                visible: root.carouselState === PresetIndicator.Disabled || root.currentIndex !== index
                radius: width / 2
                color: root.palette.dark
                anchors.fill: parent
            }

            Image {
                id: carouselControl
                visible: !defaultControl.visible
                source: root.carouselState === PresetIndicator.Running ? "qrc:/images/pause.svg" : "qrc:/images/play.svg"
                anchors.fill: parent

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.carouselControlClicked()
                }
            }
        }
    }
}
