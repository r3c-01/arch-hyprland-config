import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell

Rectangle {
    id: gameMode
    implicitHeight: 66
    radius: 0
    color: "#85303034"

    readonly property string controller: Quickshell.env("HOME") + "/.local/bin/game-mode"
    property bool notifyChanges: false
    property bool active: false
    property bool known: false
    property bool checking: false
    property bool busy: true
    property string mode: "unknown"
    property string error: ""
    property string actionError: ""
    property string pendingAction: ""
    property string message: "Checking Game Mode…"
    readonly property string label: busy ? "WAIT" : error ? "ERROR" : active ? "ON" : "OFF"

    function refresh() {
        if (!statusReader.running && !actionWriter.running) {
            if (!known) busy = true;
            checking = true;
            statusReader.running = true;
        }
    }

    function toggle() {
        if (busy || checking || statusReader.running || actionWriter.running) return;
        // A known journal, even an unverified one, must be restored first.
        if (!known) { refresh(); return; }
        pendingAction = mode === "disabled" ? "enable" : "disable";
        actionError = "";
        error = "";
        busy = true;
        message = pendingAction === "enable" ? "Enabling Game Mode…" : "Restoring desktop…";
        actionWriter.command = [controller, pendingAction];
        actionWriter.running = true;
    }

    Process {
        id: statusReader
        command: [gameMode.controller, "status"]
        stdout: StdioCollector { id: statusOutput }
        stderr: StdioCollector { id: statusError }
        onExited: (code, exitStatus) => {
            gameMode.busy = false;
            gameMode.checking = false;
            try {
                const data = JSON.parse(statusOutput.text);
                if (!["disabled", "enabled", "enabling", "restoring"].includes(data.mode))
                    throw new Error("Unexpected controller status");
                gameMode.mode = data.mode;
                gameMode.active = data.mode !== "disabled";
                gameMode.known = true;
                const issue = data.issue || ((code !== 0 || exitStatus !== 0 || data.verified === false)
                    ? "Controller verification failed" : "");
                gameMode.error = gameMode.actionError || issue;
                if (data.mode === "enabling" || data.mode === "restoring")
                    gameMode.error = gameMode.error || "Recovery pending";
                gameMode.message = gameMode.error
                    ? gameMode.error + (gameMode.active ? " · Click to restore desktop" : " · Click to retry")
                    : gameMode.active ? "Game Mode enabled · Click to restore desktop"
                                           : "Game Mode disabled · Click to enable";
                if (gameMode.pendingAction && !gameMode.error && gameMode.notifyChanges) {
                    notification.command = ["notify-send", "Game Mode", gameMode.active ? "Enabled" : "Desktop restored"];
                    notification.running = true;
                }
            } catch (err) {
                gameMode.known = false;
                gameMode.error = gameMode.actionError || statusError.text.trim() || String(err);
                gameMode.message = gameMode.error + " · Click to retry status";
            }
            gameMode.pendingAction = "";
            gameMode.actionError = "";
        }
    }

    Process {
        id: actionWriter
        stdout: StdioCollector { id: actionOutput }
        stderr: StdioCollector { id: actionStderr }
        onExited: (code, exitStatus) => {
            if (code !== 0 || exitStatus !== 0)
                gameMode.actionError = actionStderr.text.trim() || actionOutput.text.trim() || "Game Mode command failed";
            // Keep WAIT until the resulting state has been checked.
            gameMode.checking = true;
            statusReader.running = true;
        }
    }

    Process { id: notification }

    Timer {
        interval: 3000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: gameMode.refresh()
    }

    // Failed-to-start processes may not emit exited; allow a status retry.
    Timer {
        interval: 1000
        repeat: true
        running: gameMode.busy || gameMode.checking
        onTriggered: {
            if (!statusReader.running && !actionWriter.running) {
                gameMode.busy = false;
                gameMode.checking = false;
                gameMode.known = false;
                gameMode.error = "Could not start Game Mode controller";
                gameMode.message = gameMode.error + " · Click to retry status";
            }
        }
    }

    IpcHandler {
        target: "gameMode"
        function toggle(): void { gameMode.toggle(); }
        function refresh(): void { gameMode.refresh(); }
        function status(): string {
            return JSON.stringify({mode: gameMode.mode, active: gameMode.active,
                known: gameMode.known, busy: gameMode.busy, label: gameMode.label,
                error: gameMode.error, message: gameMode.message});
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5

            Text {
                text: "GAME MODE"
                color: "#f0f0f2"
                font.pixelSize: 12
                font.bold: true
                font.letterSpacing: 1
            }

            Text {
                Layout.fillWidth: true
                text: gameMode.message
                color: "#939ba8"
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }

        Rectangle {
            Layout.preferredWidth: 82
            Layout.preferredHeight: 32
            radius: 0
            color: gameMode.active ? "#ae3b3b3d" : "#a0303034"
            border.width: 1
            border.color: gameMode.error ? "#d99477"
                : gameMode.active ? "#66c8cdd4" : "#33c8cdd4"

            Text {
                anchors.centerIn: parent
                text: gameMode.label
                color: gameMode.error ? "#edb49b" : "#f0f0f2"
                font.pixelSize: 11
                font.bold: true
            }

            MouseArea {
                id: pointer
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: gameMode.busy ? Qt.BusyCursor : Qt.PointingHandCursor
                onClicked: gameMode.toggle()
            }
        }
    }

    ToolTip.visible: pointer.containsMouse
    ToolTip.delay: 400
    ToolTip.text: message
    Accessible.role: Accessible.Button
    Accessible.name: "Game Mode " + label
    Accessible.description: message
    Accessible.onPressAction: toggle()
}
