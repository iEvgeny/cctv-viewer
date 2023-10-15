import QtQml 2.12
import QtQuick 2.12
import QtMultimedia 5.12
import CCTV_Viewer.Multimedia 1.0

FocusScope {
    id: root

    property string color: "black"

    property var avOptions: ({})

    property alias loops: qmlAvPlayer.loops
    property alias source: qmlAvPlayer.source
    property alias muted: qmlAvPlayer.muted
    property alias volume: qmlAvPlayer.volume
    readonly property alias hasAudio: qmlAvPlayer.hasAudio

    onVisibleChanged: {
        if (visible) {
            if (!timer.running) {
                timer.start();
            }
        } else {
            timer.stop();
            qmlAvPlayer.autoPlay = false;
            qmlAvPlayer.stop();
        }
    }
    Component.onCompleted: {
        if (visible) {
            timer.start();
        }
    }

    Timer {
        id: timer

        interval: 50

        onTriggered: {
            if (root.visible) {
                qmlAvPlayer.autoPlay = true;
            }
        }
    }

    Rectangle {
        color: root.color
        border.color: "#101010"
        anchors.fill: parent

        VideoOutput {
            id: videoOutput

            source: qmlAvPlayer
            anchors.fill: parent
        }

//        Rectangle {
//            id: shutter

//            color: root.color
//            visible: qmlAvPlayer.status !== MediaPlayer.Buffering && qmlAvPlayer.status !== MediaPlayer.Buffered
//            anchors.fill: parent
//        }

        Text {
            id: message

            color: "white"
            visible: qmlAvPlayer.status !== MediaPlayer.Buffered
            anchors.centerIn: parent
        }

        QmlAVPlayer {
            id: qmlAvPlayer

            autoLoad: false

            avOptions: {
                var avOptions = root.avOptions;

                // BUG: Без этого кода значения по умолчанию не устанавливаются. Это не должно происходить в коде плеера!
                Object.assignDefault(avOptions, layoutsCollectionSettings.toJSValue("defaultAVFormatOptions"));

                return avOptions;
            }

            onStatusChanged: {
                switch (status) {
                case MediaPlayer.NoMedia:
                    message.text = qsTr("No media!");
                    break;
                case MediaPlayer.Loading:
                    message.text = qsTr("Loading...");
                    break;
                case MediaPlayer.Loaded:
                    message.text = qsTr("Loaded");
                    break;
                case MediaPlayer.Buffering:
                    break;
                case MediaPlayer.Stalled:
                    message.text = qsTr("Stalled");
                    break;
                case MediaPlayer.Buffered:
                    break;
                case MediaPlayer.EndOfMedia:
                    message.text = qsTr("End of media");
                    break;
                case MediaPlayer.InvalidMedia:
                    message.text = qsTr("Invalid media!");
                    break;
                case MediaPlayer.UnknownStatus:
                    break;
                }
            }

            onBufferProgressChanged: {
                message.text = qsTr("Buffering %1\%").arg(Math.round(bufferProgress * 100));
            }
        }
    }

    function play() { qmlAvPlayer.play(); }
//    function pause() { mediaPlayer.pause(); }
//    function seek(position) { mediaPlayer.seek(position); }
    function stop() { qmlAvPlayer.stop(); }
}
