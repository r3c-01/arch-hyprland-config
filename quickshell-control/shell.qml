import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

ShellRoot {
    id: root


    property bool barMonitorSession: Quickshell.env("QS_START_MONITOR") === "1"
    function closeMonitor() {
        if (root.barMonitorSession)
            Qt.quit();
        else
            root.detailsOpen = false;
    }
    // Allow the top-bar pulse icon to open the existing system monitor.
    IpcHandler {
        target: "barSystemMonitor"
        function open(): void {
            root.barMonitorSession = true;
            panel.tasksOpen = false
            panel.activityOpen = false
            panel.powerOpen = false
            root.detailsOpen = true
        }
    }
    // When Control Center was not already running, open directly on monitor.
    Timer {
        interval: 100
        repeat: false
        running: Quickshell.env("QS_START_MONITOR") === "1"
        onTriggered: {
            panel.tasksOpen = false
            panel.activityOpen = false
            panel.powerOpen = false
            root.detailsOpen = true
        }
    }
    property var metrics: ({})
    readonly property bool dashboardVisible: !panel.tasksOpen && !panel.activityOpen && !panel.powerOpen
    property bool detailsOpen: Quickshell.env("QS_START_MONITOR") === "1"
    property var cpuHistory: []
    property var gpuHistory: []
    property var memoryHistory: []
    property string hostName: "unknown"
    property string uptimeText: "Unavailable"
    property string kernelText: "Unavailable"

    function percent(value) {
        return value === null || value === undefined ? "—" : Math.round(value) + "%";
    }

    function temperature(value) {
        return value === null || value === undefined ? "Sensor unavailable" : value + "°C";
    }

    function capacity(value) {
        return value && value.used !== null && value.total !== null
            ? value.used + " / " + value.total + " GiB"
            : "Unavailable";
    }

    function pushHistory(propertyName, value) {
        if (value === null || value === undefined || value < 0)
            return;

        let next = root[propertyName].slice();
        next.push(Math.max(0, Math.min(100, Number(value) || 0)));

        while (next.length > 32)
            next.shift();

        root[propertyName] = next;
    }

    onDashboardVisibleChanged: sampler.running = dashboardVisible
    Component.onCompleted: sampler.running = dashboardVisible

    Process {
        id: sampler
        command: ["python3", Quickshell.shellDir + "/scripts/metrics.py"]

        stdout: SplitParser {
            onRead: line => {
                try {
                    const parsed = JSON.parse(line);
                    root.metrics = parsed;
                    root.pushHistory("cpuHistory", parsed.cpu);
                    root.pushHistory("gpuHistory", parsed.gpu?.percent);
                    root.pushHistory("memoryHistory", parsed.memory?.percent);
                } catch (error) {
                    console.warn("Metrics:", error);
                }
            }
        }

        onExited: (code, status) => {
            if (code !== 0)
                root.metrics = ({});
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.dashboardVisible
        onTriggered: if (!sampler.running) sampler.running = true
    }

    Process {
        id: systemInfoReader
        command: [
            "sh", "-c",
            "printf '%s|%s|%s' \"$(hostnamectl hostname 2>/dev/null || hostname)\" \"$(uptime -p 2>/dev/null | sed 's/^up //')\" \"$(uname -r)\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split("|");
                root.hostName = parts[0] || "unknown";
                root.uptimeText = parts[1] || "Unavailable";
                root.kernelText = parts[2] || "Unavailable";
            }
        }
    }

    Timer {
        interval: 30000
        repeat: true
        triggeredOnStart: true
        running: root.dashboardVisible && root.detailsOpen
        onTriggered: if (!systemInfoReader.running) systemInfoReader.running = true
    }

    PanelWindow {
        id: window

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.namespace: "custom-control-center"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (root.detailsOpen)
                    root.closeMonitor();
                else
                    Qt.quit();
            }
        }

        FocusScope {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: {
                if (root.detailsOpen)
                    root.closeMonitor();
                else
                    Qt.quit();
            }

            Rectangle {
                id: panel
                property bool tasksOpen: false
                property bool activityOpen: false
                property bool powerOpen: false

                width: Math.min(root.detailsOpen ? 1380 : 820, parent.width - 48)
                height: Math.min(
                    panel.powerOpen ? 500 :
                    panel.tasksOpen ? 520 :
                    panel.activityOpen ? 720 :
                    root.detailsOpen ? 690 : 700,
                    parent.height - 48
                )
                anchors.centerIn: parent
                radius: 0
                color: Qt.rgba(0.055, 0.059, 0.07, 0.70)
                border.color: "#414651"
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    onClicked: mouse => mouse.accepted = true
                }

                PowerOverlay {
                    anchors.fill: parent
                    anchors.margins: 10
                    visible: panel.powerOpen
                    z: 22
                    onCloseRequested: panel.powerOpen = false
                }

                ActivityOverlay {
                    anchors.fill: parent
                    anchors.margins: 10
                    visible: panel.activityOpen
                    z: 21
                    onCloseRequested: panel.activityOpen = false
                }

                TodoOverlay {
                    anchors.fill: parent
                    anchors.margins: 10
                    visible: panel.tasksOpen
                    z: 20
                    onCloseRequested: panel.tasksOpen = false
                }

                // Mutually exclusive dashboard page: not a translucent overlay
                // drawn on top of the main dashboard.
                SystemMonitorOverlay {
                    anchors.fill: parent
                    anchors.margins: 10
                    visible: root.detailsOpen && !panel.tasksOpen && !panel.activityOpen && !panel.powerOpen
                    z: 19
                    metrics: root.metrics
                    cpuHistory: root.cpuHistory
                    gpuHistory: root.gpuHistory
                    memoryHistory: root.memoryHistory
                    hostName: root.hostName
                    uptimeText: root.uptimeText
                    kernelText: root.kernelText
                    onCloseRequested: root.closeMonitor()
                }

                Flickable {
                    id: dashboardScroll
                    anchors.fill: parent
                    anchors.margins: 28
                    clip: true
                    contentHeight: dashboard.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                    visible: !panel.tasksOpen
                          && !panel.activityOpen
                          && !panel.powerOpen
                          && !root.detailsOpen

                    ColumnLayout {
                        id: dashboard
                        width: dashboardScroll.width
                        spacing: 18

                        RowLayout {
                            Layout.fillWidth: true

                            ColumnLayout {
                                spacing: 3

                                Text {
                                    text: "SYSTEM CONTROL"
                                    color: "#f0f0f2"
                                    font.pixelSize: 21
                                    font.bold: true
                                    font.letterSpacing: 2
                                }

                                Text {
                                    text: "ARCH LINUX  /  HYPRLAND"
                                    color: "#858b98"
                                    font.pixelSize: 11
                                    font.letterSpacing: 1.5
                                }
                            }

                            Item { Layout.fillWidth: true }

                            ControlButton {
                                Layout.preferredWidth: 76
                                Layout.preferredHeight: 30
                                text: "TASKS"
                                onClicked: panel.tasksOpen = true
                            }

                            ControlButton {
                                Layout.preferredWidth: 85
                                Layout.preferredHeight: 30
                                text: "ACTIVITY"
                                onClicked: {
                                    panel.tasksOpen = false;
                                    panel.activityOpen = true;
                                }
                            }

                            ControlButton {
                                Layout.preferredWidth: 75
                                Layout.preferredHeight: 30
                                text: "POWER"
                                onClicked: {
                                    panel.tasksOpen = false;
                                    panel.activityOpen = false;
                                    panel.powerOpen = true;
                                }
                            }

                            ControlButton {
                                text: "×"
                                Accessible.name: "Close control center"
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 30
                                onClicked: Qt.quit()
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: "#343943"
                        }

                        AudioControls {
                            Layout.fillWidth: true
                            Layout.preferredHeight: implicitHeight
                        }

                        NetworkControls {
                            Layout.fillWidth: true
                            Layout.preferredHeight: implicitHeight
                        }

                        GameModeControls {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 66
                        }

                        CaffeineControls {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 66
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 3
                            rowSpacing: 12
                            columnSpacing: 12

                            Repeater {
                                model: [
                                    ["CPU", root.percent(root.metrics.cpu), root.temperature(root.metrics.cpuTemperature), root.metrics.cpu ?? -1],
                                    ["GPU", root.percent(root.metrics.gpu?.percent), root.metrics.gpu?.name || "Unavailable", root.metrics.gpu?.percent ?? -1],
                                    ["MEMORY", root.percent(root.metrics.memory?.percent), root.capacity(root.metrics.memory), root.metrics.memory?.percent ?? -1]
                                ]

                                Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 104
                                    color: "#b8303034"
                                    radius: 0

                                    ControlButton {
                                        id: metricButton
                                        anchors.fill: parent
                                        text: ""
                                        Accessible.name: "Show system monitor for " + modelData[0]
                                        onClicked: root.detailsOpen = true
                                        background: Rectangle {
                                            color: "transparent"
                                            radius: 0
                                            border.color: metricButton.visualFocus ? "#c8cdd4" : "transparent"
                                        }
                                    }

                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 5

                                        Text {
                                            text: modelData[0]
                                            color: "#aeb8c6"
                                            font.pixelSize: 12
                                            font.bold: true
                                        }

                                        Text {
                                            text: modelData[1]
                                            color: "#f2f3f5"
                                            font.pixelSize: 19
                                            font.bold: true
                                            elide: Text.ElideRight
                                            width: parent.width
                                        }

                                        Text {
                                            text: modelData[2]
                                            color: "#939ba8"
                                            font.pixelSize: 12
                                        }

                                        Item {
                                            width: parent.width
                                            height: 1
                                        }

                                        Rectangle {
                                            visible: modelData[3] >= 0
                                            width: parent.width
                                            height: visible ? 3 : 0
                                            radius: 0
                                            color: "#60414a57"

                                            Rectangle {
                                                height: parent.height
                                                radius: 0
                                                color: "#c6ced9"
                                                width: parent.width * Math.max(0, Math.min(100, Number(modelData[3]) || 0)) / 100
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        ControlButton {
                            Layout.fillWidth: true
                            text: "OPEN SYSTEM MONITOR"
                            onClicked: root.detailsOpen = true
                        }
                    }
                }
            }
        }
    }
}
