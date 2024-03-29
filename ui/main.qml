import QtQuick 2.15
import QtQuick.Dialogs 1.2
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.11

import SortFilterProxyModel 0.2
import SensorReadout 1.0
import "components"
import "Helper.js" as Helper

Window {
    id: root

    SystemPalette { id: systemPalette; colorGroup: SystemPalette.Active }
    property bool hasChanges: false
    property string titleFilePath: ""

    width: 900
    height: 550
    visible: true
    title: qsTr("SensorReadout Editor") + (titleFilePath != "" ? " - "+titleFilePath : "") + (hasChanges ? " *" : "")
    color: systemPalette.window


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
                backend.events.setEventAt(backendViewModel.mapToSource(index), item);
            },
            function() { //cancelFn
                backend.events.removeEvent(backendViewModel.mapToSource(index));
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

    function openFile(url) {
        var path = url
        if(path.startsWith("file:///")) {
            path = path.substring(7);
        }
        backend.openFile(path);
        titleFilePath = path;
        hasChanges = false;
    }

    FileDialog {
        id: openFileDialog
        title: "Open a SensorReadout file"
        folder: shortcuts.home
        nameFilters: ["SensorReadout files (*.csv)"]
        onAccepted: openFile(fileUrl.toString())
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

        RowLayout {
            anchors.fill: parent
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
            ToolSeparator {}
            ToolButton {
                id: deviceDownloadButton
                enabled: backend.settings.isConfigured
                text: qsTr("Device download")
                onClicked: deviceWindow.show()
            }
            LayoutStretcher {}
            ToolButton {
                id: configureButton
                text: qsTr("Configuration")
                onClicked: {
                    configurationDialog.open();
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
        color: systemPalette.window

        ColumnLayout {
            anchors.fill: parent
            GroupBox {
                Layout.fillWidth: true
                Layout.topMargin: 7
                title: qsTr("View")
                ColumnLayout {
                    width: parent.width
                    TextField {
                        Layout.fillWidth: true
                        id: eventFilterTxt
                        placeholderText: qsTr("Event Filter")
                        color: systemPalette.text
                        selectByMouse: true
                    }
                    TextField {
                        Layout.fillWidth: true
                        id: timestampFilterTxt
                        placeholderText: qsTr("Timestamp Filter")
                        color: systemPalette.text
                        selectByMouse: true
                    }
                }
            }
            ToolSeparator {
                Layout.fillWidth: true
                orientation: Qt.Horizontal
            }
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
                        LayoutStretcher{}
                        Button {
                            text: "Next"
                            onClicked: jumpToNextEventOfType(jumpToSensorTypeCombo.currentSensorType)
                        }
                    }
                }
            }
            GroupBox {
                Layout.fillWidth: true
                title: qsTr("File Fixes")

                ColumnLayout {
                    anchors.fill: parent
                    Button {
                        id: enforceSortButton
                        Layout.fillWidth: true
                        text: "Sort"
                        hoverEnabled: true
                        ToolTip.visible: hovered
                        ToolTip.delay: 750
                        ToolTip.text: "Sort all events in ascending timestamp order."
                        onClicked: {
                            hasChanges = true;
                            backend.events.sort();
                        }
                    }
                    Button {
                        id: fixGtNumberingButton
                        Layout.fillWidth: true
                        text: "GT-Point Numbering"
                        hoverEnabled: true
                        ToolTip.visible: hovered
                        ToolTip.delay: 750
                        ToolTip.text: "Re-Assign correctly ordered (ascending) IDs to all GroundTruth events, starting at 0."
                        onClicked: {
                            hasChanges = true;
                            backend.events.fixGroundTruthNumbering();
                        }
                    }
                }
            }

            LayoutStretcher{}
            Rectangle {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.maximumHeight: 200
                border.width: 2
                border.color: (openFileDropArea.containsDrag) ? "lightblue" : "#555555"
                color: "transparent"
                radius: 4
                DropArea {
                    id: openFileDropArea
                    anchors.fill: parent
                    Icon {
                        anchors.fill: parent
                        anchors.margins: 0.25 * Math.min(openFileDropArea.width, openFileDropArea.height)
                        iconSource: "qrc:/ui/drop.svg"
                        iconColor: "white"
                    }
                    onEntered: {
                        if(drag.hasUrls) {
                            drag.accept();
                        }
                    }
                    onDropped: {
                        openFile(drop.urls[0]);
                    }
                }
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
        color: systemPalette.window

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
                    ListViewColumn { text: "EventType"; minWidth: 50; maxWidth: 215 },
                    ListViewColumn { text: "Timestamp"; minWidth: 100; maxWidth: 215 },
                    ListViewColumn { text: "Data" }
                ]
            }
            headerPositioning: ListView.OverlayHeader
            ScrollBar.vertical: ScrollBar {//FIXME: shown over header
                active: true
                z: 20
                minimumSize: 0.1
            }

            model: SortFilterProxyModel {
                id: backendViewModel
                sourceModel: EventListModel {
                    eventList: backend.events
                }
                proxyRoles: [
                    ExpressionRole {
                        name: "timestampStr"
                        expression: model.timestamp.toLocaleString('fullwide', { useGrouping: false })
                    }
                ]
                filters: [
                    ExpressionFilter {
                        expression: {
                            let filterStr = eventFilterTxt.displayText.toLowerCase();
                            if(!filterStr) { return true; }
                            return (model.sensorType.toString().indexOf(filterStr) !== -1) || (model.sensorTypeName.toLowerCase().indexOf(filterStr) !== -1);
                        }
                    },
                    ExpressionFilter {
                        expression: {
                            let filterStr = timestampFilterTxt.displayText;
                            if(!filterStr) { return true; }
                            return model.timestampStr.indexOf(filterStr) !== -1;
                        }
                    }

                ]
            }
            Component {
                id: eventDelegate
                Rectangle {
                    height: eventContentLayout.height
                    width: eventContentLayout.width
                    z: 5
                    property bool isHighlighted: (eventItemMouseArea.containsPress || eventList.currentIndex === index || eventItemMouseArea.containsMouse)
                    color: (isHighlighted) ? systemPalette.highlight : systemPalette.base

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
                                color: (isHighlighted) ? systemPalette.highlightedText : systemPalette.text
                            }
                            Text {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignRight
                                text: "(" + model.typeName + ")"
                                elide: Text.ElideLeft
                                color: systemPalette.light
                            }
                        }
                        RowLayout {
                            width: eventList.headerItem.columnWidths[1]
                            clip: true
                            Text {
                                text: model.timestamp.toLocaleString('fullwide', { useGrouping: false })
                                topPadding: 4
                                bottomPadding: 4
                                leftPadding: 4
                                rightPadding: 2
                                color: (isHighlighted) ? systemPalette.highlightedText : systemPalette.text
                            }
                            Text {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignRight
                                text: "(" + Helper.nsTimestampToTimeString(model.timestamp) + ")"
                                elide: Text.ElideRight
                                color: systemPalette.light
                            }
                        }
                        Text {
                            text: model.dataRaw;
                            width: eventList.headerItem.columnWidths[2]
                            padding: 4
                            color: (isHighlighted) ? systemPalette.highlightedText : systemPalette.text
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
                                // we have a SortFilterProxyModel inbetween, so we have to translate indices!
                                backend.events.setEventAt(backendViewModel.mapToSource(index), item);
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


    DeviceWindow {
        id: deviceWindow
        settings: backend.settings
        x: root.x
        y: root.y
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

    ConfigurationDialog {
        id: configurationDialog
        width: 0.75 * parent.width
        height: 0.75 * parent.height
        anchors.centerIn: parent
        settings: backend.settings
    }

    // init
    Component.onCompleted: {
        backend.onError.connect(function(errorMessage) {
            errorDialog.text = errorMessage;
            errorDialog.open();
        });
        if(!backend.settings.isConfigured) {
            configurationDialog.open();
        }
    }

}
