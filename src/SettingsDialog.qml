import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import CCTV_Viewer.Themes 1.0
import CCTV_Viewer.Utils 1.0

ThemedDialog {
    title: qsTr("Settings")
    width: 530
    height: 680
    minimumWidth: 450
    minimumHeight: 620

    onVisibleChanged: {
        if (visible) {
            loadSettings();
        }
    }
    onAccepted: {
        saveSettings()
        close()
    }

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

                CheckBox {
                    id: hideCursorWhenFullScreenCheckBox

                    text: qsTr("Hide cursor in full screen mode")
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

        GroupBox {
            title: qsTr("Presets")

            Layout.fillWidth: true

            ColumnLayout {
                width: parent.width

                RowLayout  {
                    width: parent.width

                    CheckBox {
                        id: carouselRunningCheckBox

                        text: qsTr("Carousel interval (sec):")

                        Layout.fillWidth: true
                    }

                    SpinBox {
                        id: carouselIntervalSpinBox

                        property int valueFactor: 1000

                        enabled: carouselRunningCheckBox.checked

                        stepSize: 100
                        from: stepSize
                        to: 300 * stepSize
                        editable: true

                        validator: DoubleValidator {
                            decimals: 2
                            bottom: Math.min(carouselIntervalSpinBox.from, carouselIntervalSpinBox.to)
                            top:  Math.max(carouselIntervalSpinBox.from, carouselIntervalSpinBox.to)
                        }
                        textFromValue: function(value, locale) {
                            return Number(value / valueFactor).toLocaleString(locale, 'f', validator.decimals)
                        }
                        valueFromText: function(text, locale) {
                            return Number.fromLocaleString(locale, text) * valueFactor
                        }
                    }
                }
            }
        }
    }

    function loadSettings() {
        singleApplicationCheckBox.checked = !generalSettings.singleApplication;
        
        sidebarAutoCollapseCheckBox.checked = rootWindowSettings.sidebarAutoCollapse;
        
        presetIndicatorCheckBox.checked = layoutsCollectionSettings.presetIndicator;

        hideCursorWhenFullScreenCheckBox.checked = viewSettings.hideCursorWhenFullScreen;

        unmuteWhenFullScreenCheckBox.checked = viewportSettings.unmuteWhenFullScreen;

        carouselRunningCheckBox.checked = presetsSettings.carouselRunning;
        carouselIntervalSpinBox.value = presetsSettings.carouselInterval;

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

        viewSettings.hideCursorWhenFullScreen = hideCursorWhenFullScreenCheckBox.checked;

        viewportSettings.unmuteWhenFullScreen = unmuteWhenFullScreenCheckBox.checked;

        presetsSettings.carouselRunning = carouselRunningCheckBox.checked;
        presetsSettings.carouselInterval = carouselIntervalSpinBox.value;

        layoutsCollectionSettings.defaultAVFormatOptions = JSON.stringify(Utils.parseOptions(defaultAVFormatOptions.text));
    }
}
