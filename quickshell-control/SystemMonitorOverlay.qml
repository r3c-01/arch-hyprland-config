import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Rectangle {
    id: monitor

    signal closeRequested()

    property var metrics: ({})
    property var cpuHistory: []
    property var gpuHistory: []
    property var memoryHistory: []
    property string hostName: "unknown"
    property string uptimeText: "Unavailable"
    property string kernelText: "Unavailable"
    property date currentTime: new Date()
    property int selectedTab: 0
    property var interfaces: []
    property var processRows: []
    property var rxHistory: []
    property var txHistory: []
    property string trackedInterface: ""
    property var networkDiagnostics: ({})
    property string processError: ""
    property bool stoppingDiagnostics: false
    property bool stoppingExtended: false
    property bool socketMode: selectedTab === 1 && networkAdvanced.section === 1
    onSocketModeChanged: { stoppingDiagnostics = true; networkDiagnosticsWorker.running = false; }
    onVisibleChanged: syncWorkers()
    onSelectedTabChanged: { syncWorkers(); stoppingExtended = true; extendedSampler.running = false; }
    function syncWorkers() {
        if (!visible || selectedTab !== 1) { stoppingDiagnostics = true; networkDiagnosticsWorker.running = false; }
        if (!visible) { stoppingExtended = true; extendedSampler.running = false; }
    }
    Timer {
        interval: 1000; repeat: true; running: monitor.visible; triggeredOnStart: true
        onTriggered: {
            if (monitor.selectedTab === 1 && !networkDiagnosticsWorker.running) { monitor.stoppingDiagnostics = false; networkDiagnosticsWorker.running = true; }
            if (!extendedSampler.running) { monitor.stoppingExtended = false; extendedSampler.running = true; }
        }
    }
    Process {
        id: networkDiagnosticsWorker
        stderr: StdioCollector { id: diagnosticsError }
        onExited: (code, status) => {
            if (code !== 0 && !monitor.stoppingDiagnostics && monitor.visible && monitor.selectedTab === 1)
                monitor.networkDiagnostics = ({socketError: "Network worker failed: " + diagnosticsError.text.trim()});
        }
        // Owned by the retry timer; stops on page/mode change.
        command: ["python3", Quickshell.shellDir + "/scripts/netdiag.py", "--stream"].concat(monitor.socketMode ? [] : ["--no-sockets"])
        stdout: SplitParser {
            onRead: line => {
                try {
                    const data = JSON.parse(line);
                    monitor.networkDiagnostics = data;
                } catch (e) { console.warn("Network diagnostics:", e); }
            }
        }
    }
    Process {
        id: extendedSampler
        stderr: StdioCollector { id: extendedError }
        onExited: (code, status) => {
            if (code !== 0 && !monitor.stoppingExtended && monitor.visible) {
                monitor.processRows = [];
                monitor.processError = "Telemetry worker failed: " + extendedError.text.trim();
            }
        }
        command: ["python3", Quickshell.shellDir + "/scripts/netproc.py"].concat(monitor.selectedTab === 1 ? ["--network-only"] : [])
        stdout: SplitParser {
            onRead: line => {
                try {
                    const data = JSON.parse(line);
                    monitor.interfaces = data.interfaces || [];
                    monitor.processRows = data.processes || [];
                    monitor.processError = data.processError || "";
                    const active = monitor.interfaces.find(x => x.name === monitor.trackedInterface) || monitor.interfaces[0];
                    if (active) {
                        if (monitor.trackedInterface !== active.name) {
                            monitor.trackedInterface = active.name;
                            monitor.rxHistory = [];
                            monitor.txHistory = [];
                        }
                        let rx = monitor.rxHistory.slice(), tx = monitor.txHistory.slice();
                        rx.push(active.rx); tx.push(active.tx);
                        monitor.rxHistory = rx.slice(-60); monitor.txHistory = tx.slice(-60);
                    }
                } catch(e) { console.warn("Extended telemetry:", e); }
            }
        }
    }

    function pct(value) {
        return value === null || value === undefined || value < 0 ? "--" : Math.round(Number(value)) + "%";
    }

    function temp(value) {
        return value === null || value === undefined ? "--" : Math.round(Number(value)) + "°C";
    }

    function cap(value) {
        return value && value.used !== null && value.total !== null
            ? value.used + " / " + value.total + " GiB"
            : "Unavailable";
    }

    function tone(value) {
        if (value === null || value === undefined) return "#c6ced9";
        value = Number(value);
        return "#c6ced9";
    }

    function tempTone(value) {
        if (value === null || value === undefined) return "#c6ced9";
        value = Number(value);
        return "#c6ced9";
    }

    // The containing control-center panel already provides 70% dark glass.
    // A second 70% background here stacks to ~91% opacity and kills the blur.
    color: "transparent"
    radius: 0
    border.color: "#565b64"
    border.width: 1
    clip: true

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: 1
        border.color: "#40515b68"
        radius: 0
        anchors.margins: 8
    }

    Item {
        anchors.fill: parent
        anchors.margins: 24

        ColumnLayout {
            anchors.fill: parent
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    spacing: 2
                    Text {
                        text: "SYS.MONITOR"
                        color: "#f0f0f2"
                        font.pixelSize: 23
                        font.bold: true
                        font.letterSpacing: 2.4
                    }
                    Text {
                        text: "LIVE TELEMETRY // " + hostName.toUpperCase() + " // KERNEL " + kernelText
                        color: "#abb1bc"
                        font.pixelSize: 11
                        font.letterSpacing: 1.5
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    id: clockPanel
                    Layout.preferredWidth: 244
                    Layout.minimumWidth: 244
                    Layout.preferredHeight: 48
                    radius: 0
                    color: "#85303034"
                    border.width: 1
                    border.color: "#505762"
                    clip: true

                    Column {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        anchors.topMargin: 5
                        anchors.bottomMargin: 5
                        spacing: 3

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignRight
                            text: Qt.formatTime(monitor.currentTime, "hh:mm:ss")
                            color: "#f0f0f2"
                            font.pixelSize: 16
                            font.bold: true
                            font.family: "monospace"
                        }
                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignRight
                            text: "UPTIME  " + uptimeText.toUpperCase()
                            color: "#a0a5af"
                            font.pixelSize: 9
                            font.family: "monospace"
                            elide: Text.ElideLeft
                            maximumLineCount: 1
                        }
                    }

                    Timer {
                        interval: 1000
                        repeat: true
                        running: monitor.visible
                        triggeredOnStart: true
                        onTriggered: monitor.currentTime = new Date()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 96
                    Layout.preferredHeight: 44
                    radius: 0
                    color: "#85303034"
                    border.width: 1
                    border.color: "#40515b68"

                    Text {
                        anchors.centerIn: parent
                        text: "RETURN"
                        color: "#f0f0f2"
                        font.bold: true
                        font.pixelSize: 11
                        font.letterSpacing: 1.5
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: monitor.closeRequested()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "#414651"
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Repeater {
                    model: ["OVERVIEW", "NETWORK", "PROCESSES"]
                    delegate: Rectangle {
                        required property int index
                        required property string modelData
                        Layout.preferredWidth: 130; Layout.preferredHeight: 34
                        color: monitor.selectedTab === index ? "#ab515158" : "#85303034"
                        border.color: "#565b64"; radius: 0
                        Text { anchors.centerIn: parent; text: modelData; color: "#f0f0f2"; font.bold: true; font.pixelSize: 11 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: monitor.selectedTab = index }
                    }
                }
                Item { Layout.fillWidth: true }
                // Network context shares the primary navigation row.
                Repeater {
                    model: monitor.selectedTab === 1 ? ["TRAFFIC", "SOCKETS", "DIAGNOSTICS"] : []
                    delegate: Rectangle {
                        required property int index
                        required property string modelData
                        Layout.preferredWidth: 110; Layout.preferredHeight: 34
                        color: networkAdvanced.section === index ? "#ab515158" : "#85303034"
                        border.color: "#565b64"; radius: 0
                        Text { anchors.centerIn: parent; text: modelData; color: "#f0f0f2"; font.bold: true; font.pixelSize: 11 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: networkAdvanced.section = index }
                    }
                }
            }
            NetworkMonitorPage {
                id: networkAdvanced
                Layout.fillWidth: true; Layout.fillHeight: true
                diagnostics: monitor.networkDiagnostics
                visible: monitor.selectedTab === 1
                interfaces: monitor.interfaces
                chosen: monitor.trackedInterface
                onInterfaceRequested: name => {
                    monitor.trackedInterface = name;
                    monitor.rxHistory = [];
                    monitor.txHistory = [];
                }
                rxHistory: monitor.rxHistory
                txHistory: monitor.txHistory
            }
            ProcessManagerPage {
                Layout.fillWidth: true; Layout.fillHeight: true
                visible: monitor.selectedTab === 2
                processes: monitor.processRows
                telemetryError: monitor.processError
            }
            RowLayout {
                visible: monitor.selectedTab === 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 14

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 300
                    Layout.fillHeight: true
                    spacing: 14

                    Repeater {
                        model: [
                            { title: "CPU CORE LOAD", type: "cpu" },
                            { title: "GPU VECTOR UNIT", type: "gpu" },
                            { title: "MEMORY FABRIC", type: "memory" }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            readonly property real level: modelData.type === "cpu"
                                ? (monitor.metrics.cpu ?? -1)
                                : modelData.type === "gpu"
                                    ? (monitor.metrics.gpu?.percent ?? -1)
                                    : (monitor.metrics.memory?.percent ?? -1)
                            readonly property var history: modelData.type === "cpu"
                                ? monitor.cpuHistory
                                : modelData.type === "gpu"
                                    ? monitor.gpuHistory
                                    : monitor.memoryHistory
                            readonly property string valueText: monitor.pct(level < 0 ? null : level)
                            readonly property string auxText: modelData.type === "cpu"
                                ? "TEMP // " + monitor.temp(monitor.metrics.cpuTemperature)
                                : modelData.type === "gpu"
                                    ? (monitor.metrics.gpu?.name || "NO DISCRETE GPU") + " // TEMP " + monitor.temp(monitor.metrics.gpu?.temperature)
                                    : "CAPACITY // " + monitor.cap(monitor.metrics.memory)
                            readonly property color metricTone: monitor.tone(level < 0 ? null : level)
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredHeight: 0
                            Layout.minimumHeight: 0
                            color: "#85303034"
                            radius: 0
                            border.width: 1
                            border.color: "#414651"

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                RowLayout {
                                    Layout.fillWidth: true

                                    ColumnLayout {
                                        spacing: 2
                                        Text {
                                            text: modelData.title
                                            color: "#f0f0f2"
                                            font.pixelSize: 14
                                            font.bold: true
                                            font.letterSpacing: 1.4
                                        }
                                        Text {
                                            text: auxText
                                            color: "#aeb8c6"
                                            font.pixelSize: 10
                                            font.letterSpacing: 1.1
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    Rectangle {
                                        Layout.preferredWidth: 96
                                        Layout.preferredHeight: 40
                                        color: "#a8303034"
                                        radius: 0
                                        border.width: 1
                                        border.color: metricTone

                                        Text {
                                            anchors.centerIn: parent
                                            text: valueText
                                            color: metricTone
                                            font.pixelSize: 19
                                            font.bold: true
                                            font.family: "monospace"
                                        }
                                    }
                                }

                                Canvas {
                                    id: graph
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    antialiasing: true

                                    onWidthChanged: requestPaint()
                                    onHeightChanged: requestPaint()

                                    Connections {
                                        target: monitor
                                        function onCpuHistoryChanged() {
                                            if (modelData.type === "cpu") graph.requestPaint();
                                        }
                                        function onGpuHistoryChanged() {
                                            if (modelData.type === "gpu") graph.requestPaint();
                                        }
                                        function onMemoryHistoryChanged() {
                                            if (modelData.type === "memory") graph.requestPaint();
                                        }
                                    }

                                    onPaint: {
                                        var ctx = getContext("2d");
                                        if (ctx.reset) ctx.reset();
                                        ctx.clearRect(0, 0, width, height);

                                        ctx.strokeStyle = "#414651";
                                        ctx.lineWidth = 1;
                                        for (var i = 1; i < 4; ++i) {
                                            var y = (height / 4) * i;
                                            ctx.beginPath();
                                            ctx.moveTo(0, y);
                                            ctx.lineTo(width, y);
                                            ctx.stroke();
                                        }

                                        var data = history || [];
                                        if (!data.length) return;

                                        ctx.strokeStyle = metricTone;
                                        ctx.lineWidth = 2;
                                        ctx.beginPath();
                                        for (var j = 0; j < data.length; ++j) {
                                            var value = Math.max(0, Math.min(100, Number(data[j]) || 0));
                                            var x = data.length === 1 ? 0 : j * (width / (data.length - 1));
                                            var y2 = height - (value / 100) * height;
                                            if (j === 0) ctx.moveTo(x, y2);
                                            else ctx.lineTo(x, y2);
                                        }
                                        ctx.stroke();

                                        ctx.fillStyle = "rgba(198,206,217,0.10)";
                                        ctx.lineTo(width, height);
                                        ctx.lineTo(0, height);
                                        ctx.closePath();
                                        ctx.fill();
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 10
                                    radius: 0
                                    color: "#a8303034"
                                    border.width: 1
                                    border.color: "#414651"

                                    Rectangle {
                                        width: parent.width * Math.max(0, Math.min(100, Number(level) || 0)) / 100
                                        height: parent.height
                                        radius: 0
                                        color: metricTone
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.preferredWidth: 360
                    Layout.minimumWidth: 340
                    Layout.fillHeight: true
                    spacing: 14

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 260
                        color: "#85303034"
                        radius: 0
                        border.width: 1
                        border.color: "#414651"

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 10

                            Text {
                                text: "HOST // SYS.FETCH"
                                color: "#f0f0f2"
                                font.pixelSize: 14
                                font.bold: true
                                font.letterSpacing: 1.4
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                                color: "#414651"
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 10

                                // Center the logo + metrics as one compact group.
                                // Do not stretch the metric values to the panel's far edge.
                                Item { Layout.fillWidth: true }

                                Item {
                                    Layout.preferredWidth: 365
                                    Layout.minimumWidth: 365
                                    Layout.fillHeight: true

                                    Text {
                                        anchors.centerIn: parent
                                        text: "ARCH LINUX"
                                        color: "#eeeeee"
                                        font.pixelSize: 40
                                        font.bold: true
                                    }
                                }

                                ColumnLayout {
                                    Layout.preferredWidth: 180
                                    Layout.minimumWidth: 180
                                    Layout.fillHeight: true
                                    spacing: 2

                                    Repeater {
                                        model: [
                                            ["KERNEL", monitor.kernelText],
                                            ["UPTIME", monitor.uptimeText],
                                            ["CPU", monitor.pct(monitor.metrics.cpu)],
                                            ["GPU", monitor.metrics.gpu?.name || "Unavailable"],
                                            ["MEM", monitor.cap(monitor.metrics.memory)],
                                            ["DISK", monitor.cap(monitor.metrics.disk)],
                                            ["CPU °C", monitor.temp(monitor.metrics.cpuTemperature)],
                                            ["GPU °C", monitor.temp(monitor.metrics.gpu?.temperature)]
                                        ]
                                        delegate: RowLayout {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            spacing: 6

                                            Text {
                                                text: modelData[0]
                                                color: "#aeb8c6"
                                                font.pixelSize: 12
                                                font.family: "monospace"
                                                Layout.preferredWidth: 56
                                            }

                                            Text {
                                                text: modelData[1]
                                                color: "#f0f0f2"
                                                font.pixelSize: 12
                                                font.family: "monospace"
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                                horizontalAlignment: Text.AlignRight
                                            }
                                        }
                                    }
                                }

                                Item { Layout.fillWidth: true }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#85303034"
                        radius: 0
                        border.width: 1
                        border.color: "#414651"

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 10

                            Text {
                                text: "TOP PROCESSES // CPU / MEM / RSS"
                                color: "#f0f0f2"
                                font.pixelSize: 12
                                font.bold: true
                                font.letterSpacing: 0.5
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: "#a8303034"
                                radius: 0
                                border.width: 1
                                border.color: "#414651"
                                clip: true

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 0

                                    // Four real columns, rather than a fixed-width ps text blob.
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 22
                                        spacing: 8

                                        Text {
                                            text: "PROCESS"
                                            Layout.fillWidth: true
                                            color: "#aeb8c6"
                                            font.family: "monospace"
                                            font.pixelSize: 10
                                            font.bold: true
                                        }
                                        Repeater {
                                            model: ["CPU%", "MEM%", "RSS(MiB)"]
                                            delegate: Text {
                                                required property string modelData
                                                text: modelData
                                                Layout.preferredWidth: modelData === "RSS(MiB)" ? 67 : 45
                                                horizontalAlignment: Text.AlignRight
                                                color: "#aeb8c6"
                                                font.family: "monospace"
                                                font.pixelSize: 10
                                                font.bold: true
                                            }
                                        }
                                    }

                                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#414651" }

                                    Repeater {
                                        model: monitor.processRows.slice(0, 6)
                                        delegate: ColumnLayout {
                                            required property var modelData
                                            required property int index
                                            Layout.fillWidth: true
                                            spacing: 0

                                            RowLayout {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 20
                                                spacing: 8

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: modelData.name || "--"
                                                    elide: Text.ElideRight
                                                    color: index === 0 ? "#f0f0f2" : "#c4cad4"
                                                    font.family: "monospace"
                                                    font.pixelSize: 11
                                                }
                                                Text {
                                                    Layout.preferredWidth: 45
                                                    horizontalAlignment: Text.AlignRight
                                                    text: Number(modelData.cpu ?? 0).toFixed(1)
                                                    color: "#c4cad4"
                                                    font.family: "monospace"
                                                    font.pixelSize: 11
                                                }
                                                Text {
                                                    Layout.preferredWidth: 45
                                                    horizontalAlignment: Text.AlignRight
                                                    text: Number(modelData.mem ?? 0).toFixed(1)
                                                    color: "#c4cad4"
                                                    font.family: "monospace"
                                                    font.pixelSize: 11
                                                }
                                                Text {
                                                    Layout.preferredWidth: 67
                                                    horizontalAlignment: Text.AlignRight
                                                    text: String(modelData.rss ?? "--")
                                                    color: "#c4cad4"
                                                    font.family: "monospace"
                                                    font.pixelSize: 11
                                                }
                                            }
                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 1
                                                color: "#32414651"
                                            }
                                        }
                                    }
                                    Item { Layout.fillHeight: true }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
