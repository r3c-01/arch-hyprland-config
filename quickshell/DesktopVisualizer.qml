pragma ComponentBehavior: Bound

import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    property bool visualizerEnabled: true

    IpcHandler {
        target: "desktopVisualizer"

        function toggle(): void {
            root.visualizerEnabled = !root.visualizerEnabled;
        }

        function status(): string {
            return root.visualizerEnabled ? "enabled" : "disabled";
        }
    }

    property var levels: []

    Process {
        running: root.visualizerEnabled
        command: ["cava", "-p", (Quickshell.env("XDG_CONFIG_HOME") || StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.config") + "/cava/wallpaper.conf"]

        stdout: SplitParser {
            onRead: frame => {
                const values = frame.trim().split(";");

                if (values.length < 96)
                    return;
                const next = [];

                for (let i = 0; i < 96; i++)
                    next.push(Math.max(0, Number(values[i]) || 0));

                root.levels = next;
            }
        }
    }

    PanelWindow {
        id: visualizer
        visible: root.visualizerEnabled

        screen: Quickshell.screens.find(s => s.name === Quickshell.env("VISUALIZER_OUTPUT")) || Quickshell.screens[0]
        WlrLayershell.namespace: "quickshell-cava-wallpaper"
        WlrLayershell.layer: WlrLayer.Bottom

        anchors {
            left: true
            right: true
            bottom: true
        }

        implicitHeight: 280
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        mask: Region {}

        Item {
            id: spectrum

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom

            width: parent.width
            height: 280
            clip: true
            property real barSpacing: 3

            Repeater {
                model: 96

                delegate: Rectangle {
                    id: bar
                    required property int index

                    width: Math.max(0, (spectrum.width - 95 * spectrum.barSpacing) / 96)

                    height: {
                        const raw = Math.sqrt(Math.max(0, root.levels[bar.index] || 0) / 1000) * 1.45;

                        const knee = 0.80;

                        const fraction = raw <= knee ? raw : knee + 0.14 * (1 - Math.exp(-(raw - knee) / 0.14));

                        return spectrum.height * fraction;
                    }

                    x: bar.index * (width + spectrum.barSpacing)
                    y: spectrum.height - height

                    color: "#FFFFFF"
                    opacity: 0.70
                    radius: 0
                }
            }
        }
    }
}
