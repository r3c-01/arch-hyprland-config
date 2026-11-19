import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.Notifications
import Quickshell.Io
import Quickshell.Services.Mpris

Scope {
    id: root

    readonly property int historyCount: notificationHistory.count

    function toggleHistory(): void {
        historyVisible = !historyVisible
    }
        property bool songVisible: false
        property string songTitle: ""
        property string songArtist: ""
        property string songArt: ""
    property bool historyVisible: false

    property bool dndEnabled: false

    function toggleDnd(): void {
        dndEnabled = !dndEnabled
    }

    readonly property var spotify: {
        const players = Mpris.players.values

        for (let i = 0; i < players.length; i++) {
            const player = players[i]

            if ((player.desktopEntry || "").toLowerCase() === "spotify" ||
                (player.dbusName || "").toLowerCase().includes("spotify")) {
                return player
            }
        }

        return null
    }

        Connections {
        target: root.spotify

        function onPostTrackChanged() {
            if (!root.spotify)
                return

            trackDelay.restart()
        }
    }

    Timer {
        id: trackDelay
        interval: 250
        repeat: false

        onTriggered: {
            const player = root.spotify

            if (!player || !player.trackTitle)
                return

            root.songTitle = player.trackTitle
            root.songArtist = player.trackArtist || "Unknown Artist"
            root.songArt = player.trackArtUrl || ""

            root.songVisible = true
            songTimeout.restart()

            console.log("[spotify-popup]", root.songTitle, root.songArtist)
        }
    }

    Timer {
        id: songTimeout
        interval: 5000
        repeat: false

        onTriggered: root.songVisible = false
    }

    ListModel {
        id: notificationHistory
    }

    IpcHandler {
        target: "notifications"

        function count(): int {
            return notificationHistory.count
        }

        function toggle(): void {
            root.historyVisible = !root.historyVisible
        }

        function clear(): void {
            notificationHistory.clear()
        }
    }

    NotificationServer {
        id: notificationServer
        keepOnReload: false
        bodySupported: true

        onNotification: (notification) => {
            notification.tracked = true

            if (!notification.transient) {
                notificationHistory.insert(0, {
                    app: notification.appName || "Application",
                    title: notification.summary || "",
                    body: notification.body || "",
                    icon: notification.appIcon || "",
                    time: Qt.formatTime(new Date(), "hh:mm AP")
                })

                if (notificationHistory.count > 50)
                    notificationHistory.remove(50)
            }
            console.log("[notify] received:",
                        notification.appName,
                        notification.summary)
        }
    }

    PanelWindow {
        id: notificationWindow

        screen: Quickshell.screens.find(s => s.name === "DP-1")

        visible: !root.historyVisible &&
         (root.songVisible ||
         (!root.dndEnabled &&
         notificationServer.trackedNotifications.values.length > 0))

        anchors {
            top: true
            right: true
        }

        margins {
            top: 40
            right: 16
        }

        implicitWidth: 340
        implicitHeight: Math.max(1, stack.implicitHeight)

        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay

        Column {
            id: stack

            anchors.top: parent.top
            anchors.right: parent.right
            width: parent.width
            spacing: 8
                        Rectangle {
                id: songCard

                visible: root.songVisible

                width: stack.width
                height: 90

                color: Qt.rgba(0, 0, 0, 0.50)
                border.width: 1
                border.color: "#333333"
                radius: 0

                Row {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    Rectangle {
                        id: artwork

                        width: 60
                        height: 60
                        color: "#222222"
                        clip: true

                        Text {
                            anchors.centerIn: parent
                            text: "♫"
                            color: "#888888"
                            font.pixelSize: 25
                            visible: cover.status !== Image.Ready
                        }

                        Image {
                            id: cover
                            anchors.fill: parent
                            source: root.songArt
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: status === Image.Ready
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - artwork.width - 12
                        spacing: 5

                        Text {
                            width: parent.width
                            text: "SPOTIFY · NOW PLAYING"
                            color: "#888888"
                            font.family: "Inter"
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }

                        Text {
                            width: parent.width
                            text: root.songTitle
                            color: "#FFFFFF"
                            font.family: "Inter"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: root.songArtist
                            color: "#AAAAAA"
                            font.family: "Inter"
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }
                }
            }
            Repeater {
                model: notificationServer.trackedNotifications

                delegate: Rectangle {
                    id: card

                    visible: !root.dndEnabled

                    required property var modelData

                    width: stack.width
                    height: 90
                    color: Qt.rgba(0, 0, 0, 0.50)
                    border.width: 1
                    border.color: "#333333"
                    radius: 0

                    Timer {
                        interval: 5000
                        running: true
                        repeat: false

                        onTriggered: {
                            card.modelData.expire()
                        }
                    }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8

                        Row {
                            width: parent.width
                            height: 16
                            spacing: 8

                            IconImage {
                                implicitSize: 16
                                anchors.verticalCenter: parent.verticalCenter

                                source: {
                                    const name = card.modelData.appIcon

                                    if (!name)
                                        return Quickshell.iconPath(
                                            "application-x-executable"
                                        )

                                    if (name.startsWith("/"))
                                        return "file://" + name

                                    if (name.startsWith("image:") ||
                                        name.startsWith("file:") ||
                                        name.startsWith("data:"))
                                        return name

                                    return Quickshell.iconPath(
                                        name,
                                        "application-x-executable"
                                    )
                                }

                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    saturation: -1.0
                                    brightness: 0.40
                                }
                            }

                            Text {
                                width: parent.width - 52

                                text: card.modelData.appName
                                color: "#AAAAAA"

                                font.family: "Inter"
                                font.weight: Font.DemiBold
                                font.pixelSize: 11

                                elide: Text.ElideRight
                            }

                            Item {
                                width: 20
                                height: 16

                                Text {
                                    anchors.centerIn: parent

                                    text: "\u00d7"
                                    color: closeArea.containsMouse
                                           ? "#FFFFFF" : "#888888"

                                    font.family: "Inter"
                                    font.pixelSize: 17
                                }

                                MouseArea {
                                    id: closeArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: card.modelData.dismiss()
                                }
                            }
                        }

                        Text {
                            width: parent.width

                            text: card.modelData.summary
                            textFormat: Text.PlainText
                            elide: Text.ElideRight

                            color: "#FFFFFF"
                            font.family: "Inter"
                            font.weight: Font.DemiBold
                            font.pixelSize: 14
                        }

                        Text {
                            width: parent.width

                            text: card.modelData.body
                            textFormat: Text.PlainText
                            elide: Text.ElideRight

                            color: "#AAAAAA"
                            font.family: "Inter"
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }

    PanelWindow {
        id: historyWindow
        focusable: true

        HyprlandFocusGrab {
            id: notificationFocusGrab
            windows: [historyWindow]
            active: root.historyVisible

            onCleared: root.historyVisible = false
        }

        Shortcut {
            id: historyEscapeShortcut
            sequence: "Escape"
            context: Qt.WindowShortcut
            enabled: root.historyVisible

            onActivated: root.historyVisible = false
        }
        WlrLayershell.namespace: "quickshell-notification-center"

        screen: Quickshell.screens.find(s => s.name === "DP-1")
        visible: root.historyVisible

        anchors {
            top: true
            right: true
        }

        margins {
            top: 40
            right: 16
        }

        implicitWidth: 390
        implicitHeight: 520

        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.50)
            border.color: "#333333"
            border.width: 1
            radius: 0

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Item {
                    width: parent.width
                    height: 32

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "NOTIFICATIONS"
                        color: "#FFFFFF"
                        font.family: "Inter"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        Item {
                            width: 62
                            height: 24

                            Text {
                                anchors.centerIn: parent
                                text: "Clear all"
                                color: clearMouse.containsMouse
                                       ? "#FFFFFF" : "#999999"
                                font.family: "Inter"
                                font.pixelSize: 12
                            }

                            MouseArea {
                                id: clearMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: notificationHistory.clear()
                            }
                        }

                        Item {
                            width: 22
                            height: 22

                            Text {
                                anchors.centerIn: parent
                                text: "×"
                                color: closeMouse.containsMouse
                                       ? "#FFFFFF" : "#999999"
                                font.family: "Inter"
                                font.pixelSize: 18
                            }

                            MouseArea {
                                id: closeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.historyVisible = false
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#333333"
                }

                Item {
                    width: parent.width
                    height: parent.height - 53

                    ListView {
                        id: historyList
                        anchors.fill: parent
                        clip: true
                        spacing: 8
                        model: notificationHistory

                        delegate: Rectangle {
                            width: historyList.width
                            height: 104
                            color: Qt.rgba(1, 1, 1, 0.045)
                            border.width: 1
                            border.color: "#333333"

                            Column {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 7

                                Text {
                                    width: parent.width
                                    text: model.app + "  ·  " + model.time
                                    color: "#999999"
                                    font.family: "Inter"
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: model.title
                                    color: "#FFFFFF"
                                    font.family: "Inter"
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: model.body
                                    color: "#AAAAAA"
                                    font.family: "Inter"
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: notificationHistory.count === 0
                        text: "No notifications"
                        color: "#888888"
                        font.family: "Inter"
                        font.pixelSize: 13
                    }
                }
            }
        }
    }

}
