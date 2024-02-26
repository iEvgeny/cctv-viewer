import QtQuick 2.12
import CCTV_Viewer.Utils 1.0

MouseArea {
    id: root

    enabled: false
    acceptedButtons: Qt.NoButton

    property bool autoHide: false
    property int autoHideTimeout: 0  // ms

    readonly property alias hidden: d.hidden

    onAutoHideChanged: {
        if (!autoHide) {
            d.hidden = false;
        }
    }

    QtObject {
        id: d

        property bool hidden: false
        property int hiddenCursor: Qt.ArrowCursor

        onHiddenChanged: {
            if (hidden) {
                hiddenCursor = cursorShape;
                root.cursorShape = Qt.BlankCursor;
            } else {
                root.cursorShape = hiddenCursor;
            }
        }

        function eventFiltered() {
            d.hidden = false;
            timer.restart();
        }
    }

    Timer {
        id: timer

        running: root.autoHide
        interval: root.autoHideTimeout
        onTriggered: d.hidden = true
    }

    EventFilter {
        enabled: root.autoHide
        scope: EventFilter.Application
        eventTypes: [ "MouseMove", "MouseButtonPress" ]
        eventProperties: false
        onEventFiltered: d.eventFiltered()
    }

    function set(cursorShape) {
        root.cursorShape = cursorShape;
    }
    function reset() {
        root.cursorShape = Qt.ArrowCursor;
    }
}
