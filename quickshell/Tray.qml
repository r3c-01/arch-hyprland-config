import Quickshell
import QtQuick
import QtQuick.Effects
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Item {
    id: root

    signal contextMenuOpened(var menuWindow)
    signal contextMenuClosed(var menuWindow)

    implicitWidth: trayRow.implicitWidth
    implicitHeight: trayRow.implicitHeight

    Grid {
        id: trayRow

        anchors.centerIn: parent
        columns: Math.max(1, Math.min(3, trayRepeater.count))
        spacing: 4

        Repeater {
            id: trayRepeater
            model: SystemTray.items

            delegate: Item {
                id: trayEntry

                required property SystemTrayItem modelData

                width: 30
                height: 30

                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 18
                    source: trayEntry.modelData.icon

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        saturation: -1.0
                    }
                }

                TrayMenu {
                    id: customMenu
                    triggerItem: trayEntry
                    trayItem: trayEntry.modelData

                    onVisibleChanged: {
                        if (visible)
                            root.contextMenuOpened(customMenu)
                        else
                            root.contextMenuClosed(customMenu)
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor

                    onClicked: (mouse) => {
                        const item = trayEntry.modelData

                        if (mouse.button === Qt.RightButton) {
                            if (item.hasMenu)
                                customMenu.visible = !customMenu.visible
                        } else if (mouse.button === Qt.LeftButton) {
                            if (item.onlyMenu && item.hasMenu)
                                customMenu.visible = !customMenu.visible
                            else
                                item.activate()
                        }
                    }
                }
            }
        }
    }
}
