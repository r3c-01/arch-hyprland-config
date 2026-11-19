import QtQuick
import QtQuick.Controls
import Quickshell.Services.Pipewire

Item {
    id: root

    signal popupRequested()

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio:
        sink && sink.ready ? sink.audio : null

    readonly property real level:
        audio ? audio.volume : 0

    readonly property bool muted:
        audio ? audio.muted : false

    implicitWidth: content.implicitWidth
    implicitHeight: 30

    MouseArea {
        id: volumeMouse
        anchors.fill: parent
        hoverEnabled: true
        ToolTip.visible: containsMouse
        ToolTip.delay: 500
        ToolTip.text: !root.audio ? "Audio unavailable" : root.muted ? "Muted" : Math.round(root.level * 100) + "%"
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        scrollGestureEnabled: true

        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton && root.audio) {
                root.audio.muted = !root.audio.muted
            } else if (mouse.button === Qt.LeftButton) {
                root.popupRequested()
            }
        }

        onWheel: (wheel) => {
            console.log("Volume wheel:", wheel.angleDelta.y)

            if (!root.audio || wheel.angleDelta.y === 0)
                return

            const step = wheel.angleDelta.y > 0 ? 5 : -5
            const current = Math.round(root.audio.volume * 100)
            const next = Math.max(0, Math.min(100, current + step))

            root.audio.volume = next / 100
            wheel.accepted = true
        }
    }

    PwObjectTracker {
        objects: [root.sink]
    }

    Row {
        id: content

        anchors.centerIn: parent
        spacing: 7

        Image {
            id: speakerIcon
            width: 20
            height: 20
            anchors.verticalCenter: parent.verticalCenter
            sourceSize.width: 72
            sourceSize.height: 72
            fillMode: Image.PreserveAspectFit
            source: !root.audio || root.muted || root.level <= 0
                ? "icons/speaker-x.svg"
                : root.level <= 0.33
                    ? "icons/speaker-low.svg" : "icons/speaker-high.svg"
        }


    }
}
