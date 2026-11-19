import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import Quickshell.Io

Rectangle {
    id: audio
    implicitHeight: (expanded ? 218 : 66) + (issue ? 32 : 0)
    radius: 0
    color: "#85303034"
    property bool expanded: false
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    property bool known: false
    property real volume: 0
    property bool muted: false
    property real requestedVolume: 0
    readonly property bool available: known
    readonly property var outputs: Pipewire.nodes.values.filter(n => n.audio && !n.isStream && n.isSink)
    readonly property var inputs: Pipewire.nodes.values.filter(n => n.audio && !n.isStream && !n.isSink)
    property string statusIssue: ""
    property string actionIssue: ""
    readonly property string issue: actionIssue || statusIssue
    property string pending: ""
    property var expectedNode: null
    property bool expectedMute: false
    property real expectedVolume: 0
    property real queuedVolume: -1

    PwObjectTracker { objects: Pipewire.nodes.values }

    function refresh() {
        if (!reader.running && !writer.running)
            reader.running = true;
    }
    function setVolume(value) {
        if (!available) return;
        requestedVolume = Math.max(0, Math.min(1, value));
        queuedVolume = requestedVolume;
        volumeDelay.restart();
    }
    function writeVolume() {
        if (!available || writer.running || reader.running || pending || queuedVolume < 0) return;
        expectedVolume = Math.round(queuedVolume * 100) / 100;
        queuedVolume = -1;
        actionIssue = "";
        pending = "volume";
        writer.command = ["timeout", "5s", "wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", Math.round(expectedVolume * 100) + "%"];
        writer.running = true;
        verification.restart();
    }
    function toggleMute() {
        if (!available || writer.running || pending) return;
        expectedMute = !muted;
        actionIssue = "";
        pending = "mute";
        writer.command = ["timeout", "5s", "wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", expectedMute ? "1" : "0"];
        writer.running = true;
        verification.restart();
    }
    function selectDevice(node, input) {
        if (!node || writer.running || pending) return;
        actionIssue = "";
        expectedNode = node;
        pending = input ? "input" : "output";
        writer.command = ["timeout", "5s", "wpctl", "set-default", String(node.id)];
        writer.running = true;
        verification.restart();
    }
    function confirmed() {
        if (pending === "output") return expectedNode && sink === expectedNode;
        if (pending === "input") return expectedNode && source === expectedNode;
        if (!known) return false;
        if (pending === "mute") return muted === expectedMute;
        return pending === "volume" && Math.abs(volume - expectedVolume) < 0.015;
    }
    Process {
        id: reader
        command: ["timeout", "5s", "wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector { id: statusOutput }
        stderr: StdioCollector { id: statusError }
        onExited: (code, exitStatus) => {
            const match = statusOutput.text.match(/Volume:\s*([0-9.]+)/);
            if (code !== 0 || exitStatus !== 0 || !match || !Number.isFinite(Number(match[1]))) {
                audio.known = false;
                audio.statusIssue = "Audio unavailable: " + (statusError.text.trim() || "Could not read the default output device.");
                return;
            }
            audio.volume = Number(match[1]);
            audio.muted = statusOutput.text.includes("[MUTED]");
            audio.known = true;
            audio.statusIssue = "";
            if (!writer.running && audio.pending && audio.confirmed()) {
                audio.pending = "";
                verification.stop();
            }
            if (audio.queuedVolume >= 0) volumeDelay.restart();
        }
    }
    Process {
        id: writer
        stderr: StdioCollector { id: errors }
        onExited: (code, exitStatus) => {
            if (code !== 0 || exitStatus !== 0) {
                audio.actionIssue = errors.text.trim() || "Audio change failed. Check the output device and try again.";
                audio.pending = "";
                audio.queuedVolume = -1;
                verification.stop();
            }
            audio.refresh();
        }
    }
    Timer {
        id: volumeDelay
        interval: 120
        onTriggered: {
            audio.writeVolume();
            if (audio.queuedVolume >= 0 && !audio.pending && audio.available) restart();
        }
    }
    Timer {
        id: poll
        interval: 1500
        running: audio.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: audio.refresh()
    }
    Connections {
        target: Pipewire
        function onDefaultAudioSinkChanged() { audio.refresh(); }
    }
    Timer {
        id: verification
        interval: 150
        repeat: true
        property int elapsed: 0
        onRunningChanged: if (running) elapsed = 0
        onTriggered: {
            elapsed += interval;
            if (!writer.running && !reader.running && audio.confirmed()) {
                audio.pending = "";
                stop();
                if (audio.queuedVolume >= 0) volumeDelay.restart();
            } else if (elapsed >= 6500) {
                audio.actionIssue = "Could not confirm the audio change. Check the selected device and try again.";
                audio.pending = "";
                audio.queuedVolume = -1;
                stop();
            } else if (!writer.running) audio.refresh();
        }
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12
        RowLayout {
            Layout.fillWidth: true
            spacing: 14
            Text { text: "AUDIO"; color: "#f0f0f2"; font.pixelSize: 12; font.bold: true; font.letterSpacing: 1 }
            Slider {
                id: slider
                objectName: "outputVolumeSlider"
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                implicitHeight: 32
                from: 0; to: 1; stepSize: 0.01
                enabled: audio.available
                value: !audio.available ? 0 : pressed || audio.queuedVolume >= 0 || audio.pending === "volume" || volumeDelay.running
                    ? audio.requestedVolume : Math.min(1, audio.volume)
                onMoved: audio.setVolume(value)
                onPressedChanged: if (!pressed && audio.queuedVolume >= 0) volumeDelay.restart()
                Accessible.name: "Output volume"
                background: Rectangle {
                    x: slider.leftPadding
                    y: slider.topPadding + slider.availableHeight / 2 - height / 2
                    width: slider.availableWidth
                    height: 6; radius: 0; color: "#414651"
                    Rectangle { width: slider.visualPosition * parent.width; height: parent.height; radius: 0; color: "#c4cad4" }
                }
                handle: Rectangle {
                    x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                    y: slider.topPadding + slider.availableHeight / 2 - height / 2
                    width: 12; height: 12; radius: 0
                    color: slider.visualFocus ? "white" : "#c4cad4"
                    visible: slider.hovered || slider.pressed || slider.visualFocus
                }
                WheelHandler {
                    onWheel: event => {
                        if (audio.available) {
                            audio.setVolume((audio.queuedVolume >= 0 || audio.pending === "volume" ? audio.requestedVolume : audio.volume) + (event.angleDelta.y > 0 ? 0.02 : -0.02));
                            event.accepted = true;
                        }
                    }
                }
            }
            Text {
                Layout.preferredWidth: 55
                horizontalAlignment: Text.AlignRight
                text: !audio.available ? "N/A" : audio.pending ? "WAIT" : audio.muted ? "MUTED" : Math.round(audio.volume * 100) + "%"
                color: "#c4cad4"; font.pixelSize: 12
            }
            ControlButton {
                text: audio.available && audio.muted ? "UNMUTE" : "MUTE"
                enabled: audio.available && !audio.pending
                selected: audio.available && audio.muted
                onClicked: audio.toggleMute()
            }
            ControlButton { text: audio.expanded ? "LESS" : "DEVICES"; onClicked: audio.expanded = !audio.expanded }
        }
        Text {
            visible: audio.issue !== ""
            Layout.fillWidth: true
            text: audio.issue
            color: "#edb49b"
            font.pixelSize: 11
            elide: Text.ElideRight
        }
        ColumnLayout {
            visible: audio.expanded
            Layout.fillWidth: true
            spacing: 8
            Text { text: "OUTPUT"; color: "#b7beca"; font.pixelSize: 10; font.bold: true }
            DeviceSelector {
                Layout.fillWidth: true
                model: audio.outputs
                textRole: "description"
                currentIndex: audio.outputs.indexOf(audio.sink)
                enabled: Pipewire.ready && !audio.pending
                onActivated: index => audio.selectDevice(audio.outputs[index], false)
                Accessible.name: "Output device"
            }
            Text { text: "MICROPHONE / INPUT"; color: "#b7beca"; font.pixelSize: 10; font.bold: true }
            RowLayout {
                Layout.fillWidth: true
                DeviceSelector {
                    Layout.fillWidth: true
                    model: audio.inputs; textRole: "description"
                    currentIndex: audio.inputs.indexOf(audio.source)
                    enabled: Pipewire.ready && !audio.pending
                    onActivated: index => audio.selectDevice(audio.inputs[index], true)
                    Accessible.name: "Input device"
                }
            }
        }
    }
    ToolTip.visible: issuePointer.hovered && (audio.issue !== "" || !audio.available)
    ToolTip.text: audio.issue || "Audio unavailable. Check that the default output device and WirePlumber are running."
    ToolTip.delay: 400
    HoverHandler { id: issuePointer }
    Rectangle {
        visible: audio.issue !== ""
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        height: 3; radius: 0; color: "#edb49b"
    }
}
