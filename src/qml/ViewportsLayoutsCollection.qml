import QtQuick 2.6
import Qt.labs.settings 1.0

Item {
    id: root

    property int currentIndex: 0
    readonly property alias count: d.count
    readonly property alias currentLayout: d.currentLayout

    signal dataChanged()

    onDataChanged: sync()
    onCurrentIndexChanged: d.currentLayout = get(currentIndex);
    onCountChanged: currentIndex = currentIndex.clamp(0, count - 1);
    onCurrentLayoutChanged: dataChanged()
    Component.onCompleted: {
        d.parse(settings.collection);
        d.completed = true;
    }

    QtObject {
        id: d

        property int count: 1
        property var currentLayout: get(currentIndex)
        property var collection: []
        property bool completed: false

        function parse(string) {
            if (!string.isEmpty()) {
                try {
                    var jsCollection = JSON.parse(string);

                    if (jsCollection instanceof Array) {
                        for (var i = 0; i < jsCollection.length; ++i) {
                            var jsLayout = jsCollection[i];

                            if (jsLayout instanceof Object) {
                                root.set(i, jsLayout);
                            }
                        }
                    }
                } catch(err) {
                    CCTV_Viewer.log_error(qsTr('Error reading configuration.'));
                }
            }

            return this;
        }

        function stringify() {
            return JSON.stringify(d.collection);
        }
    }

    Settings {
        id: settings

        category: 'ViewportsLayoutsCollection'

        property alias currentIndex: root.currentIndex
        property string collection
    }

    function get(index) {
        var jsLayout = d.collection[index];

        if (jsLayout instanceof Object) {
            return jsLayout;
        }

        // Init element
        return set(index, {});
    }

    function set(index, object) {
        var jsLayout = d.collection[index];

        if (jsLayout instanceof Object) {
            Object.assign(jsLayout, object);
        } else {
            d.collection[index] = object;
        }

        d.count = d.collection.length;
        dataChanged();

        return d.collection[index];
    }

    function append() {
        d.collection.push({});
        d.count = d.collection.length;
        dataChanged();
    }

    function remove(index) {
        if (count != 1) {
            d.collection.splice(index, 1);
            d.count = d.collection.length;
            d.currentLayout = get(currentIndex);
        }
    }

    function sync() {
        if (d.completed) {
            settings.collection = d.stringify();
        }
    }
}
