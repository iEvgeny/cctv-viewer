import QtQuick 2.0
import QtMultimedia 5.0
import CCTV_Viewer.Multimedia 1.0
import '../js/utils.js' as CCTV_Viewer

FocusScope {
    id: root

    property bool keepAlive: false
    property string color: 'black'
    property bool autoLoad: true
    property bool autoPlay: false
    property int probesize: 500000  // 500 KB
    property int analyzeduration: 0  // 0 µs

//    property alias duration: mediaPlayer.duration
    property alias loops: ffPlayer.loops
    property alias source: ffPlayer.source
    property alias status: ffPlayer.status
//    property alias metaData: mediaPlayer.metaData
    property alias muted: ffPlayer.muted
//    property alias playbackRate: mediaPlayer.playbackRate
//    property alias playbackState: mediaPlayer.playbackState
//    property alias position: mediaPlayer.position
    property alias volume: ffPlayer.volume

    readonly property alias hasAudio: ffPlayer.hasAudio

    onVisibleChanged: {
        if (visible && autoPlay) {
            ffPlayer.autoPlay = true;
        } else {
            ffPlayer.autoPlay = false;
            ffPlayer.stop();
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
                ffPlayer.autoPlay = true;
            }
        }
    }

    Rectangle {
        color: root.color
        anchors.fill: parent

        VideoOutput {
            id: videoOutput

            source: ffPlayer
            anchors.fill: parent
        }

//        Rectangle {
//            id: shutter

//            color: root.color
//            visible: ffPlayer.status !== MediaPlayer.Buffering && ffPlayer.status !== MediaPlayer.Buffered
//            anchors.fill: parent
//        }

        Text {
            id: message

            color: 'white'
            visible: ffPlayer.status !== MediaPlayer.Buffered
            anchors.centerIn: parent
        }

//        MediaPlayer {
        FFPlayer {
            id: ffPlayer

            autoLoad: false

            ffmpegFormatOptions: {
                'probesize': root.probesize,
                'analyzeduration': root.analyzeduration,
                'sync': 'ext'
            }

            onStatusChanged: {
                switch (status) {
                case MediaPlayer.NoMedia:
                    message.text = qsTr('No media!');
                    break;
                case MediaPlayer.Loading:
                    message.text = qsTr('Loading...');
                    break;
                case MediaPlayer.Loaded:
                    message.text = qsTr('Loaded');
                    break;
                case MediaPlayer.Buffering:
                    break;
                case MediaPlayer.Stalled:
                    message.text = qsTr('Stalled');
                    break;
                case MediaPlayer.Buffered:
                    break;
                case MediaPlayer.EndOfMedia:
                    message.text = qsTr('End of media');
                    break;
                case MediaPlayer.InvalidMedia:
                    message.text = qsTr('Invalid media!');
                    break;
                case MediaPlayer.UnknownStatus:
                    break;
                }

//                if (playbackState === MediaPlayer.StoppedState) {
//                    if (keepAlive) {
//                        CCTV_Viewer.sleep(500);
//                        play();
//                    }
//                }
            }

            onBufferProgressChanged: {
                message.text = qsTr('Buffering %1\%').arg(Math.round(bufferProgress * 100));
            }
        }
    }

    function play() { ffPlayer.play(); }
//    function pause() { mediaPlayer.pause(); }
//    function seek(position) { mediaPlayer.seek(position); }
    function stop() { ffPlayer.stop(); }
}
