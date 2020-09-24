import QtQuick 2.0
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQml.Models 2.15

import SensorReadout 1.0
import "components"

Window {
    id: deviceWindow
    title: qsTr("Device Functions")
    SystemPalette { id: systemPalette; colorGroup: SystemPalette.Active }
    color: systemPalette.window

    property var settings: null

    AdbController {
        id: adbController
        settings: backend.settings
        device: deviceChooser.currentValue
    }
    ListModel {
        id: deviceModel
    }

    onVisibleChanged: {
        if(visible) {
            deviceModel.clear();
            var deviceList = adbController.deviceList();
            deviceList.forEach(function(device){
                deviceModel.append({
                    value: device,
                    text: device
                });
            });
        }
        __updateFileListing();
    }

    function __updateFileListing() {
        if(deviceModel.count > 0) {
            var fileList = adbController.listFiles("/storage/emulated/0/Android/data/de.fhws.indoor.sensorreadout/files/Documents/sensorOutFiles/*.csv");
            recordingListView.model = fileList;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 5
        RowLayout {
            id: deviceChooserRow
            Layout.fillWidth: true

            Label {
                text: "Device: "
            }
            ComboBox {
                enabled: deviceModel.count > 0
                id: deviceChooser
                model: deviceModel
                textRole: "text"
                valueRole: "value"
                currentIndex: 0
                onCurrentIndexChanged: {
                    __updateFileListing();
                }
            }
            Text {
                visible: deviceModel.count === 0
                text: "No device"
                color: "red"
            }
        }
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: systemPalette.text
        }

        ListView {
            id: recordingListView
            Layout.fillWidth: true
            Layout.fillHeight: true

        }

        LayoutStretcher {}
    }
}

/*##^##
Designer {
    D{i:0;autoSize:true;height:480;width:640}
}
##^##*/
