import QtQuick 2.7
import QtQml.Models 2.2
import CCTV_Viewer.Enums 1.0
import '../js/script.js' as CCTV_Viewer

Item {
    id: root

    property var listModel: model

    property alias count: model.count

    signal changed()
    signal dataChanged()

    onCountChanged: changed()
    Component.onCompleted: {
        model.dataChanged.connect(function() { root.dataChanged(); root.changed(); });
    }

    QtObject {
        id: d

        property var currentCall: null

        function setCurrentCall(current) {
            var prev = currentCall;

            currentCall = current;

            return prev;
        }
    }

    ListModel {
        id: model

        ListElement {
            url: ''
            columnSpan: 1
            rowSpan: 1
            visible: Viewport.Visible
            volume: 0.0
        }

        function defaultElement() {
            var clone = {
                url: '',
                columnSpan: 1,
                rowSpan: 1,
                visible: Viewport.Visible,
                volume: 0.0
            };

            return clone;
        }
    }

    function get(index) {
        return model.get(index);
    }

    function parse(string, clear) {
        if (!string.isEmpty()) {
            try {
                var jsModel = JSON.parse(string);

                if (typeof(jsModel) === 'object') {
                    if (clear !== undefined && clear) {
                        model.clear();
                    }

                    for (var i = 0; i < jsModel.length; ++i) {
                        var element = jsModel[i];

                        if (typeof(element) === 'object') {
                            if (i < model.count) {
                                model.set(i, element);
                            } else {
                                model.append(element);
                            }
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
        var jsModel = [];

        for (var i = 0; i < model.count; ++i) {
            // HACK: По непонятным причинам "последнее" свойство объекта всегда дублируется (ключ и значение),
            // потому мы вынуждены применить несколько более сложный подход для добавления объекта в массив
            // учитывающий данный факт взамен очевидного и куда более простого.
            //jsModel.push(model.get(i));
            var obj = {};
            var prevKey = '';
            var element = model.get(i);

            for (var key in element) {
                if (key !== prevKey) {
                    obj[key] = element[key];
                    prevKey = key;
                }
            }

            jsModel.push(obj);
        }

        return JSON.stringify(jsModel);
    }

    function columnFromIndex(index, division) {
        return index % division;
    }

    function rowFromIndex(index, division) {
        return Math.floor(index / division);
    }

    function indexFromAddress(column, row, division) {
        return row * division + column;
    }

    function spanningIndex(index, division) {
        var spannedElement = model.get(index);
        var spanningIndex = indexFromAddress(columnFromIndex(index, division) + spannedElement.columnSpan,
                                             rowFromIndex(index, division) + spannedElement.rowSpan, division);

        if (spanningIndex < 0 || spanningIndex >= model.count ||
            model.get(spanningIndex).columnSpan + spannedElement.columnSpan < 1 ||
            model.get(spanningIndex).rowSpan + spannedElement.rowSpan < 1) {
            return -1;
        }

        return spanningIndex;
    }

    function normalize(division, quadSpan) {
        var cells = Math.pow(division, 2);

        // Protection against exceeding the maximum call stack size & performance optimization.
        if (d.currentCall !== normalize) {
            var prevCall = d.setCurrentCall(normalize);

            // Add missing items.
            if (model.count < cells) {
                for (var i = 0; model.count < cells; ++i) {
                    model.append(listModel.defaultElement());
                }
            }

            // Validate model.
            for (var index = 0; index < model.count; ++index) {
                var element = model.get(index);
                var column = columnFromIndex(index, division);
                var row = rowFromIndex(index, division);

                // Mormalize properties
                element.url = (element.url !== undefined) ? element.url : '';
                element.volume = element.volume.clamp(0.0, 1.0);

                if (index < cells) {
                    if (index > 0 && element.visible === Viewport.Spanned) {
                        // Mormalize properties
                        element.columnSpan = element.columnSpan.clamp(-column, 0);
                        element.rowSpan = element.rowSpan.clamp(-row, 0);

                        // Check for span
                        if (root.spanningIndex(index, division) < 0) {
                            element.visible = Viewport.Visible;
                            // Recheck
                            --index;
                        }
                    } else {
                        if (quadSpan === true) {
                            element.rowSpan = element.columnSpan;
                        }

                        // Mormalize properties
                        element.columnSpan = element.columnSpan.clamp(1, division - column);
                        element.rowSpan = element.rowSpan.clamp(1, division - row);

                        if (quadSpan === true) {
                            var span = Math.min(element.columnSpan, element.rowSpan);

                            element.columnSpan = span;
                            element.rowSpan = span;
                        }

                        element.visible = Viewport.Visible;

                        normalize_1:
                        // Iterate spanned elements
                        for (var rowSpan = 0; rowSpan < element.rowSpan; ++rowSpan) {
                            for (var columnSpan = 0; columnSpan < element.columnSpan; ++columnSpan) {
                                var spannedIndex = index + columnSpan + rowSpan * division;

                                if (spannedIndex < model.count && index != spannedIndex) {
                                    // Check for span
                                    if (model.get(spannedIndex).visible === Viewport.Spanned) {
                                        var spanningIndex = root.spanningIndex(spannedIndex, division);

                                        if (spanningIndex >= 0 && spanningIndex !== index) {
                                            element.columnSpan = 1;
                                            element.rowSpan = 1;

                                            break normalize_1;
                                        }
                                    }

                                    model.get(spannedIndex).columnSpan = -columnSpan;
                                    model.get(spannedIndex).rowSpan = -rowSpan;
                                    model.get(spannedIndex).visible = Viewport.Spanned;
                                }
                            }
                        }
                    }
                } else {
                    element.columnSpan = 0;
                    element.rowSpan = 0;
                    element.visible = Viewport.Hidden;
                }
            }

            d.setCurrentCall(prevCall);
        }
    }
}
