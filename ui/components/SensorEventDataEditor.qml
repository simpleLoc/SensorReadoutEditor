import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12
import Qt.labs.qmlmodels 1.0

import SensorReadout 1.0
import "SensorEvent.js" as SensorEvent

Item {
    SystemPalette { id: systemPalette; colorGroup: SystemPalette.Active }

    property var sensorEvent: null
    property var __parsedEditEvent: new SensorEvent.SensorEvent(sensorEvent)
    property var __parsedEditEventData: __parsedEditEvent.get()

    property bool __isFixedParameter: (__parsedEditEventData && __parsedEditEventData.type === "fixedParameter")
    property bool __isMatrixParameter: (__parsedEditEventData && __parsedEditEventData.type === "matrixParameter")

    function __applyChange() {
        // trickle changes back up the parsing pipeline.
        __parsedEditEvent.set(__parsedEditEventData);
        __parsedEditEventData = __parsedEditEvent.get();
        sensorEvent.dataRaw = __parsedEditEvent.toRawData();
    }

    Component {
        id: parameterEditorFloat

        TextField {
            selectByMouse: true
            width: parent.width
            padding: 4
            text: parameterModel.value
            onEditingFinished: __applyChange()
            onTextEdited: {
                //__parsedEditEventData.value[modelIndex].value = text
                parameterModel.value = text;
            }
        }
    }
    Component {
        id: parameterEditorInteger

        TextField {
            selectByMouse: true
            width: parent.width
            padding: 4
            text: parameterModel.value
            onEditingFinished: __applyChange()
            onTextEdited: {
                parameterModel.value = text;
            }
        }
    }
    Component {
        id: parameterEditorString

        TextField {
            selectByMouse: true
            width: parent.width
            padding: 4
            text: parameterModel.value
            onEditingFinished: __applyChange()
            onTextEdited: {
                parameterModel.value = text;
            }
        }
    }
    Component {
        id: parameterEditorTable
        ListView {
            id: tableEditListView
            // bind modelIndex to a property with another name, because we need to
            // access it in the item delegate, and that defines a modelIndex property itself,
            // shadowing the one accessible here.
            property int modelFieldIndex: modelIndex

            implicitHeight: implicitContentHeight
            header: ListViewColumnHeader {
                id: parameterEditorTableHeader
                height: 25
                width: parent.width
                columns: {
                    let columns = [];
                    for(let columnName of parameterModel.columns) {
                        let column = Qt.createQmlObject("ListViewColumn {}", parameterEditorTableHeader, columnName);
                        column.text = columnName;
                        columns.push(column);
                    }
                    return columns;
                }
            }

            // array of arrays:
            // [[row0], [row1], [col0row2, col1row2, col2row2]]
            model: parameterModel.value
            Component {
                id: parameterEditorTableDelegate
                RowLayout {
                    id: parmeterEditorTableRowLayout
                    property int rowIndex: index

                    width: ListView.width
                    spacing: 0
                    Repeater { // repeat columns
                        model: modelData
                        Loader {
                            Layout.preferredWidth: tableEditListView.headerItem.columnWidths[index]
                            // properties to forward to the editor:
                            // this property binding is so complicated, because we need to pass it by-reference instead of by-value
                            property var parameterModel: __parsedEditEventData.value[modelFieldIndex].value[rowIndex][index]
                            property int modelIndex: index;
                            sourceComponent: {
                                switch(modelData.type) {
                                    case "float": return parameterEditorFloat;
                                    case "integer": return parameterEditorInteger;
                                    case "string": return parameterEditorString;
                                }
                                return null;
                            }
                        }
                    }
                }
            }
            delegate: parameterEditorTableDelegate
        }
    }

    // +++
    // + FixedParameter
    // +++
    ListView {
        id: fixedParameterEditor
        visible: __isFixedParameter
        enabled: __isFixedParameter
        anchors.fill: parent
        reuseItems: false

        header: ListViewColumnHeader {
            height: 25
            width: parent.width
            columns: [
                ListViewColumn { text: "Parameter"; fixedWidth: 125 },
                ListViewColumn { text: "Value" }
            ]
        }

        model: (__isFixedParameter) ? __parsedEditEventData.value : []
        Component {
            id: fixedParameterDelegate
            RowLayout {
                width: ListView.width
                spacing: 0
                Label {
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                    Layout.preferredWidth: fixedParameterEditor.headerItem.columnWidths[0]
                    text: modelData.name
                    padding: 4
                }
                Loader {
                    Layout.preferredWidth: fixedParameterEditor.headerItem.columnWidths[1]
                    // properties to forward to the editor:
                    property var parameterModel: __parsedEditEventData.value[index];
                    property int modelIndex: index;

                    sourceComponent: {
                        switch(__parsedEditEventData.value[index].type) {
                            case "float": return parameterEditorFloat;
                            case "integer": return parameterEditorInteger;
                            case "string": return parameterEditorString;
                            case "table": return parameterEditorTable;
                        }
                        return null;
                    }
                }
            }
        }
        delegate: fixedParameterDelegate
    }

    // +++
    // + MatrixParameter
    // +++
    GridLayout {
        id: matrixParameterEditor
        anchors.fill: parent
        visible: __isMatrixParameter
        enabled: __isMatrixParameter
        columns: (__isMatrixParameter) ? __parsedEditEventData.value.width : 0
        rows: (__isMatrixParameter) ? (__parsedEditEventData.value.height + 1) : 0

        Repeater {
            model: (__isMatrixParameter) ? __parsedEditEventData.value.values.length : null
            TextField {
                Layout.fillHeight: false
                Layout.fillWidth: true
                selectByMouse: true
                text: __parsedEditEventData.value.values[index]
                onEditingFinished: {
                    __applyChange()
                }
                onTextEdited: {
                    __parsedEditEventData.value.values[index] = text;
                }
            }
        }
        Rectangle {
            Layout.columnSpan: (parent.columns <= 0) ? 1 : parent.columns
            Layout.fillHeight: true
        }
    }
}
