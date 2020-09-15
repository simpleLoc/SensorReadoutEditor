import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12

import SensorReadout 1.0

Dialog {
    id: editingDialog
    /* edit state */
    readonly property var emptyEvent: { "type": 0, "timestamp": 0, "dataRaw": "" };
    property var __editEvent: emptyEvent
    property var __saveFn: null

    function openEdit(event, saveFn) {
        __editEvent = event;
        __saveFn = saveFn;
        eventDataEditor.sensorEvent = event;
        open();
    }
    function __save() {
        __editEvent.dataRaw = eventDataEditor.sensorEvent.dataRaw;
        __saveFn(__editEvent);
        __editEvent = emptyEvent;
        close();
    }

    GridLayout {
        anchors.fill: parent
        columns: 2
        rowSpacing: 10
        columnSpacing: 5


        Text { text: "EventType: "; font.bold: true }
        Text { Layout.fillWidth: true; text: editingDialog.__editEvent.type + " (" + SensorType.toName(editingDialog.__editEvent.type) + ")" }

        Text { text: "Timestamp: "; font.bold: true }
        TextField {
            Layout.fillWidth: true;
            text: editingDialog.__editEvent.timestamp
            onTextEdited: editingDialog.__editEvent.timestamp = parseInt(text)
        }

        Text { text: "Parameters:"; Layout.columnSpan: 2; font.bold: true }
        SensorEventDataEditor {
            id: eventDataEditor
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.columnSpan: 2
        }

        Row {
            layoutDirection: Qt.RightToLeft
            Layout.fillWidth: true
            Layout.columnSpan: 2
            spacing: 5
            Button {
                text: "Save"
                onClicked: __save()
            }
            Button {
                text: "Cancel"
                onClicked: {
                    __editEvent = emptyEvent;
                    close();
                }
            }
        }
    }
}

/*##^##
Designer {
    D{i:0;autoSize:true;height:480;width:640}
}
##^##*/
