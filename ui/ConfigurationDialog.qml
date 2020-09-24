import QtQuick 2.0
import QtQuick.Dialogs 1.2
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12

import "components"

Dialog {
    id: configurationDialog
    SystemPalette { id: systemPalette; colorGroup: SystemPalette.Active }

    property var settings: null

    modal: true
    standardButtons: Dialog.Ok

    FileDialog {
        id: adbExecutableDialog
        onAccepted: {
            var path = fileUrl.toString().replace(/^(file:\/{2})/,"");
            adbExecutableText.text = path;
        }
    }

    GridLayout {
        anchors.fill: parent
        columns: 2

        Text {
            font.bold: true
            color: systemPalette.text
            text: "ADB Executable:"
        }
        RowLayout {
            Layout.fillWidth: true
            TextField {
                id: adbExecutableText
                selectByMouse: true
                Layout.fillWidth: true
                text: settings.adbExecutable
            }
            Button {
                text: "Open"
                onClicked: adbExecutableDialog.open()
            }
        }

        LayoutStretcher {}
        LayoutStretcher {}
    }

    onAccepted: {
        settings.adbExecutable = adbExecutableText.text;
    }
}



/*##^##
Designer {
    D{i:0;autoSize:true;height:480;width:640}
}
##^##*/
