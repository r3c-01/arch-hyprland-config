import QtQuick
import Quickshell

Item {
    id: root

    signal clicked()
    implicitWidth: content.implicitWidth
    implicitHeight: 42

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 12

        Text {
            anchors.verticalCenter: parent.verticalCenter

            text: Qt.formatDateTime(clock.date, "ddd, MMM d")
            color: "#FFFFFF"

            font.family: "Tintoretto"
            font.weight: Font.Normal
            font.pixelSize: 22
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter

            text: Qt.formatDateTime(clock.date, "h:mm AP")
            color: "#FFFFFF"

            font.family: "Tintoretto"
            font.weight: Font.Normal
            font.pixelSize: 22
        }
    }
}
