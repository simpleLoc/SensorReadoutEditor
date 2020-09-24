import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: columnHeader
    SystemPalette { id: systemPalette; colorGroup: SystemPalette.Active }

    property list<ListViewColumn> columns
    readonly property int columnCnt: columns.length
    property var columnWidths: []

    function performLayout() {
        var idx, column;
        var newColumnWidths = [];
        var relativeSize = 0;
        var fixedSize = 0;
        var expandingWidgetCnt = 0;
        // first pass - init & fixed / relative width
        for(idx = 0; idx < columns.length; ++idx) {
            column = columns[idx];
            newColumnWidths.push(-1);
            if(column.fixedWidth !== -1) {
                newColumnWidths[idx] = column.fixedWidth;
                fixedSize += newColumnWidths[idx];
            } else if(column.relativeWidth >= -0.5) {
                newColumnWidths[idx] = (columnHeader.width * column.relativeWidth);
                relativeSize += newColumnWidths[idx];
            } else {
                expandingWidgetCnt += 1;
            }
        }
        var remainingWidth = Math.max(columnHeader.width - (relativeSize + fixedSize), 0);

        // second pass - expanding widgets with size constraints
        for(var r = 0; r < expandingWidgetCnt; ++r) {
            for(idx = 0; idx < columns.length; ++idx) {
                column = columns[idx];
                if(newColumnWidths[idx] === -1) { // column whose size is tbd.
                    var widgetSize = remainingWidth / expandingWidgetCnt;
                    if(column.minWidth !== -1 && column.minWidth > widgetSize) {
                        newColumnWidths[idx] = column.minWidth;
                        remainingWidth -= newColumnWidths[idx];
                        expandingWidgetCnt -= 1;
                    } else if(column.maxWidth !== -1 && column.maxWidth < widgetSize) {
                        newColumnWidths[idx] = column.maxWidth;
                        remainingWidth -= newColumnWidths[idx];
                        expandingWidgetCnt -= 1;
                    }
                }
            }
        }

        // third pass - expanding widgets without size constraints
        for(idx = 0; idx < columns.length; ++idx) {
            if(newColumnWidths[idx] === -1) { // column whose size is tbd.
                newColumnWidths[idx] = remainingWidth / expandingWidgetCnt;
            }
        }

        columnHeader.columnWidths = newColumnWidths;
    }

    onWidthChanged: performLayout()
    Component.onCompleted: performLayout()

    Row {
        anchors.fill: parent
        Repeater {
            id: columnRenderer
            model: columns

            Rectangle {
                id: eventTypeColumnHeader
                height: parent.height
                width: columnHeader.columnWidths[index]
                color: systemPalette.mid
                Rectangle {
                    id: columnSeparator
                    visible: (index > 0)
                    height: parent.height
                    width: 1
                    anchors.left: parent.left
                    color: systemPalette.light
                }
                Text {
                    text: modelData.text
                    color: systemPalette.text
                    padding: 5
                    anchors.left: columnSeparator.right
                }
            }
        }
    }
}
