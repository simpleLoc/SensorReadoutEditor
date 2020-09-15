import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12

import SensorReadout 1.0
import "SensorEvent.js" as SensorEvent

Item {
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
            width: fixedParameterEditor.width
            columns: [
                ListViewColumn { text: "Parameter"; fixedWidth: 125 },
                ListViewColumn { text: "Value" }
            ]
        }

        model: (__isFixedParameter) ? __parsedEditEventData.value : []
        Component {
            id: fixedParameterDelegate
            Rectangle {
                height: eventContentLayout.height
                width: eventContentLayout.width
                Row {
                    id: eventContentLayout
                    Text {
                        text: modelData.name
                        width: fixedParameterEditor.headerItem.columnWidths[0]
                        padding: 4
                    }
                    TextField {
                        selectByMouse: true
                        width: fixedParameterEditor.headerItem.columnWidths[1]
                        padding: 4
                        text: modelData.value
                        onEditingFinished: __applyChange()
                        onTextEdited: {
                            __parsedEditEventData.value[index].value = text;
                        }
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
