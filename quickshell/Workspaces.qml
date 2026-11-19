import QtQuick
import Quickshell.Hyprland

Item {
    id: root
    required property string monitorName

    implicitWidth: workspaceRow.implicitWidth + 32
    implicitHeight: 32

    Row {
        id: workspaceRow
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 18

        Repeater {
            model: Hyprland.workspaces

            delegate: Item {
                id: workspaceItem
                required property HyprlandWorkspace modelData
                readonly property bool shouldShow: modelData.id > 0 &&
                    (modelData.active || modelData.toplevels.values.length > 0)
                visible: shouldShow
                implicitWidth: number.implicitWidth + 16
                implicitHeight: 32

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: 27
                    radius: 0
                    color: "#12ffffff"
                    opacity: workspaceItem.modelData.focused ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 140 } }
                }

                Text {
                    id: number
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -2
                    text: {
                                const numerals = ["I", "II", "III", "IV", "V",
                                                "VI", "VII", "VIII", "IX", "X"];
                                return numerals[workspaceItem.modelData.id - 1]
                                    ?? String(workspaceItem.modelData.id);
                            }             
                    font.family: "Tintoretto"
                    font.pixelSize: 23
                    font.weight: Font.Normal
                    color: "#ffffff"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: workspaceItem.modelData.activate()
                }
            }
        }
    }
}
