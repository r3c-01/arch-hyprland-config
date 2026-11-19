import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    property bool caffeineOn: false

    visible: caffeineOn
    implicitWidth: caffeineOn ? 20 : 0
    implicitHeight: 30

    Process {
        id: statusReader

        command: [
            "qs", "-p",
            Quickshell.env("HOME") + "/.config/quickshell-caffeine",
            "ipc", "call", "caffeine", "status"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const status = this.text.trim().toLowerCase();

                if (status === "on")
                    root.caffeineOn = true;
                else if (status === "off")
                    root.caffeineOn = false;
            }
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: {
            if (!statusReader.running)
                statusReader.running = true;
        }
    }

    Image {
        anchors.centerIn: parent
        width: 20
        height: 20
        source: "icons/coffee.svg"
        sourceSize.width: 80
        sourceSize.height: 80
        fillMode: Image.PreserveAspectFit
    }
}
