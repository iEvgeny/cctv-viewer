import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.3
import CCTV_Viewer.Utils 1.0

Dialog {
    title: qsTr("Settings")
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
            title: qsTr("General")

            Layout.fillWidth: true

            ColumnLayout {

                width: parent.width

                CheckBox {
                    id: singleApplicationCheckBox

                    text: qsTr("Allow running multiple application instances")
                }

                CheckBox {
                    id: sidebarAutoCollapseCheckBox

                    text: qsTr("Automatically collapse sidebar") 
                }
            }
        }

        GroupBox {
            title: qsTr("Viewports")

            Layout.fillWidth: true

            ColumnLayout {
                width: parent.width

                CheckBox {
                    id: presetIndicatorCheckBox

                    text: qsTr("Show preset indicator")
                }

                Label {
                    text: qsTr("Default AVFormat options")
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
        
        // Auto collapse sidebar option
        sidebarAutoCollapseCheckBox.checked = rootWindowSettings.sidebarAutoCollapse;
        
        // Preset indicator
        presetIndicatorCheckBox.checked = layoutsCollectionSettings.presetIndicator;

        // Default AVFormat options
        defaultAVFormatOptions.text = "";
        var options = layoutsCollectionSettings.toJSValue("defaultAVFormatOptions");
        for (var key in options) {
            if (typeof options[key] === "string" || typeof options[key] === "number") {
                defaultAVFormatOptions.text += "-%1 %2 ".arg(key).arg(options[key]);
            }
        }
        defaultAVFormatOptions.text = defaultAVFormatOptions.text.trim();
    }

    function saveSettings() {
        // Single application
        generalSettings.singleApplication = !singleApplicationCheckBox.checked;
        
        // Auto collapse sidebar option
        rootWindowSettings.sidebarAutoCollapse = sidebarAutoCollapseCheckBox.checked;
        
        // Preset indicator
        layoutsCollectionSettings.presetIndicator = presetIndicatorCheckBox.checked;

        // Default AVFormat options
        layoutsCollectionSettings.defaultAVFormatOptions = JSON.stringify(Utils.parseOptions(defaultAVFormatOptions.text));
    }
}
