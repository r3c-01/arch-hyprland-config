import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

ShellRoot {
    id: root

    // Always start disabled for safety.
    // Closing another Quickshell instance does not change this.
    property bool caffeineOn: false

    // Minimal mapped Wayland surface for idle inhibition.
    // The visible status indicator lives in the main Quickshell bar.
    PanelWindow {
        id: indicator

        visible: root.caffeineOn

        anchors {
            top: true
            right: true
        }

        margins {
            top: 0
            right: 0
        }

        implicitWidth: 1
        implicitHeight: 1

        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.namespace: "custom-caffeine"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    }

    // Native Wayland idle inhibition.
    // Never stops, restarts, or modifies hypridle.
    IdleInhibitor {
        window: indicator
        enabled: root.caffeineOn
    }

    // Dedicated IPC interface.
    IpcHandler {
        target: "caffeine"

        function enable(): void {
            root.caffeineOn = true;
        }

        function disable(): void {
            root.caffeineOn = false;
        }

        function toggle(): void {
            root.caffeineOn = !root.caffeineOn;
        }

        function status(): string {
            return root.caffeineOn ? "on" : "off";
        }
    }
}
