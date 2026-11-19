import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
    id: root

    property var activeMenu: null

    width: 18
    height: 36

    Image {
        width: 17
        height: 17
        anchors.centerIn: parent
        source: "icons/caret-up.svg"
        sourceSize.width: 60
        sourceSize.height: 60
        fillMode: Image.PreserveAspectFit
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor

        onClicked: dropdown.visible = !dropdown.visible
    }

    Timer {
        id: focusArm
        interval: 120
        repeat: false

        onTriggered: {
            if (dropdown.visible) {
                trayFocus.active = true
                console.log("[tray] delayed focus request; active:", trayFocus.active)
            }
        }
    }

    HyprlandFocusGrab {
        id: trayFocus

        onActiveChanged: console.log("[tray] focus active:", active)

        windows: root.activeMenu
            ? [dropdown, root.activeMenu]
            : [dropdown]

        onCleared: {
            console.log("[tray] focus cleared")
            if (root.activeMenu)
                root.activeMenu.visible = false
            dropdown.visible = false
        }
    }

    PopupWindow {
        id: dropdown

        visible: false
        grabFocus: false

        onVisibleChanged: {
            if (visible) {
                focusArm.restart()
            } else {
                focusArm.stop()
                trayFocus.active = false
            }

            if (!visible && root.activeMenu) {
                root.activeMenu.visible = false
                root.activeMenu = null
            }
        }

        anchor.item: root
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left
        anchor.margins.bottom: -4

        implicitWidth: Math.max(34, trayContent.implicitWidth + 16)
        implicitHeight: Math.max(34, trayContent.implicitHeight + 16)
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.50)
            border.width: 1
            border.color: "#333333"
            radius: 0

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onClicked: {
                    if (root.activeMenu) {
                        const menu = root.activeMenu
                        root.activeMenu = null
                        menu.visible = false
                    }
                }
            }

            Tray {
                id: trayContent
                anchors.centerIn: parent

                onContextMenuOpened: (menuWindow) => {
                    const previousMenu = root.activeMenu
                    root.activeMenu = menuWindow

                    // Rebuild the focus grab with the newly opened menu.
                    trayFocus.active = false
                    focusArm.restart()

                    // Close the previous menu before continuing.
                    if (previousMenu && previousMenu !== menuWindow)
                        previousMenu.visible = false
                    console.log("[tray] context menu opened; focus active:", trayFocus.active)
                }

                onContextMenuClosed: (menuWindow) => {
                    if (root.activeMenu === menuWindow) {
                        root.activeMenu = null
                        dropdown.visible = false
                    }
                }
            }
        }

        Shortcut {
            sequence: "Escape"
            context: Qt.ApplicationShortcut
            enabled: dropdown.visible
            onActivated: dropdown.visible = false
        }
    }
}
