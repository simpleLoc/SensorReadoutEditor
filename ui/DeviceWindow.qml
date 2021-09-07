import QtQuick 2.0
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQml.Models 2.15
import QtQuick.Dialogs 1.3

import SensorReadout 1.0
import SortFilterProxyModel 0.2
import "components"
import "Helper.js" as Helper

Window {
    id: deviceWindow
    title: qsTr("Device Functions")
    SystemPalette { id: systemPalette; colorGroup: SystemPalette.Active }
    color: systemPalette.window
    width: 600
    height: 400

    property var settings: null

    AdbController {
        id: adbController
        settings: backend.settings
        device: deviceChooser.currentValue
    }
    ListModel {
        id: deviceModel
    }
    ListModel {
        id: deviceRecordingModel
    }

    onVisibleChanged: __updateDeviceListing()

    function __updateDeviceListing() {
        if(visible) {
            deviceModel.clear();
            var deviceList = adbController.deviceList();
            deviceList.forEach(function(device){
                deviceModel.append({
                    value: device,
                    text: device
                });
            });
            if(deviceModel.count == 1) {
                deviceChooser.currentIndex = 0;
            }
        }
        __updateFileListing();
    }

    function __updateFileListing() {
        if(deviceModel.count > 0) {
            var fileList1 = adbController.listFiles("/storage/emulated/0/Android/data/de.fhws.indoor.sensorreadout/files/Documents/sensorOutFiles/*.csv");
            var fileList2 = adbController.listFiles("/storage/*/Android/data/de.fhws.indoor.sensorreadout/files/Documents/sensorOutFiles/*.csv");
            var fileList = [].concat(fileList1).concat(fileList2);
            deviceRecordingModel.clear();
            for(var i in fileList) {
                deviceRecordingModel.append(fileList[i]);
            }
        }
    }

    function __deleteFile(filePath) {
        adbController.deleteFile(filePath);
        __updateFileListing();
    }

    function __downloadFile(filePath) {
        downloadSaveFolderDialog.open();
        let acceptHandler = function() {
            let folder = downloadSaveFolderDialog.folder.toString();
            if(!folder.startsWith("file://")) {
                throw new Error("Invalid Folder URL");
            }
            folder = folder.substr(7);

            adbController.downloadFile(folder, [filePath]);
            downloadSaveFolderDialog.accepted.disconnect(acceptHandler);
        };
        downloadSaveFolderDialog.accepted.connect(acceptHandler);
    }

    FileDialog {
        id: downloadSaveFolderDialog
        selectFolder: true
        selectExisting: true
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 5
        ToolBar {
            id: toolBar
            Layout.fillWidth: true

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
                ToolButton {
                    id: refreshDeviceListButton
                    icon.name: "view-refresh"
                    onClicked: __updateDeviceListing()
                }
            }
        }

        ListView {
            id: recordingListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: SortFilterProxyModel {
                id: sortedDeviceRecordingModel
                sourceModel: deviceRecordingModel
                sorters: StringSorter {
                    roleName: "fileDate"
                    numericMode: true
                    sortOrder: Qt.DescendingOrder
                }
            }
            currentIndex: -1
            delegate: Control {
                width: ListView.view.width
                padding: 5
                hoverEnabled: true

                property bool isHighlighted: (hovered || recordingListView.currentIndex == index)

                background: Rectangle {
                    color: (isHighlighted) ? systemPalette.highlight : systemPalette.base
                }
                contentItem: GridLayout {
                    id: inner
                    rowSpacing: 0
                    rows: 2
                    columns: 4
                    Label {
                        id: fileNameLbl
                        clip: true
                        Layout.row: 0
                        Layout.column: 0
                        font.bold: true
                        color: (isHighlighted) ? systemPalette.highlightedText : systemPalette.text
                        text: fileName
                    }
                    Label {
                        id: fileMetadataLbl
                        clip: true
                        Layout.row: 0
                        Layout.column: 1
                        Layout.fillWidth: true
                        color: (isHighlighted) ? systemPalette.highlightedText : systemPalette.text
                        text: "(" + fileDate + " | " + Helper.bytesToSizeString(fileSize) + ")"
                    }
                    Button {
                        id: downloadFileBtn
                        Layout.row: 0
                        Layout.rowSpan: 2
                        Layout.column: 2
                        Layout.preferredWidth: height
                        icon.name: "document-save"
                        onClicked: __downloadFile(filePath)
                    }
                    Button {
                        id: deleteFileBtn
                        Layout.row: 0
                        Layout.rowSpan: 2
                        Layout.column: 3
                        Layout.preferredWidth: height
                        icon.name: "delete"
                        onClicked: __deleteFile(filePath)
                    }
                    Label {
                        id: filePathLbl
                        Layout.row: 1
                        Layout.column: 0
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        color: (isHighlighted) ? systemPalette.highlightedText : systemPalette.text
                        elide: Text.ElideLeft
                        text: filePath
                    }
                }
            }
        }
    }
}


