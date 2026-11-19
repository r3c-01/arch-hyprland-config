import Quickshell
import QtQuick
import Quickshell.Services.Pipewire

PopupWindow {
    id: root

    property Item triggerItem

    property bool devicesOpen: false

    onDevicesOpenChanged: Qt.callLater(() => {
        console.log("AUDIO-POPUP DEBUG",
                    "requested:", root.implicitHeight,
                    "actual:", root.height,
                    "devices:", root.outputDevices.length)
    })


    readonly property var outputDevices: {
        const current = Pipewire.defaultAudioSink

        return Array.from(Pipewire.nodes.values)
            .filter(node =>
                node.audio &&
                node.isSink &&
                !node.isStream)
            .sort((a, b) =>
                a === current ? -1 :
                b === current ? 1 : 0)
    }


    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio:
        sink && sink.ready ? sink.audio : null

    readonly property real level:
        audio ? Math.max(0, Math.min(1, audio.volume)) : 0

    readonly property bool muted:
        audio ? audio.muted : false

    implicitWidth: 300
    implicitHeight: 90 + (devicesOpen ? 1 + Math.min(168, outputDevices.length * 28) : 0)

    color: "transparent"
    visible: false
    grabFocus: true

    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        enabled: root.visible

        onActivated: root.visible = false
    }
    onVisibleChanged: {
        if (!visible) devicesOpen = false
    }

    anchor.item: triggerItem
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.margins.bottom: -4

    PwObjectTracker {
        objects: [root.sink]
    }

    function setSliderVolume(x) {
        if (!root.audio || sliderTrack.width <= 0)
            return

        const value = Math.max(0, Math.min(1,
            (x - sliderTrack.x) / sliderTrack.width))

        root.audio.volume = value

        if (root.audio.muted)
            root.audio.muted = false
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.50)
        border.width: 1
        border.color: "#333333"
        radius: 0
    }

    Row {
        id: volumeRow

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.top: parent.top
        anchors.topMargin: 16

        height: 18
        spacing: 12

        Canvas {
            id: speakerIcon

            width: 16
            height: 16
            anchors.verticalCenter: parent.verticalCenter

            readonly property int volumeState:
                !root.audio || root.muted || root.level <= 0 ? 0 :
                root.level <= 0.33 ? 1 :
                root.level <= 0.66 ? 2 : 3

            onVolumeStateChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d")
                if (!ctx) return

                ctx.clearRect(0, 0, width, height)
                ctx.strokeStyle = "#FFFFFF"
                ctx.lineWidth = 1.35
                ctx.lineCap = "round"
                ctx.lineJoin = "round"

                ctx.beginPath()
                ctx.moveTo(1.5, 6)
                ctx.lineTo(4.3, 6)
                ctx.lineTo(7.8, 3.1)
                ctx.lineTo(7.8, 12.9)
                ctx.lineTo(4.3, 10)
                ctx.lineTo(1.5, 10)
                ctx.closePath()
                ctx.stroke()

                if (volumeState === 0) {
                    ctx.beginPath()
                    ctx.moveTo(10.5, 6)
                    ctx.lineTo(14.5, 10)
                    ctx.moveTo(14.5, 6)
                    ctx.lineTo(10.5, 10)
                    ctx.stroke()
                } else {
                    const radii = [3.4, 5.3, 7.2]

                    for (let i = 0; i < volumeState; i++) {
                        ctx.beginPath()
                        ctx.arc(7.8, 8, radii[i], -0.62, 0.62)
                        ctx.stroke()
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    if (root.audio)
                        root.audio.muted = !root.audio.muted
                }
            }
        }

        Item {
            id: slider

            width: volumeRow.width - 16 - 38 - 24
            height: 18
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                id: sliderTrack

                x: 4
                width: parent.width - 8
                height: 5
                anchors.verticalCenter: parent.verticalCenter
                color: "#444444"

                Rectangle {
                    width: parent.width * root.level
                    height: parent.height
                    color: root.muted ? "#888888" : "#FFFFFF"
                }
            }

            Rectangle {
                width: 8
                height: 8
                radius: 0

                x: sliderTrack.x +
                   sliderTrack.width * root.level - width / 2

                anchors.verticalCenter: parent.verticalCenter
                color: root.muted ? "#888888" : "#FFFFFF"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor

                onPressed: (mouse) => {
                    root.setSliderVolume(mouse.x)
                }

                onPositionChanged: (mouse) => {
                    if (pressed)
                        root.setSliderVolume(mouse.x)
                }
            }
        }

        Text {
            width: 38
            anchors.verticalCenter: parent.verticalCenter

            text: root.audio
                ? Math.round(root.level * 100) + "%"
                : "--%"

            font.family: "Inter"
            font.pixelSize: 13
            font.weight: Font.DemiBold

            horizontalAlignment: Text.AlignRight
            color: "#FFFFFF"
        }
    }


    Rectangle {
        id: deviceSelector

        anchors.top: volumeRow.bottom
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 16
        anchors.rightMargin: 16

        height: 28 + (root.devicesOpen
            ? 1 + Math.min(168, root.outputDevices.length * 28)
            : 0)

        color: "transparent"
        border.width: 1
        border.color: root.devicesOpen || headerMouse.containsMouse
            ? "#888888" : "#444444"
        radius: 0

        Item {
            id: header

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 28

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.right: chevron.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter

                text: root.sink && root.sink.ready
                    ? (root.sink.description ||
                       root.sink.nickname ||
                       root.sink.name)
                    : "No output device"

                font.family: "Inter"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: "#FFFFFF"

                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Canvas {
                id: chevron

                width: 12
                height: 12
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter

                readonly property bool expanded: root.devicesOpen
                onExpandedChanged: requestPaint()

                onPaint: {
                    const ctx = getContext("2d")
                    if (!ctx) return

                    ctx.clearRect(0, 0, width, height)
                    ctx.strokeStyle = "#888888"
                    ctx.lineWidth = 1.5
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"

                    ctx.beginPath()
                    if (expanded) {
                        ctx.moveTo(2, 8)
                        ctx.lineTo(6, 4)
                        ctx.lineTo(10, 8)
                    } else {
                        ctx.moveTo(2, 4)
                        ctx.lineTo(6, 8)
                        ctx.lineTo(10, 4)
                    }
                    ctx.stroke()
                }
            }

            MouseArea {
                id: headerMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: root.devicesOpen = !root.devicesOpen
            }
        }

        Rectangle {
            id: separator

            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 1
            anchors.rightMargin: 1

            height: 1
            color: "#333333"
            visible: root.devicesOpen
        }

        ListView {
            id: deviceList

            anchors.top: separator.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 1
            anchors.rightMargin: 1

            height: root.devicesOpen
                ? Math.min(168, root.outputDevices.length * 28)
                : 0

            visible: root.devicesOpen
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            model: ScriptModel {
                values: root.outputDevices
            }

            delegate: Rectangle {
                id: deviceRow
                required property var modelData

                width: deviceList.width
                height: 28
                color: rowHover.containsMouse
                    ? "#222222" : "transparent"

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter

                    text: modelData.description ||
                          modelData.nickname ||
                          modelData.name

                    font.family: "Inter"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold

                    color: modelData === Pipewire.defaultAudioSink
                        ? "#FFFFFF" : "#888888"

                    elide: Text.ElideRight
                }

                MouseArea {
                    id: rowHover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        const selected = deviceRow.modelData

                        if (selected !== Pipewire.defaultAudioSink)
                            Pipewire.preferredDefaultAudioSink = selected

                        root.devicesOpen = false
                    }
                }
            }
        }

        Rectangle {
            id: dropdownBorderOverlay
            anchors.fill: parent
            z: 10
            color: "transparent"
            border.width: 1
            border.color: deviceSelector.border.color
            radius: 0
            enabled: false
        }

    }

}
