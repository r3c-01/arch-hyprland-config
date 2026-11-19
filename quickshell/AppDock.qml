
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: dock
    signal closeRequested()

    focusable: false
    required property var targetScreen
    property bool dockOpen: false

    screen: targetScreen
    visible: dockOpen

    WlrLayershell.namespace: "quickshell-dock"

    anchors {
        bottom: true
    }

    margins.bottom: 18

    implicitWidth: dockRow.implicitWidth + 28
    implicitHeight: 64

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.50)
    radius: 14
    border.width: 0
    }

    Row {
        id: dockRow
        anchors.centerIn: parent
        spacing: 12

        Repeater {
            model: [
                { name: "Terminal", icon: "utilities-terminal", command: "kitty" },
                { name: "Files", icon: "system-file-manager", command: "thunar" },
                { name: "Browser", icon: "firefox", command: "firefox" },
                { name: "Code", icon: "visual-studio-code", command: "code" },
                { name: "Music", icon: "spotify", command: "spotify" }
            ]

            delegate: Item {
                required property var modelData

                width: 44
                height: 48

                Rectangle {
                    anchors.centerIn: parent
                    width: 44
                    height: 44
                    radius: 10
                    color: mouse.containsMouse ? "#24ffffff" : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: 140 }
                    }
                }

                Image {
                    anchors.centerIn: parent
                    width: 32
                    height: 32
                    source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        Quickshell.execDetached([modelData.command])
                        dock.closeRequested()
                    }
                }
            }
        }
    }
}
