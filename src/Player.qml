import QtQml 2.12
import QtQuick 2.12
import QtMultimedia 5.12
import CCTV_Viewer.Multimedia 1.0

FocusScope {
    id: root

    property string color: "black"

    property var avOptions: ({})

    // How the video is fitted into the viewport:
    //   VideoOutput.PreserveAspectFit  - fit, keep aspect ratio (letterbox)
    //   VideoOutput.PreserveAspectCrop - fill, keep aspect ratio (crop)
    //   VideoOutput.Stretch            - stretch to fill
    property int fillMode: VideoOutput.PreserveAspectFit

    // When false the stream is stopped and the network connection released.
    // Used to pause hidden/background viewports to save bandwidth.
    property bool active: true

    readonly property bool shouldPlay: visible && active

    // Holds the last frame grabbed from the video output. It is shown in place
    // of a black rectangle while a new stream is loading (e.g. when switching
    // between the grid and a full-size/single view swaps the stream source).
    property var _lastFrame: null

    property alias loops: qmlAvPlayer.loops
    property alias source: qmlAvPlayer.source
    property alias muted: qmlAvPlayer.muted
    property alias volume: qmlAvPlayer.volume
    readonly property alias hasAudio: qmlAvPlayer.hasAudio

    onShouldPlayChanged: updatePlayback()
    Component.onCompleted: updatePlayback()

    function updatePlayback() {
        if (shouldPlay) {
            if (!timer.running) {
                timer.start();
            }
        } else {
            timer.stop();
            qmlAvPlayer.autoPlay = false;
            qmlAvPlayer.stop();
        }
    }

    Timer {
        id: timer

        interval: 50

        onTriggered: {
            if (root.shouldPlay) {
                qmlAvPlayer.autoPlay = true;
            }
        }
    }

    // Periodically remember the last displayed frame while the stream is
    // playing so it can be used as a placeholder thumbnail when the stream is
    // reloaded (grid <-> full-size/single view).
    Timer {
        id: thumbnailTimer

        interval: 1000
        repeat: true
        running: root.shouldPlay && qmlAvPlayer.status === MediaPlayer.Buffered

        onTriggered: root.grabThumbnail()
    }

    function grabThumbnail() {
        videoOutput.grabToImage(function(result) {
            if (result !== null) {
                root._lastFrame = result;
            }
        });
    }

    Rectangle {
        color: root.color
        border.color: "#101010"
        anchors.fill: parent

        VideoOutput {
            id: videoOutput

            source: qmlAvPlayer
            fillMode: root.fillMode
            anchors.fill: parent
        }

        // Last known frame, shown instead of a black rectangle while the new
        // stream buffers after a source change.
        Image {
            id: thumbnail

            anchors.fill: parent
            cache: false
            smooth: true
            source: root._lastFrame ? root._lastFrame.url : ""
            visible: source.toString() !== "" && qmlAvPlayer.status !== MediaPlayer.Buffered
            fillMode: {
                switch (root.fillMode) {
                case VideoOutput.PreserveAspectCrop:
                    return Image.PreserveAspectCrop;
                case VideoOutput.Stretch:
                    return Image.Stretch;
                default:
                    return Image.PreserveAspectFit;
                }
            }
            clip: true
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
                    message.text = qsTr("No media");
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
                    // Capture a fresh frame as soon as playback resumes so a
                    // recent thumbnail is available for the next reload.
                    root.grabThumbnail();
                    break;
                case MediaPlayer.EndOfMedia:
                    message.text = qsTr("End of media");
                    break;
                case MediaPlayer.InvalidMedia:
                    message.text = qsTr("Error!");
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
