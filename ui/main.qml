import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.11
import QtQuick.Dialogs 1.3

import SensorReadout 1.0
import "components"

Window {
    id: root

    property bool hasChanges: false

    width: 640
    height: 480
    visible: true
    title: qsTr("SensorReadout Editor") + (hasChanges ? "*" : "")



    function insertNewEventAtIdx(index) {
        var timestamp = 0;
        if(index === -1) { // append
            index = backend.events.len();
        } else { // copy timestamp from event at index
            timestamp = backend.events.getEventAt(index);
        }
        console.assert(backend.events.insertEmptyEvent(index));
        var newEvent = backend.events.getEventAt(index).clone();
        newEvent.timestamp = timestamp;
        editingDialog.openEdit(newEvent,
            function(item) { // saveFn
                backend.events.setEventAt(index, item);
            },
            function() { //cancelFn
                backend.events.removeEvent(index);
            }
        );
        root.hasChanges = true;
    }

    function jumpToIdx(index) {
        eventList.positionViewAtIndex(index, ListView.Center);
        eventList.currentIndex = index;
    }

    function jumpToNextEventOfType(sensorType) {
        var startIdx = (eventList.currentIndex === -1) ? 0 : (eventList.currentIndex + 1);
        var nextIdx = backend.events.findNextOfType(startIdx, sensorType);
        if(nextIdx >= 0) {
            jumpToIdx(nextIdx);
        }
    }
    function jumpToPreviousEventOfType(sensorType) {
        if(eventList.currentIndex === -1) { return; }
        var nextIdx = backend.events.findPreviousOfType(eventList.currentIndex - 1, sensorType);
        if(nextIdx >= 0) {
            jumpToIdx(nextIdx);
        }
    }


    FileDialog {
        id: openFileDialog
        title: "Open a SensorReadout file"
        folder: shortcuts.home
        nameFilters: ["SensorReadout files (*.csv)"]
        onAccepted: {
            var path = fileUrl.toString();
            if(path.startsWith("file:///")) {
                path = path.substring(7);
            }
            backend.openFile(path);
        }
    }
    FileDialog {
        id: saveAsFileDialog
        title: "Save SensorReadout file"
        folder: shortcuts.home
        selectMultiple: false
        selectFolder: false
        selectExisting: false
        nameFilters: ["SensorReadout files (*.csv)"]
        onAccepted: {
            var path = fileUrl.toString();
            if(path.startsWith("file:///")) {
                path = path.substring(7);
            }
            if(backend.saveFile(path)) {
                root.hasChanges = false;
            }
        }
    }

    ToolBar {
        id: toolBar
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.top: root.top

        Row {
            ToolButton {
                id: openFileButton
                text: qsTr("Open")
                onClicked: {
                    openFileDialog.open();
                }
            }
            ToolButton {
                id: saveFileButton
                text: qsTr("Save") + (hasChanges ? "*" : "")
                onClicked: {
                    if(backend.saveFile()) {
                        root.hasChanges = false;
                    }
                }
            }
            ToolButton {
                id: saveAsFileButton
                text: qsTr("Save as")
                onClicked: {
                    saveAsFileDialog.open();
                }
            }
            ToolSeparator {}
            ToolButton {
                id: editMetadataButton
                text: qsTr("Edit Metadata")
                onClicked: {
                    var metadataIdx = backend.events.findNextOfType(0, SensorType.FileMetadata);
                    var eventWasNew = (metadataIdx === -1);
                    if(eventWasNew) {
                        metadataIdx = 0; // insert metadata event at position 0
                        console.assert(backend.events.insertEmptyEvent(metadataIdx));
                        var newEvent = backend.events.getEventAt(metadataIdx).clone();
                        newEvent.timestamp = 0;
                        newEvent.type = SensorType.FileMetadata;
                        backend.events.setEventAt(metadataIdx, newEvent);
                    }
                    var metadataEvent = backend.events.getEventAt(metadataIdx);
                    editingDialog.openEdit(metadataEvent.clone(),
                        function(item) { // saveFn
                            backend.events.setEventAt(metadataIdx, item);
                        },
                        function() { //cancelFn
                            if(eventWasNew) { // we added the metadata event -> delete it again
                                backend.events.removeEvent(metadataIdx);
                            }
                        }
                    );
                    root.hasChanges = true;
                }
            }
        }
    }

    Rectangle {
        id: sideBarComponent
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.top: toolBar.bottom
        anchors.topMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        width: 250

        ColumnLayout {
            anchors.fill: parent
            GroupBox {
                Layout.fillWidth: true
                title: qsTr("Jump to next...")
                ColumnLayout {
                    width: parent.width
                    SensorTypeComboBox {
                        id: jumpToSensorTypeCombo
                        Layout.fillWidth: true
                        currentSensorType: SensorType.Accelerometer
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Button {
                            text: "Prev"
                            onClicked: jumpToPreviousEventOfType(jumpToSensorTypeCombo.currentSensorType)
                        }
                        Rectangle { Layout.fillWidth: true; Layout.fillHeight: true; }
                        Button {
                            text: "Next"
                            onClicked: jumpToNextEventOfType(jumpToSensorTypeCombo.currentSensorType)
                        }
                    }
                }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
    Rectangle {
        id: eventListComponent
        anchors.left: sideBarComponent.right
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.top: toolBar.bottom
        anchors.topMargin: 0
        height: 1.0 * (parent.height - toolBar.height)

        ListView {
            id: eventList
            // positioning
            anchors.fill: parent
            // style
            clip: true
            reuseItems: true

            header: ListViewColumnHeader {
                height: 25
                width: parent.width
                z: 10
                columns: [
                    ListViewColumn { text: "EventType"; minWidth: 50; maxWidth: 175 },
                    ListViewColumn { text: "Timestamp"; minWidth: 100; maxWidth: 175 },
                    ListViewColumn { text: "Data" }
                ]
            }
            headerPositioning: ListView.OverlayHeader
            ScrollBar.vertical: ScrollBar {//FIXME: shown over header
                active: true
                z: 20
                minimumSize: 0.1
            }

            model: EventListModel {
                eventList: backend.events
            }
            Component {
                id: eventDelegate
                Rectangle {
                    height: eventContentLayout.height
                    width: eventContentLayout.width
                    z: 5
                    color: {
                        if(eventItemMouseArea.containsPress) { return "lightsteelblue"; }
                        if(eventList.currentIndex == index) { return "#8fbee6"; }
                        return (eventItemMouseArea.containsMouse) ? "lightblue" : "white";
                    }
                    Row {
                        id: eventContentLayout
                        RowLayout {
                            width: eventList.headerItem.columnWidths[0]
                            clip: true
                            Text {
                                text: model.type
                                topPadding: 4
                                bottomPadding: 4
                                leftPadding: 4
                                rightPadding: 2
                            }
                            Text {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignRight
                                text: "(" + SensorType.toName(model.type) + ")"
                                elide: Text.ElideLeft
                                color: "gray"
                            }
                        }
                        RowLayout {
                            width: eventList.headerItem.columnWidths[1]
                            clip: true
                            Text {
                                text: model.timestamp
                                topPadding: 4
                                bottomPadding: 4
                                leftPadding: 4
                                rightPadding: 2
                            }
                            Text {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignRight
                                text: "(" + toTimeString(model.timestamp) + ")"
                                elide: Text.ElideRight
                                color: "gray"
                                function padDigits(number, digits) {
                                    return Array(Math.max(digits - String(number).length + 1, 0)).join(0) + number;
                                }
                                function toTimeString(timestamp) {
                                    var minutes = timestamp / 60000000000;
                                    var fullMinutes = Math.trunc(minutes);
                                    var seconds = (minutes - fullMinutes) * 60;
                                    var fullSeconds = Math.trunc(seconds);
                                    var fullMilliseconds = Math.trunc((seconds - fullSeconds) * 1000);
                                    return padDigits(fullMinutes, 2) + ":" + padDigits(fullSeconds, 2) + "." + padDigits(fullMilliseconds, 4);
                                }
                            }
                        }
                        Text {
                            text: model.dataRaw;
                            width: eventList.headerItem.columnWidths[2]
                            padding: 4
                        }
                    }

                    Menu {
                        id: eventContextMenu

                        MenuItem {
                            text: "Jump to next (same type)"
                            onTriggered: {
                                eventList.currentIndex = index;
                                jumpToNextEventOfType(model.type);
                            }
                        }
                        MenuSeparator {}
                        MenuItem {
                            text: "Remove"
                            onTriggered: {
                                root.hasChanges = true;
                                backend.events.removeEvent(index);
                            }
                        }
                        MenuItem {
                            text: "New Here"
                            onTriggered: root.insertNewEventAtIdx(index)
                        }
                    }

                    MouseArea {
                        id: eventItemMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: {
                            if(mouse.button & Qt.LeftButton) {
                                eventList.currentIndex = index;
                            } else if(mouse.button & Qt.RightButton) {
                                eventContextMenu.popup();
                            }
                        }

                        onDoubleClicked: {
                            editingDialog.openEdit(model.clone(), function(item) {
                                root.hasChanges = true;
                                backend.events.setEventAt(index, item);
                            });
                        }
                    }
                }
            }
            delegate: eventDelegate
        }
    }
    Rectangle { //future
        id: dataPreviewComponent
        anchors.left: sideBarComponent.right
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.top: eventListComponent.bottom
        anchors.topMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
    }


    SensorEventEditDialog {
        id: editingDialog
        width: Math.max(parent.width / 2, 350)
        height: Math.max(parent.height / 2, 350)
        anchors.centerIn: parent
        modal: true
    }


    MessageDialog {
        id: errorDialog
        title: "An error occured"
    }

    // init
    Component.onCompleted: {
        backend.onError.connect(function(errorMessage) {
            errorDialog.text = errorMessage;
            errorDialog.open();
        });
    }

}
