import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.11
import Qt.labs.qmlmodels 1.0

import SensorReadout 1.0
import "components"

Window {
    id: root

    property bool hasChanges: false

    width: 640
    height: 480
    visible: true
    title: qsTr("SensorReadout Editor") + (hasChanges ? "*" : "")

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
                        if(eventItemMouseArea.containsPress) { return "#8fbee6"; }
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

                    MouseArea {
                        id: eventItemMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onDoubleClicked: {
                            editingDialog.openEdit(model.clone(), function(item) {
                                backend.events.setEventAt(index, item);
                                hasChanges = true;
                            });
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


    SensorEventEditDialog {
        id: editingDialog
        width: Math.max(parent.width / 2, 350)
        height: Math.max(parent.height / 2, 350)
        anchors.centerIn: parent
        modal: true
    }


    // init
    Component.onCompleted: {
        backend.onError.connect(function(errorMessage) {
            console.log(errorMessage);
        });
    }

}
