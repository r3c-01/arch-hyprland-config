import QtQuick
import QtQuick.Controls
Button {
    id: control
    implicitWidth: 82
    implicitHeight: 32
    hoverEnabled: true
    padding: 8
    property bool selected: false
    contentItem: Text {
        text: control.text
        color: control.enabled ? "#f0f0f2" : "#a0a5af"
        font.pixelSize: 11
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: Rectangle {
        radius: 0
        color: control.down ? "#505058" : control.hovered || control.selected ? "#3b3b3d" : "#303034"
        border.width: control.visualFocus ? 2 : 1
        border.color: control.visualFocus ? "#c8cdd4" : control.selected ? "#66c8cdd4" : "#33c8cdd4"
    }
}
