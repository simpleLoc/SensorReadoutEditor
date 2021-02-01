import QtQuick 2.0
import QtQuick.Controls 2.0

Item {
    id: control

    property alias iconName: inner.icon.name
    property alias iconColor: inner.icon.color
    property alias iconSource: inner.icon.source
    property alias padding: inner.padding

    signal clicked()

    ItemDelegate {
        id: inner
        anchors.fill: parent
        enabled: control.enabled
        implicitHeight: 32
        implicitWidth: 32
        icon.width: Math.min(width, height)
        icon.height: Math.min(width, height)
        display: AbstractButton.IconOnly
        padding: 2
        onClicked: control.clicked()
        background: null
    }
}
