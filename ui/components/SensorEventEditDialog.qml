import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12

import SensorReadout 1.0

Dialog {
    id: editingDialog
    SystemPalette { id: systemPalette; colorGroup: SystemPalette.Active }
    /* edit state */
    property var __editEvent: null
    property var __saveFn: null
    property var __cancelFn: null

    function openEdit(event, saveFn, cancelFn) {
        __editEvent = event;
        __saveFn = saveFn;
        __cancelFn = cancelFn;
        open();
    }
    function __save() {
        __editEvent.dataRaw = eventDataEditor.sensorEvent.dataRaw;
        __saveFn(__editEvent);
        __resetAndClose();
    }
    function __cancel() {
        if(__cancelFn) { __cancelFn(); }
        __resetAndClose();
    }
    function __resetAndClose() {
        __editEvent = null;
        __saveFn = null;
        __cancelFn = null;
        close();
    }

    GridLayout {
        anchors.fill: parent
        columns: 2
        rowSpacing: 10
        columnSpacing: 5


        Label { text: "EventType: "; font.bold: true }
        SensorTypeComboBox {
            Layout.fillWidth: true
            currentSensorType: (__editEvent) ? __editEvent.type : SensorType.UNKNOWN
            onActivated: {
                var newEvent = editingDialog.__editEvent;
                newEvent.type = currentSensorType;
                editingDialog.__editEvent = newEvent;
            }
        }

        Label { text: "Timestamp: "; font.bold: true }
        TextField {
            Layout.fillWidth: true;
            selectByMouse: true
            text: (__editEvent) ? __editEvent.timestamp : ""
            onTextEdited: __editEvent.timestamp = parseInt(text)
        }

        Label { text: "Parameters:"; Layout.columnSpan: 2; font.bold: true }
        SensorEventDataEditor {
            id: eventDataEditor
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.columnSpan: 2
            sensorEvent: __editEvent
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
                onClicked: __cancel()
            }
        }
    }
}

/*##^##
Designer {
    D{i:0;autoSize:true;height:480;width:640}
}
##^##*/
