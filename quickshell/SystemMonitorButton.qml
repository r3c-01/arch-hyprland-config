import Quickshell
import QtQuick

Item {
    id: root
    implicitWidth: 20
    implicitHeight: 30

    Image {
        anchors.centerIn: parent
        width: 20
        height: 20
        source: "icons/pulse.svg"
        sourceSize.width: 80
        sourceSize.height: 80
        fillMode: Image.PreserveAspectFit
        opacity: buttonMouse.containsMouse ? 1 : 0.90
    }
    MouseArea {
        id: buttonMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["sh", Quickshell.shellDir + "/scripts/open_system_monitor.sh"])
    }
}
