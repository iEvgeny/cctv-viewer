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
            title: qsTr("View")

            Layout.fillWidth: true

            ColumnLayout {
                width: parent.width

                CheckBox {
                    id: presetIndicatorCheckBox

                    text: qsTr("Show preset indicator")
                }
            }
        }

        GroupBox {
            title: qsTr("Viewport")

            Layout.fillWidth: true

            ColumnLayout {
                width: parent.width

                CheckBox {
                    id: unmuteWhenFullScreenCheckBox

                    text: qsTr("Unmute when the viewport is in full screen mode")
                }

                Label {
                    text: qsTr("Default FFmpeg options")
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
        singleApplicationCheckBox.checked = !generalSettings.singleApplication;
        
        sidebarAutoCollapseCheckBox.checked = rootWindowSettings.sidebarAutoCollapse;
        
        presetIndicatorCheckBox.checked = layoutsCollectionSettings.presetIndicator;

        unmuteWhenFullScreenCheckBox.checked = viewportSettings.unmuteWhenFullScreen;

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
        generalSettings.singleApplication = !singleApplicationCheckBox.checked;
        
        rootWindowSettings.sidebarAutoCollapse = sidebarAutoCollapseCheckBox.checked;
        
        layoutsCollectionSettings.presetIndicator = presetIndicatorCheckBox.checked;

        viewportSettings.unmuteWhenFullScreen = unmuteWhenFullScreenCheckBox.checked;

        layoutsCollectionSettings.defaultAVFormatOptions = JSON.stringify(Utils.parseOptions(defaultAVFormatOptions.text));
    }
}
