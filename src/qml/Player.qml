import QtQuick 2.0
import QtMultimedia 5.0
import '../js/script.js' as CCTV_Viewer

FocusScope {
    id: root

    property bool keepAlive: false
    property string color: 'black'

    property alias autoLoad: mediaPlayer.autoLoad
    property alias autoPlay: mediaPlayer.autoPlay
    property alias duration: mediaPlayer.duration
    property alias error: mediaPlayer.error
    property alias errorString: mediaPlayer.errorString
    property alias loops: mediaPlayer.loops
    property alias source: mediaPlayer.source
    property alias status: mediaPlayer.status
    property alias metaData: mediaPlayer.metaData
    property alias muted: mediaPlayer.muted
    property alias playbackRate: mediaPlayer.playbackRate
    property alias playbackState: mediaPlayer.playbackState
    property alias position: mediaPlayer.position
    property alias volume: mediaPlayer.volume

    Rectangle {
        color: root.color
        anchors.fill: parent

        Text {
            id: message

            color: 'white'
            visible: (videoOutput.opacity < 1) ? true : false
            anchors.centerIn: parent
        }

        VideoOutput {
            id: videoOutput

            source: mediaPlayer
            anchors.fill: parent
        }

        MediaPlayer {
            id: mediaPlayer

            onError: {
                if (MediaPlayer.NoError != error) {
                    if (keepAlive) {
                        play();
                    }

                    CCTV_Viewer.log_error(errorString);
                }
            }

            onStatusChanged: {
                switch (status) {
                case MediaPlayer.NoMedia:
                    videoOutput.opacity = 0;
                    message.text = qsTr('No media!');
                    break;
                case MediaPlayer.Loading:
                    videoOutput.opacity = 0;
                    message.text = qsTr('Loading...');
                    break;
                case MediaPlayer.Loaded:
                    videoOutput.opacity = 0;
                    message.text = qsTr('Loaded');
                    break;
                case MediaPlayer.Buffering:
                case MediaPlayer.Stalled:
                    videoOutput.opacity = 0;
                    break;
                case MediaPlayer.Buffered:
                    videoOutput.opacity = 1;
                    break;
                case MediaPlayer.EndOfMedia:
                    videoOutput.opacity = 0;
                    message.text = qsTr('End of media');
                    break;
                case MediaPlayer.InvalidMedia:
                    videoOutput.opacity = 0;
                    message.text = qsTr('Invalid media!');
                    break;
                case MediaPlayer.UnknownStatus:
                    break;
                }
            }

            onBufferProgressChanged: {
                message.text = qsTr('Buffering %1\%').arg(bufferProgress * 100);
            }
        }
    }

    function play() { mediaPlayer.play(); }
    function pause() { mediaPlayer.pause(); }
    function seek(position) { mediaPlayer.seek(position); }
    function stop() { mediaPlayer.stop(); }
}
