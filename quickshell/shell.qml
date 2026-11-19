//@ pragma UseQApplication
import Quickshell
import QtQuick
import Quickshell.Wayland
import Quickshell.Io

Scope {
    id: root

    property bool dockOpen: false

    IpcHandler {
        target: "dock"

        function toggle(): void {
            root.dockOpen = !root.dockOpen
        }
    }

    Notifications { id: notifications }
    DesktopVisualizer {}
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barPanel
            WlrLayershell.namespace: "quickshell-bar"
            required property var modelData

            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 42
            color: Qt.rgba(0, 0, 0, 0.50)
            exclusiveZone: 42
Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom

    height: 1
    color: "#222222"
}
            DateTime {
                id: dateTime
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                onClicked: calendarPopup.visible = !calendarPopup.visible
            }

            CalendarPopup {
                id: calendarPopup
                barWindow: barPanel
            }

            // Optical spacing calibrated to the actual Phosphor Regular SVGs.
            // Deliberate gaps avoid accumulating margins and icon offsets.
            Row {
                id: rightStatus
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0


                SystemMonitorButton {
                    anchors.verticalCenter: parent.verticalCenter
                }
                Item { width: 13; height: 1 }
                CaffeineIndicator {
                    id: caffeineIndicator
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Only occupy space when the caffeine indicator is visible.
                Item {
                    width: 13
                    height: 1
                    visible: caffeineIndicator.visible
                }

                Volume {
                    id: volumeIndicator
                    anchors.verticalCenter: parent.verticalCenter
                    onPopupRequested: audioPopup.visible = !audioPopup.visible
                }

                Item { width: 12; height: 1 }

                TrayToggle {
                    id: trayToggle
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item { width: 9; height: 1 }

                Item {
                    id: controlCenterButton
                    width: 20
                    height: 30
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        anchors.centerIn: parent
                        width: 20
                        height: 20
                        sourceSize.width: 72
                        sourceSize.height: 72
                        fillMode: Image.PreserveAspectFit
                        source: "icons/sliders-horizontal.svg"
                        opacity: controlCenterMouse.containsMouse ? 1.0 : 0.91
                    }

                    MouseArea {
                        id: controlCenterMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton
                        onClicked: Quickshell.execDetached([
                            Quickshell.env("HOME") + "/.local/bin/control-center-toggle"
                        ])
                    }
                }

                Item { width: 9; height: 1 }

                Item {
                    id: notificationBell
                    height: 30
                    width: bellRow.implicitWidth
                    anchors.verticalCenter: parent.verticalCenter

                    Row {
                        id: bellRow
                        anchors.centerIn: parent
                        spacing: 4

                        Image {
                            id: bellIcon
                            width: 20
                            height: 20
                            sourceSize.width: 72
                            sourceSize.height: 72
                            fillMode: Image.PreserveAspectFit
                            anchors.verticalCenter: parent.verticalCenter
                            source: notifications.dndEnabled ? "icons/bell-slash.svg" : "icons/bell.svg"
                            opacity: bellMouse.containsMouse ? 1.0 : 0.91
                        }
                        Rectangle {
                            visible: notifications.historyCount > 0
                            width: visible ? Math.max(16, countLabel.implicitWidth + 8) : 0
                            height: 17
                            radius: 0
                            anchors.verticalCenter: parent.verticalCenter
                            color: "#18ffffff"
                            border.width: 1
                            border.color: "#20ffffff"
                            Text {
                                id: countLabel
                                anchors.centerIn: parent
                                text: notifications.historyCount
                                color: "#FFFFFF"
                                font.family: "Inter"
                                font.pixelSize: 10
                                font.weight: Font.Medium
        }
    }
}

                    MouseArea {
                        id: bellMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: (mouse) => {
                            if (mouse.button === Qt.RightButton)
                                notifications.toggleDnd()
                            else
                                notifications.toggleHistory()
                        }
                    }
                }
            }

            AudioPopup {
                id: audioPopup
                triggerItem: volumeIndicator
            }

            NowPlaying {
                anchors.left: workspaceIndicator.right
                anchors.leftMargin: 22
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(0, Math.min(300,
                    (barPanel.width - dateTime.width) / 2 - workspaceIndicator.width - 42))
            }

            Workspaces {
                id: workspaceIndicator
                monitorName: modelData.name

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
    Variants {
        model: Quickshell.screens
        AppDock {
            required property var modelData
            targetScreen: modelData
            dockOpen: root.dockOpen
            onCloseRequested: root.dockOpen = false
        }
    }

}
