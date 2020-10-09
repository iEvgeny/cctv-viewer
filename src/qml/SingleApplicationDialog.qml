import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.3

Dialog {
    title: qsTr('Warning!')
    modality: Qt.ApplicationModal
    standardButtons: StandardButton.Ok

    property bool singleApplication: !checkBox.checked

    Frame {
        anchors.fill: parent

        SwipeView {
            id: swipeView

            clip: true
            implicitWidth: Math.max(itemAt(0).implicitWidth, itemAt(1).implicitWidth)
            implicitHeight: Math.max(itemAt(0).implicitHeight, itemAt(1).implicitHeight)
            anchors.fill: parent

            RowLayout {
                Text {
                    text: qsTr('The application is already running!')
                }

                RoundButton {
                    text: '>>'
                    flat: true
                    Layout.alignment: Qt.AlignRight
                    onReleased: swipeView.incrementCurrentIndex()
                }
            }

            RowLayout {
                CheckBox {
                    id: checkBox

                    text: qsTr('Allow running multiple application instances')
                }
            }
        }
    }
}
