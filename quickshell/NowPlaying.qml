import Quickshell
import QtQuick
import Quickshell.Services.Mpris

// Compact Now Playing on the bar + click-to-open glass mini-player.
// The parent shell still determines this item's width and placement.
Item {
    id: media
    implicitHeight: 32

    readonly property var player: {
        const players = Mpris.players.values
        let paused = null
        for (const candidate of players) {
            if (!candidate || !candidate.trackTitle || !candidate.trackTitle.trim())
                continue
            if (candidate.isPlaying)
                return candidate
            if (candidate.playbackState === MprisPlaybackState.Paused && !paused)
                paused = candidate
        }
        return paused
    }

    visible: player !== null && width >= 125

    function clockTime(seconds) {
        if (!isFinite(seconds) || seconds < 0)
            return "0:00"
        const s = Math.floor(seconds)
        return Math.floor(s / 60) + ":" + ("0" + (s % 60)).slice(-2)
    }

    onPlayerChanged: {
        if (!player)
            miniPlayer.visible = false
    }

    Timer {
        interval: 1000
        repeat: true
        running: media.visible && media.player !== null && media.player.isPlaying
        onTriggered: {
            if (media.player)
                media.player.positionChanged()
        }
    }

    // Original bar layout, with the track text made clickable.
    Row {
        id: barRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -1
        height: 23
        spacing: 8

        Image {
            width: 17
            height: 17
            anchors.verticalCenter: parent.verticalCenter
            source: "icons/music-notes.svg"
            sourceSize.width: 68
            sourceSize.height: 68
            fillMode: Image.PreserveAspectFit
        }

        Item {
            id: titleHitArea
            width: Math.max(0, barRow.width - 56)
            height: barRow.height

            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                font.family: "Inter"
                font.pixelSize: 11
                color: trackMouse.containsMouse ? "#ffffff"
                    : media.player && media.player.isPlaying ? "#e0e4ea" : "#a6afb9"
                text: media.player ? media.player.trackTitle
                    + (media.player.trackArtist ? " · " + media.player.trackArtist : "") : ""
                elide: Text.ElideRight
            }

            MouseArea {
                id: trackMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: media.player !== null
                cursorShape: Qt.PointingHandCursor
                onClicked: miniPlayer.visible = !miniPlayer.visible
            }
        }

        Item {
            width: 20
            height: 23

            Image {
                anchors.centerIn: parent
                width: 17
                height: 17
                sourceSize.width: 68
                sourceSize.height: 68
                source: media.player && media.player.isPlaying
                    ? "icons/pause.svg" : "icons/play.svg"
                fillMode: Image.PreserveAspectFit
                opacity: 0.90
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: media.player !== null && media.player.canTogglePlaying
                onClicked: if (media.player) media.player.togglePlaying()
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 2
        color: "#20ffffff"

        Rectangle {
            height: parent.height
            color: "#9cd7dce3"
            width: media.player && media.player.length > 0
                ? parent.width * Math.max(0, Math.min(1,
                    media.player.position / media.player.length)) : 0
        }
    }

    PopupWindow {
        id: miniPlayer
        visible: false
        grabFocus: true
        color: "transparent"
        implicitWidth: 356
        implicitHeight: 254

        // Anchor below the NOW PLAYING item, not at the screen edge.
        anchor.item: media
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Right
        anchor.margins.bottom: -6

        Shortcut {
            sequence: "Escape"
            context: Qt.ApplicationShortcut
            enabled: miniPlayer.visible
            onActivated: miniPlayer.visible = false
        }

        Rectangle {
            anchors.fill: parent
            radius: 0
            color: Qt.rgba(0.055, 0.059, 0.07, 0.58)
            border.width: 1
            border.color: "#565b64"
        }

        Column {
            id: popupContent
            anchors.fill: parent
            anchors.margins: 17
            spacing: 12

            Row {
                width: parent.width
                height: 96
                spacing: 15

                Rectangle {
                    width: 96
                    height: 96
                    clip: true
                    radius: 0
                    color: "#30343a"
                    border.width: 1
                    border.color: "#454b53"

                    Image {
                        id: coverArt
                        anchors.fill: parent
                        anchors.margins: 1
                        source: media.player ? media.player.trackArtUrl : ""
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                    }

                    Image {
                        anchors.centerIn: parent
                        width: 30
                        height: 30
                        visible: coverArt.status !== Image.Ready
                        source: "icons/music-notes.svg"
                        sourceSize.width: 120
                        sourceSize.height: 120
                        fillMode: Image.PreserveAspectFit
                        opacity: 0.7
                    }
                }

                Column {
                    width: Math.max(0, parent.width - 111)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Text {
                        width: parent.width
                        text: media.player ? media.player.trackTitle : "Not playing"
                        font.family: "Inter"
                        font.pixelSize: 17
                        font.bold: true
                        color: "#f0f0f2"
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: media.player ? (media.player.trackArtist || "Unknown artist") : ""
                        font.family: "Inter"
                        font.pixelSize: 14
                        color: "#d5d9de"
                        elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: media.player ? (media.player.trackAlbum || "") : ""
                        font.family: "Inter"
                        font.pixelSize: 12
                        color: "#aeb4bf"
                        elide: Text.ElideRight
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: "#42474f" }

            // Seek bar updates while playing; clicking seeks where supported.
            Item {
                width: parent.width
                height: 13

                Rectangle {
                    id: seekTrack
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 4
                    radius: 0
                    color: "#4a505a"

                    Rectangle {
                        height: parent.height
                        radius: 0
                        color: "#e4e8ed"
                        width: media.player && media.player.length > 0
                            ? parent.width * Math.max(0, Math.min(1,
                                media.player.position / media.player.length)) : 0
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: media.player !== null && media.player.canSeek
                        && media.player.positionSupported && media.player.lengthSupported
                        && media.player.length > 0
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: (mouse) => {
                        if (!media.player || seekTrack.width <= 0)
                            return
                        const ratio = Math.max(0, Math.min(1, mouse.x / seekTrack.width))
                        media.player.position = ratio * media.player.length
                    }
                }
            }

            Item {
                width: parent.width
                height: 14

                Text {
                    anchors.left: parent.left
                    text: media.player ? media.clockTime(media.player.position) : "0:00"
                    font.family: "Inter"
                    font.pixelSize: 11
                    color: "#aeb6c0"
                }
                Text {
                    anchors.right: parent.right
                    text: media.player && media.player.lengthSupported
                        ? media.clockTime(media.player.length) : "--:--"
                    font.family: "Inter"
                    font.pixelSize: 11
                    color: "#aeb6c0"
                }
            }

            Item {
                width: parent.width
                height: 38

                Row {
                    anchors.centerIn: parent
                    spacing: 25

                    Item {
                        width: 34; height: 34
                        Image {
                            anchors.centerIn: parent
                            width: 21; height: 21
                            source: "icons/skip-back.svg"
                            sourceSize.width: 84
                            sourceSize.height: 84
                            opacity: prevMouse.enabled ? (prevMouse.containsMouse ? 1 : 0.86) : 0.3
                        }
                        MouseArea {
                            id: prevMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            enabled: media.player !== null && media.player.canGoPrevious
                            onClicked: if (media.player) media.player.previous()
                        }
                    }

                    Item {
                        width: 38; height: 34
                        Image {
                            anchors.centerIn: parent
                            width: 23; height: 23
                            sourceSize.width: 92
                            sourceSize.height: 92
                            source: media.player && media.player.isPlaying
                                ? "icons/pause.svg" : "icons/play.svg"
                            opacity: playMouse.enabled ? (playMouse.containsMouse ? 1 : 0.88) : 0.3
                        }
                        MouseArea {
                            id: playMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            enabled: media.player !== null && media.player.canTogglePlaying
                            onClicked: if (media.player) media.player.togglePlaying()
                        }
                    }

                    Item {
                        width: 34; height: 34
                        Image {
                            anchors.centerIn: parent
                            width: 21; height: 21
                            source: "icons/skip-forward.svg"
                            sourceSize.width: 84
                            sourceSize.height: 84
                            opacity: nextMouse.enabled ? (nextMouse.containsMouse ? 1 : 0.86) : 0.3
                        }
                        MouseArea {
                            id: nextMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            enabled: media.player !== null && media.player.canGoNext
                            onClicked: if (media.player) media.player.next()
                        }
                    }
                }
            }
        }
    }
}
