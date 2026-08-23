import QtQml 2.12
import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Dialogs 1.3
import CCTV_Viewer.Utils 1.0
import CCTV_Viewer.Onvif 1.0

Dialog {
    id: root

    title: qsTr("Add ONVIF device")
    modality: Qt.ApplicationModal
    standardButtons: StandardButton.Close

    width: 460

    property string statusMessage: ""

    onVisibleChanged: {
        if (visible) {
            onvifDevice.reset();
            discovery.reset();
            statusMessage = "";
            channelsModel.clear();
        }
    }

    OnvifDevice {
        id: onvifDevice

        host: hostField.text
        port: parseInt(portField.text) || 80
        username: userField.text
        password: passwordField.text

        onErrorChanged: {
            if (error !== "") {
                root.statusMessage = error;
            }
        }
        onChannelsChanged: {
            channelsModel.clear();
            var subCount = 0;
            for (var i = 0; i < channels.length; ++i) {
                var ch = channels[i];
                if (ch.subUrl) {
                    ++subCount;
                }
                channelsModel.append({
                    "name": ch.name,
                    "mainUrl": ch.mainUrl,
                    "subUrl": ch.subUrl ? ch.subUrl : "",
                    "mainResolution": ch.mainResolution ? ch.mainResolution : "",
                    "subResolution": ch.subResolution ? ch.subResolution : "",
                    "selected": true
                });
            }
            if (channelsModel.count > 0) {
                if (subCount === channelsModel.count) {
                    root.statusMessage = qsTr("Found %1 channel(s), each with a sub stream.").arg(channelsModel.count);
                } else if (subCount > 0) {
                    root.statusMessage = qsTr("Found %1 channel(s); %2 have a sub stream.").arg(channelsModel.count).arg(subCount);
                } else {
                    root.statusMessage = qsTr("Found %1 channel(s), but no sub streams were detected. Enable sub streams on the device for better grid performance, or set them manually.").arg(channelsModel.count);
                }
            }
        }
    }

    OnvifDiscovery {
        id: discovery
    }

    ListModel {
        id: channelsModel
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        GroupBox {
            title: qsTr("Device")

            Layout.fillWidth: true

            GridLayout {
                columns: 2
                anchors.fill: parent
                columnSpacing: 8
                rowSpacing: 6

                Label { text: qsTr("Host / IP address:") }
                TextField {
                    id: hostField

                    placeholderText: qsTr("192.168.1.10")
                    selectByMouse: true
                    Layout.fillWidth: true
                }

                Label { text: qsTr("Port:") }
                TextField {
                    id: portField

                    text: "80"
                    inputMethodHints: Qt.ImhDigitsOnly
                    validator: IntValidator { bottom: 1; top: 65535 }
                    selectByMouse: true
                    Layout.preferredWidth: 90
                }

                Label { text: qsTr("Username:") }
                TextField {
                    id: userField

                    text: "admin"
                    selectByMouse: true
                    Layout.fillWidth: true
                }

                Label { text: qsTr("Password:") }
                TextField {
                    id: passwordField

                    echoMode: TextInput.Password
                    selectByMouse: true
                    Layout.fillWidth: true
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Button {
                text: discovery.scanning ? qsTr("Scanning…") : qsTr("Discover")
                enabled: !discovery.scanning
                onClicked: {
                    root.statusMessage = qsTr("Scanning the local network…");
                    discovery.scan(4000);
                }
            }

            Button {
                text: qsTr("Connect")
                enabled: !onvifDevice.busy && hostField.text.trim() !== ""
                onClicked: {
                    root.statusMessage = qsTr("Connecting…");
                    onvifDevice.fetchChannels();
                }
            }

            BusyIndicator {
                running: onvifDevice.busy || discovery.scanning
                implicitWidth: 24
                implicitHeight: 24
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }
        }

        RowLayout {
            Layout.fillWidth: true

            Label { text: qsTr("Subnet:") }

            TextField {
                id: subnetField

                placeholderText: qsTr("192.168.1.0/24 or 10.0.0.1-10.0.0.50")
                selectByMouse: true
                Layout.fillWidth: true
            }

            Button {
                text: qsTr("Scan subnet")
                enabled: !discovery.scanning && subnetField.text.trim() !== ""
                onClicked: {
                    root.statusMessage = qsTr("Scanning subnet %1…").arg(subnetField.text.trim());
                    discovery.scanSubnet(subnetField.text.trim(), 6000);
                }
            }
        }

        // Discovered devices
        GroupBox {
            title: qsTr("Discovered devices")
            visible: discovery.devices.length > 0

            Layout.fillWidth: true

            Flow {
                width: parent.width
                spacing: 6

                Repeater {
                    model: discovery.devices

                    Button {
                        text: modelData.host + ":" + modelData.port
                        onClicked: {
                            hostField.text = modelData.host;
                            portField.text = String(modelData.port);
                        }
                    }
                }
            }
        }

        // Channels
        GroupBox {
            title: qsTr("Channels")

            Layout.fillWidth: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    visible: channelsModel.count > 0

                    Button {
                        text: qsTr("Select all")
                        onClicked: setAllSelected(true)
                    }
                    Button {
                        text: qsTr("Select none")
                        onClicked: setAllSelected(false)
                    }
                    Item { Layout.fillWidth: true }
                }

                ScrollView {
                    clip: true

                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
                    Layout.minimumHeight: 120

                    ListView {
                        model: channelsModel
                        spacing: 2

                        delegate: RowLayout {
                            width: ListView.view ? ListView.view.width : 0

                            CheckBox {
                                checked: model.selected
                                onToggled: channelsModel.setProperty(index, "selected", checked)
                            }

                            ColumnLayout {
                                spacing: 0
                                Layout.fillWidth: true

                                Label {
                                    text: model.name
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Label {
                                    text: {
                                        var s = model.mainResolution ? qsTr("main %1").arg(model.mainResolution) : qsTr("main stream");
                                        if (model.subUrl) {
                                            s += model.subResolution ? qsTr(", sub %1").arg(model.subResolution) : qsTr(", sub stream");
                                        }
                                        return s;
                                    }
                                    opacity: 0.6
                                    font.pointSize: rootWindow.font.pointSize * 0.9
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }
            }
        }

        Label {
            text: root.statusMessage
            wrapMode: Text.WordWrap
            visible: text !== ""

            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true

            Item { Layout.fillWidth: true }

            Button {
                text: qsTr("Add selected to layout")
                enabled: channelsModel.count > 0 && hasSelection()
                highlighted: true
                onClicked: addSelected()
            }
        }
    }

    function setAllSelected(value) {
        for (var i = 0; i < channelsModel.count; ++i) {
            channelsModel.setProperty(i, "selected", value);
        }
    }

    function hasSelection() {
        for (var i = 0; i < channelsModel.count; ++i) {
            if (channelsModel.get(i).selected) {
                return true;
            }
        }
        return false;
    }

    function addSelected() {
        var layoutModel = Utils.currentModel();
        var count = layoutModel.size.width * layoutModel.size.height;
        var slot = 0;
        var added = 0;

        for (var c = 0; c < channelsModel.count; ++c) {
            var ch = channelsModel.get(c);
            if (!ch.selected) {
                continue;
            }

            // Find the next empty viewport.
            while (slot < count && String(layoutModel.get(slot).url) !== "") {
                ++slot;
            }
            if (slot >= count) {
                break;
            }

            layoutModel.get(slot).url = ch.mainUrl;
            layoutModel.get(slot).subStreamUrl = ch.subUrl;
            ++slot;
            ++added;
        }

        if (added < countSelected()) {
            root.statusMessage = qsTr("Added %1 channel(s). Not enough free viewports for the rest — increase the window division.").arg(added);
        } else {
            root.close();
        }
    }

    function countSelected() {
        var n = 0;
        for (var i = 0; i < channelsModel.count; ++i) {
            if (channelsModel.get(i).selected) {
                ++n;
            }
        }
        return n;
    }
}
