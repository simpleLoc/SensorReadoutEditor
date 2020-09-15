import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12

import SensorReadout 1.0

ComboBox {
    id: control
    valueRole: "value"
    textRole: "text"

    property int currentSensorType: SensorType.UNKNOWN
    onCurrentSensorTypeChanged: {
        var newIdx = indexOfValue(currentSensorType);
        // stop ring-binding
        if(currentIndex !== newIdx) { currentIndex = newIdx; }
    }

    model: SensorType.values.map(function(value) {
        return { value: value, text: SensorType.toName(value) }
    });
    onActivated: {
        currentSensorType = currentValue;
    }
}

/*##^##
Designer {
    D{i:0;autoSize:true;height:480;width:640}
}
##^##*/
