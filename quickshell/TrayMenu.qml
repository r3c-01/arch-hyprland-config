import QtQuick
import Quickshell

PopupWindow {
    id: root

    property Item triggerItem
    property var trayItem: null

    anchor.item: triggerItem
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.bottom: -4

    width: 240
    height: Math.max(14, menuColumn.implicitHeight + 12)
    color: "transparent"
    grabFocus: false

    QsMenuOpener {
        id: menuOpener
        menu: root.trayItem ? root.trayItem.menu : null
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.50)
        border.width: 1
        border.color: "#333333"
        radius: 0

        Column {
            id: menuColumn

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 6
            spacing: 0

            Repeater {
                model: menuOpener.children

                delegate: Item {
                    id: entry

                    required property QsMenuEntry modelData

                    width: menuColumn.width
                    height: modelData.isSeparator ? 9 : 28

                    Rectangle {
                        anchors.fill: parent
                        visible: !entry.modelData.isSeparator
                        color: entryArea.containsMouse
                               && entry.modelData.enabled
                               ? "#222222" : "transparent"
                    }

                    Rectangle {
                        visible: entry.modelData.isSeparator
                        anchors.centerIn: parent
                        width: parent.width - 16
                        height: 1
                        color: "#333333"
                    }

                    Image {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16

                        source: entry.modelData.isSeparator
                                ? "" : entry.modelData.icon
                        sourceSize.width: 16
                        sourceSize.height: 16
                        fillMode: Image.PreserveAspectFit

                        visible: source !== ""
                                 && entry.modelData.checkState !== Qt.Checked
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter

                        text: entry.modelData.checkState === Qt.Checked
                              ? "\u2713" : ""
                        color: "#FFFFFF"
                        font.family: "Inter"
                        font.pixelSize: 13
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 34
                        anchors.right: parent.right
                        anchors.rightMargin: 24
                        anchors.verticalCenter: parent.verticalCenter

                        text: entry.modelData.isSeparator
                              ? "" : entry.modelData.text

                        color: entry.modelData.enabled
                               ? "#FFFFFF" : "#777777"
                        font.family: "Inter"
                        font.weight: Font.DemiBold
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter

                        text: entry.modelData.hasChildren ? "\u203a" : ""
                        color: "#999999"
                        font.pixelSize: 16
                    }

                    MouseArea {
                        id: entryArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        enabled: !entry.modelData.isSeparator
                                 && entry.modelData.enabled

                        onClicked: {
                            console.log("[menu] clicked:", entry.modelData.text,
                                        "submenu:", entry.modelData.hasChildren)
                            if (entry.modelData.hasChildren)
                                return

                            entry.modelData.triggered()
                            root.visible = false
                        }
                    }
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        enabled: root.visible
        onActivated: root.visible = false
    }
}
