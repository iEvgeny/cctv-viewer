import QtQuick 2.12
import CCTV_Viewer.Utils 1.0

MouseArea {
    id: root

    enabled: false
    acceptedButtons: Qt.NoButton

    property bool hidden: false
    property int hideTimeout: 0  // ms

    onHideTimeoutChanged: {
        if (hideTimeout > 0) {
            timer.start();
        } else {
            timer.stop();
            hidden = false;
        }
    }
    onHiddenChanged: {
        if (hidden) {
            d.hiddenCursor = cursorShape;
            cursorShape = Qt.BlankCursor;
        } else {
            cursorShape = d.hiddenCursor;
        }
    }

    QtObject {
        id: d

        property int hiddenCursor: Qt.ArrowCursor

        function eventFiltered() {
            root.hidden = false;
            timer.restart();
        }
    }

    Timer {
        id: timer

        interval: root.hideTimeout
        onTriggered: root.hidden = true
    }

    EventFilter {
        enabled: root.hideTimeout > 0
        scope: EventFilter.Application
        eventType: "MouseMove"
        eventProperties: false
        onEventFiltered: d.eventFiltered()
    }
    EventFilter {
        enabled: root.hideTimeout > 0
        scope: EventFilter.Application
        eventType: "MouseButtonPress"
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
