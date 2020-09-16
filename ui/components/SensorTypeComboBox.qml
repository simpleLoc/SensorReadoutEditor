import QtQuick 2.15
import QtQml.Models 2.15
import QtQuick.Controls 2.15

import SensorReadout 1.0
import SortFilterProxyModel 0.2

ComboBox {
    id: control
    valueRole: "value"
    textRole: "text"
    model: ListModel {
        id: sensorTypeModel
    }

    property int currentSensorType: SensorType.UNKNOWN
    onCurrentSensorTypeChanged: {
        var newIdx = indexOfValue(currentSensorType);
        // stop ring-binding
        if(currentIndex !== newIdx) { currentIndex = newIdx; }
    }
    onActivated: {
        currentSensorType = currentValue;
    }

    Component.onCompleted: {
        // fill model
        SensorType.values.forEach(function(value) {
            sensorTypeModel.append(
                { value: value, text: SensorType.toName(value) }
            );
        });
        currentIndex = indexOfValue(currentSensorType);
    }

    popup: Popup {
        y: control.height - 1
        width: control.width
        height: implicitContentHeight
        padding: 1

        function selectAndClose(sensorType) {
            control.currentSensorType = sensorType;
            filterTxt.text = "";
            control.activated(control.currentIndex);
            popup.close();
        }

        onOpened: {
            filterTxt.forceActiveFocus();
            itemList.currentIndex = -1;
        }

        SortFilterProxyModel {
            id: filteredSensorTypeModel
            sourceModel: sensorTypeModel
            filters: RegExpFilter {
                roleName: "text"
                pattern: filterTxt.text
                caseSensitivity: Qt.CaseInsensitive
            }
        }

        contentItem: Column {
            TextField {
                id: filterTxt
                selectByMouse: true
                width: parent.width
                onAccepted: {
                    if(filteredSensorTypeModel.rowCount() === 1) {
                        popup.selectAndClose(filteredSensorTypeModel.get(0).value);
                    }
                }
                Keys.onPressed: {
                    if(event.key === Qt.Key_Down) {
                        itemList.forceActiveFocus();
                        itemList.currentIndex = 0;
                    }
                }
            }
            ListView {
                id: itemList
                width: parent.width
                implicitHeight: itemList.contentHeight
                clip: true
                model: control.popup.visible ? filteredSensorTypeModel : null
                ScrollIndicator.vertical: ScrollIndicator { }
                delegate: Rectangle {
                    implicitHeight: popupListItemLayout.implicitHeight
                    width: itemList.width

                    MouseArea {
                        id: popupListItemMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            popup.selectAndClose(model.value);
                        }
                    }
                    Keys.onPressed: {
                        if(event.key === Qt.Key_Up && itemList.currentIndex === 0) {
                            itemList.currentIndex = -1;
                            filterTxt.forceActiveFocus();
                        } else if(event.key === Qt.Key_Return && itemList.currentIndex !== -1) {
                            popup.selectAndClose(model.value);
                        } else if(event.text !== "") {
                            filterTxt.text += event.text;
                            filterTxt.forceActiveFocus();
                        }
                    }

                    color: (itemList.currentIndex == index) ? "lightsteelblue" : (popupListItemMouseArea.containsMouse ? "lightblue": "transparent")

                    Row {
                        id: popupListItemLayout
                        width: parent.width
                        padding: 4
                        Text {
                            text: model.text
                        }
                    }
                }
            }
        }
    }
}

/*##^##
Designer {
    D{i:0;autoSize:true;height:40;width:400}
}
##^##*/
