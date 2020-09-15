import QtQuick 2.15
import QtQuick.Controls 2.15

import SensorReadout 1.0
import "SensorEvent.js" as SensorEvent

Item {
    property var sensorEvent: { "type": 0, "timestamp": 0, "dataRaw": "" }
    property var __parsedEditEvent: new SensorEvent.SensorEvent(sensorEvent)
    property var __parsedEditEventData: __parsedEditEvent.get()

    property bool __isFixedParameter: (__parsedEditEvent && __parsedEditEventData.type === "fixedParameter")

    function __applyChange() {
        // trickle changes back up the parsing pipeline.
        __parsedEditEvent.set(__parsedEditEventData);
        __parsedEditEventData = __parsedEditEvent.get();
        sensorEvent.dataRaw = __parsedEditEvent.toRawData();
    }

    ListView {
        id: parameterEditor
        visible: __isFixedParameter
        enabled: __isFixedParameter
        anchors.fill: parent
        reuseItems: false

        header: ListViewColumnHeader {
            height: 25
            width: parameterEditor.width
            columns: [
                ListViewColumn { text: "Parameter"; fixedWidth: 100 },
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
                        width: parameterEditor.headerItem.columnWidths[0]
                        padding: 4
                    }
                    TextField {
                        text: modelData.value
                        width: parameterEditor.headerItem.columnWidths[1]
                        padding: 4
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


}
