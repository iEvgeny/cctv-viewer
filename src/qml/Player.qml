import QtQuick 2.0
//import QtMultimedia 5.0
import QtAV 1.7
import '../js/utils.js' as CCTV_Viewer

FocusScope {
    id: root

    property bool keepAlive: false
    property string color: 'black'
    property int probesize: 200000  // 200 KB
    property int analyzeduration: 0  // 0 µs

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

//        VideoOutput {
        VideoOutput2 {            id: videoOutput

            source: mediaPlayer
            anchors.fill: parent
        }

        Text {
            id: message

            color: 'white'
            visible: mediaPlayer.status != MediaPlayer.Buffered
            anchors.centerIn: parent
        }

//        MediaPlayer {
        AVPlayer {
            id: mediaPlayer

            avFormatOptions: {
                'probesize': root.probesize,
                'analyzeduration': root.analyzeduration,
                'sync': 'ext'
            }

            onError: {
                if (MediaPlayer.NoError !== error) {
                    if (keepAlive) {
                        play();
                    }

                    CCTV_Viewer.log_error(errorString);
                }
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
            }

            onBufferProgressChanged: {
                message.text = qsTr('Buffering %1\%').arg(Math.round(bufferProgress * 100));
            }
        }
    }

    function play() { mediaPlayer.play(); }
    function pause() { mediaPlayer.pause(); }
    function seek(position) { mediaPlayer.seek(position); }
    function stop() { mediaPlayer.stop(); }
}
