import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: caffeine

    implicitHeight: 66
    radius: 0
    color: "#85303034"

    property bool active: false
    property bool known: false
    property bool busy: false
    property string message: "Checking controller..."

    readonly property string controller:
        Quickshell.env("HOME") + "/.config/quickshell-caffeine"

    function refresh() {
        if (!statusReader.running && !busy)
            statusReader.running = true;
    }

    Process {
        id: statusReader

        command: [
            "qs", "-p", caffeine.controller,
            "ipc", "call", "caffeine", "status"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const value = this.text.trim().toLowerCase();

                if (value === "on" || value === "off") {
                    caffeine.active = value === "on";
                    caffeine.known = true;
                    caffeine.message = caffeine.active
                        ? "Idle inhibition active"
                        : "Normal idle behavior";
                } else {
                    caffeine.known = false;
                    caffeine.message = "Controller unavailable";
                }
            }
        }

        onExited: (code, status) => {
            if (code !== 0) {
                caffeine.known = false;
                caffeine.message = "Controller unavailable";
            }
        }
    }

    Process {
        id: toggleWriter

        command: [
            "qs", "-p", caffeine.controller,
            "ipc", "call", "caffeine", "toggle"
        ]

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim())
                    console.warn("Caffeine:", this.text.trim());
            }
        }

        onExited: (code, status) => {
            caffeine.busy = false;

            if (code !== 0) {
                caffeine.message = "Caffeine command failed";
                caffeine.known = false;
            }

            if (!statusReader.running)
                statusReader.running = true;
        }
    }

    function toggle() {
        if (busy || !known ||
            toggleWriter.running || statusReader.running)
            return;

        busy = true;
        message = "Changing caffeine state...";
        toggleWriter.running = true;
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: caffeine.refresh()
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        ColumnLayout {
            spacing: 5

            Text {
                text: "CAFFEINE"
                color: "#f0f0f2"
                font.pixelSize: 12
                font.bold: true
                font.letterSpacing: 1
            }

            Text {
                text: caffeine.message
                color: "#939ba8"
                font.pixelSize: 11
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Rectangle {
            Layout.preferredWidth: 82
            Layout.preferredHeight: 32
            radius: 0

            color: caffeine.active
                ? "#ae3b3b3d"
                : "#a0303034"
            border.width: 1
            border.color: caffeine.active
                ? "#66c8cdd4" : "#33c8cdd4"

            opacity: caffeine.known ? 1 : 0.5

            Text {
                anchors.centerIn: parent

                text: caffeine.busy ? "WAIT" :
                      !caffeine.known ? "N/A" :
                      caffeine.active ? "ON" : "OFF"

                color: "#f0f0f2"
                font.pixelSize: 11
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                enabled: caffeine.known && !caffeine.busy
                cursorShape: Qt.PointingHandCursor
                onClicked: caffeine.toggle()
            }
        }
    }
}
