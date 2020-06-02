import QtQuick 2.0
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.1
import QtQuick.Dialogs 1.2

Dialog {
    title: qsTr('Warning!')
    modality: Qt.ApplicationModal
    standardButtons: Dialog.Ok

    property bool singleApplication: !checkBox.checked

    Frame {
        anchors.fill: parent

        SwipeView {
            id: swipeView

            clip: true
            implicitWidth: Math.max(itemAt(0).implicitWidth, itemAt(1).implicitWidth)
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
