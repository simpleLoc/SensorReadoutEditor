import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.11
import Qt.labs.qmlmodels 1.0

import EventList 1.0
import "components"

Window {
    id: root
    width: 640
    height: 480
    visible: true
    title: qsTr("SensorReadout Editor")

    ToolBar {
        id: toolBar
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.top: root.top

        ToolButton {
            id: openFileButton
            text: qsTr("Open File")
            onClicked: {
                backend.openFile("/home/seiji/Documents/seiji.li/FHWS/Forschungsstelle/Data/private/museum_many_small_stairs_0.csv");
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
        width: 200
        color: "#ffaa00"

    }
    Rectangle {
        id: eventListComponent
        anchors.left: sideBarComponent.right
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.top: toolBar.bottom
        anchors.topMargin: 0
        height: 0.5 * (parent.height - toolBar.height)
        color: "#005500"

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
                columns: [
                    ListViewColumn { text: "EventType"; minWidth: 50; maxWidth: 100 },
                    ListViewColumn { text: "Timestamp"; minWidth: 100; maxWidth: 150 },
                    ListViewColumn { text: "Data" }
                ]
            }

            model: EventListModel {
                eventList: backend.events
            }
            Component {
                id: eventDelegate
                Rectangle {
                    height: eventContentLayout.height
                    width: eventContentLayout.width
                    color: {
                        if(eventItemMouseArea.containsPress) { return "#8fbee6"; }
                        return (eventItemMouseArea.containsMouse) ? "lightblue" : "white";
                    }
                    Row {
                        id: eventContentLayout
                        Text {
                            text: model.type
                            width: eventList.headerItem.columnWidths[0]
                            padding: 4
                        }
                        Text {
                            text: model.timestamp
                            width: eventList.headerItem.columnWidths[1]
                            padding: 4
                        }
                        Text {
                            text: renderData(model.data);
                            width: eventList.headerItem.columnWidths[2]
                            padding: 4
                            function renderData(modelData) {
                                var properties = [];
                                for(var key in modelData) {
                                    properties.push(key + ": " + modelData[key].toFixed(10));
                                }
                                return properties.join("; ");
                            }
                        }
                    }

                    MouseArea {
                        id: eventItemMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onDoubleClicked: {
                            editingDialog.editEvent = model;
                            editingDialog.open();
                        }
                    }
                }
            }
            delegate: eventDelegate
        }
    }
    Rectangle {
        id: dataPreviewComponent
        anchors.left: sideBarComponent.right
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0
        anchors.top: eventListComponent.bottom
        anchors.topMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        color: "blue"
    }


    Dialog {
        id: editingDialog
        property var editEvent: null
        width: parent.width / 2
        height: parent.height / 2
        anchors.centerIn: parent
        modal: true

        GridLayout {
            x: 0
            y: 0
            width: editingDialog.width - 2 * editingDialog.padding
            height: editingDialog.height - 2 * editingDialog.padding
            columns: 2
            rowSpacing: 10
            columnSpacing: 5
            Text { text: "EventType: "; font.bold: true }
            Text { Layout.fillWidth: true; text: editingDialog.editEvent.type }

            Text { text: "Timestamp: "; font.bold: true }
            TextField {
                Layout.fillWidth: true;
                text: editingDialog.editEvent.timestamp
                onTextEdited: editingDialog.editEvent.timestamp = parseInt(text)
            }

            Text {
                text: "asdf"
            }
            Text {
                Layout.fillWidth: true;
                text: JSON.stringify(editingDialog.editEvent.data)
            }

            Item {//vertical fill
                Layout.fillHeight: true
            }
        }
    }


    // init
    Component.onCompleted: {
        backend.onError.connect(function(errorMessage) {
            console.log(errorMessage);
        });
        backend.openFile("/home/seiji/Documents/seiji.li/FHWS/Forschungsstelle/Data/private/museum_stairs_down_0.csv");
    }

}
