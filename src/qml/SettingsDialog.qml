import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.3
import '../js/utils.js' as CCTV_Viewer

Dialog {
    title: qsTr('Settings')
    modality: Qt.ApplicationModal
    standardButtons: StandardButton.Ok | StandardButton.Cancel

    onVisibleChanged: {
        if (visible) {
            loadSettings();
        }
    }
    onAccepted: saveSettings()

    ColumnLayout {
        anchors.fill: parent

        GroupBox {
            title: qsTr('General')

            Layout.fillWidth: true

            CheckBox {
                id: singleApplicationCheckBox

                text: qsTr('Allow running multiple application instances')
            }
        }

        GroupBox {
            title: qsTr('Viewports')

            Layout.fillWidth: true

            ColumnLayout {
                width: parent.width

                Label {
                    text: qsTr('Default AVFormat options')
                }

                TextField {
                    id: defaultAVFormatOptions

                    selectByMouse: true

                    Layout.fillWidth: true
                }
            }
        }
    }

    function loadSettings() {
        // Single application
        singleApplicationCheckBox.checked = !generalSettings.singleApplication;

        // Default AVFormat options
        defaultAVFormatOptions.text = '';
        var options = layoutsCollectionSettings.toJSValue('defaultAVFormatOptions');
        for (var key in options) {
            if (typeof options[key] === 'string' || typeof options[key] === 'number') {
                defaultAVFormatOptions.text += '-%1 %2 '.arg(key).arg(options[key]);
            }
        }
        defaultAVFormatOptions.text = defaultAVFormatOptions.text.trim();
    }

    function saveSettings() {
        // Single application
        generalSettings.singleApplication = !singleApplicationCheckBox.checked;

        // Default AVFormat options
        layoutsCollectionSettings.defaultAVFormatOptions = JSON.stringify(CCTV_Viewer.parseOptions(defaultAVFormatOptions.text));
    }
}
