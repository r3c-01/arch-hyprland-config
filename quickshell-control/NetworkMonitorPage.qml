import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Io

Item {
    id: page
    property var interfaces: []
    property var rxHistory: []
    property var txHistory: []
    property string chosen: ""
    signal interfaceRequested(string name)
    property var available: interfaces.map(x => x.name)
    property var diagnostics: ({})
    property var probeData: ({})
    property string publicIp: "Not requested"
    property bool probesEnabled: false
    property int section: 0
    property string socketFilter: ""
    property string stateFilter: "ALL"
    property var latencyHistory: []
    property int maxRows: 120
    property var selectedSocket: null
    property int diagnosticTool: 0
    property string lookupTarget: "example.com"
    property string lookupType: "A"
    property string traceTarget: "1.1.1.1"
    property string dnsOutput: "Select a record type and run a lookup."
    property string traceOutput: "Enter a destination and run a trace."
    property bool dnsBusy: false
    property bool traceBusy: false
    readonly property bool healthActive: visible && section === 2 && diagnosticTool === 0
    readonly property bool dnsActive: visible && section === 2 && diagnosticTool === 1
    readonly property bool traceActive: visible && section === 2 && diagnosticTool === 2
    readonly property string inspectorHost: endpointHost(selectedSocket?.remote)
    readonly property bool canInspect: !!selectedSocket && inspectorHost !== "" && inspectorHost !== "*" && inspectorHost !== "0.0.0.0" && inspectorHost !== "::"
    property bool socketStale: false
    onDiagnosticsChanged: {
        if (section !== 1 || !selectedSocket) return;
        const row = (diagnostics.sockets || []).find(x => x.protocol === selectedSocket.protocol && x.local === selectedSocket.local && x.remote === selectedSocket.remote && x.pid === selectedSocket.pid);
        socketStale = !row;
        if (row) selectedSocket = row;
    }
    onSelectedSocketChanged: socketStale = false
    onHealthActiveChanged: if (!healthActive) { probeProcess.running = false; if (publicIpProcess.running) page.publicIp = "Cancelled"; publicIpProcess.running = false; }
    onDnsActiveChanged: if (!dnsActive && dnsToolProcess.running) { dnsOutput = "Cancelled on leaving DNS lookup."; dnsToolProcess.running = false; }
    onTraceActiveChanged: if (!traceActive && traceToolProcess.running) { traceOutput = "Cancelled on leaving Trace Route."; traceToolProcess.running = false; }
    function toolOutput(result) {
        return "STATUS: " + (result.status || (result.ok ? "OK" : "ERROR"))
            + (result.tool ? "  TOOL: " + result.tool : "")
            + (result.query ? "\nQUERY: " + result.query + (result.recordType ? " / " + result.recordType : "") : "")
            + (result.elapsedMs !== undefined ? "  TIME: " + result.elapsedMs + " ms" : "")
            + "\n" + result.result;
    }

    function rate(value) {
        if (value === undefined || value === null || isNaN(value)) return "—";
        let n = Number(value);
        let units = ["B/s", "KiB/s", "MiB/s", "GiB/s"];
        let i = 0;
        while (Math.abs(n) >= 1024 && i < 3) { n /= 1024; i++; }
        return n.toFixed(i ? 1 : 0) + " " + units[i];
    }
    function bytes(value) { return rate(value).replace('/s', ''); }
    function endpointHost(endpoint) {
        if (!endpoint || endpoint === "*" || endpoint === "*:*" || endpoint === "—") return "";
        if (endpoint.startsWith("[") && endpoint.includes("]:")) return endpoint.slice(1, endpoint.lastIndexOf("]:"));
        let cut = endpoint.lastIndexOf(":");
        return cut > 0 ? endpoint.slice(0, cut) : endpoint;
    }
    function latency(value) { return value === null || value === undefined ? "—" : Number(value).toFixed(1) + " ms"; }
    readonly property var active: interfaces.find(x => x.name === chosen) || interfaces[0] || ({rx:0,tx:0,name:"none"})
    readonly property var interfaceInfo: (diagnostics.interfaces || []).find(x => x.name === active.name) || ({})
    readonly property var sockets: diagnostics.sockets || []
    readonly property var filteredSockets: sockets.filter(x => {
        if (stateFilter !== "ALL" && x.state !== stateFilter) return false;
        let needle = socketFilter.toLowerCase().trim();
        if (!needle) return true;
        return [x.protocol,x.state,x.local,x.remote,x.remoteName || "",x.process,x.pid].join(" ").toLowerCase().includes(needle);
    }).slice(0, maxRows)
    property int textSize: 11
    property color muted: "#abb1bc"
    property color bright: "#f0f0f2"
    property color edge: "#414651"
    property color surface: "#85303034"

    Process {
        id: probeProcess
        command: ["python3", Quickshell.shellDir + "/scripts/netdiag.py", "--probe"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (!page.healthActive) return;
                    let parsed = JSON.parse(this.text);
                    page.probeData = parsed;
                    if (parsed.wan && parsed.wan.latencyMs !== null) {
                        let hist = page.latencyHistory.slice();
                        hist.push(parsed.wan.latencyMs);
                        page.latencyHistory = hist.slice(-40);
                    }
                } catch(e) { page.probeData = ({wan:{status:"worker error"},gateway:{status:"worker error"},dnsProbe:{status:"worker error"}}); console.warn("Network probe:", e); }
            }
        }
    }
    Timer {
        interval: 15000
        running: page.healthActive && page.probesEnabled
        repeat: true
        triggeredOnStart: true
        onTriggered: { if (!probeProcess.running) probeProcess.running = true; }
    }
    Process {
        id: publicIpProcess
        command: ["python3", Quickshell.shellDir + "/scripts/netdiag.py", "--public-ip"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { if (page.healthActive) page.publicIp = JSON.parse(this.text).value || "Unavailable"; }
                catch(e) { page.publicIp = "Unavailable"; }
            }
        }
    }
    // User-initiated tools; never run on page open or refresh.
    Process {
        id: dnsToolProcess
        command: ["python3", Quickshell.shellDir + "/scripts/nettool.py", "--dns", page.lookupTarget, "--type", page.lookupType]
        onRunningChanged: page.dnsBusy = running
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (!page.dnsActive || !this.text.trim()) return;
                    let result = JSON.parse(this.text);
                    page.dnsOutput = page.toolOutput(result);
                } catch(e) { page.dnsOutput = "DNS tool returned invalid data: " + e; }
            }
        }
    }
    Process {
        id: traceToolProcess
        command: ["python3", Quickshell.shellDir + "/scripts/nettool.py", "--trace", page.traceTarget]
        onRunningChanged: page.traceBusy = running
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (!page.traceActive || !this.text.trim()) return;
                    let result = JSON.parse(this.text);
                    page.traceOutput = page.toolOutput(result);
                } catch(e) { page.traceOutput = "Route tool returned invalid data: " + e; }
            }
        }
    }
    Timer {
        interval: 1000; repeat: true; running: page.visible
        property int dnsTicks: 0
        property int traceTicks: 0
        property int probeTicks: 0
        property int ipTicks: 0
        onTriggered: {
            if (!dnsToolProcess.running && page.dnsOutput === "Querying...") page.dnsOutput = "DNS worker failed to start or returned no output.";
            if (!traceToolProcess.running && page.traceOutput === "Tracing route...") page.traceOutput = "Route worker failed to start or returned no output.";
            if (!publicIpProcess.running && page.publicIp === "Querying...") page.publicIp = "Worker unavailable";
            dnsTicks = dnsToolProcess.running ? dnsTicks + 1 : 0;
            traceTicks = traceToolProcess.running ? traceTicks + 1 : 0;
            probeTicks = probeProcess.running ? probeTicks + 1 : 0;
            ipTicks = publicIpProcess.running ? ipTicks + 1 : 0;
            if (dnsTicks > 8) { dnsToolProcess.running = false; page.dnsOutput = "DNS worker exceeded 8 seconds."; }
            if (traceTicks > 22) { traceToolProcess.running = false; page.traceOutput = "Route worker exceeded 22 seconds."; }
            if (probeTicks > 16) { probeProcess.running = false; page.probeData = ({wan:{status:"timeout"},dnsProbe:{status:"timeout"}}); }
            if (ipTicks > 7) { publicIpProcess.running = false; page.publicIp = "Timed out"; }
        }
    }
    component Label: Text {
        font.family: "monospace"
        font.pixelSize: page.textSize
        color: page.muted
        elide: Text.ElideRight
    }
    component Value: Text {
        font.family: "monospace"
        font.pixelSize: page.textSize + 1
        color: page.bright
        elide: Text.ElideRight
    }
    component Panel: Rectangle {
        radius: 0
        color: page.surface
        border.width: 1
        border.color: page.edge
    }
    component Readout: Item {
        property string heading: ""
        property string value: ""
        property string detail: ""
        Layout.fillWidth: true
        Layout.preferredHeight: 85
        Panel { anchors.fill: parent }
        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 7
            Label { text: heading; font.bold: true }
            Value { text: value; font.pixelSize: 20; font.bold: true }
            Label { text: detail; font.pixelSize: 10 }
        }
    }
    component InfoLine: RowLayout {
        property string heading: ""
        property string value: ""
        Layout.fillWidth: true
        spacing: 8
        Label { text: heading; Layout.preferredWidth: 90 }
        Value { text: value; Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft }
    }
    component Tab: Rectangle {
        property int minimumWidth: 95
        property string caption: ""
        property bool selected: false
        signal activated()
        width: Math.max(minimumWidth, captionText.implicitWidth + 22)
        height: 28
        radius: 0
        opacity: enabled ? 1 : 0.4
        color: selected ? "#555962" : "#303034"
        border.width: 1
        border.color: "#565b64"
        Label { id: captionText; anchors.centerIn: parent; text: caption; color: page.bright; font.bold: true }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: activated() }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 9
        RowLayout {
            Layout.fillWidth: true
            Label { text: "NETWORK / " + ["TRAFFIC", "SOCKETS", "DIAGNOSTICS"][page.section]; color: page.bright; font.pixelSize: 15; font.bold: true; font.letterSpacing: 1 }
            Item { Layout.fillWidth: true }
            Label { text: "IFACE  " + page.active.name.toUpperCase() }
        }
        // Top-level overview: throughput, history, local identity.
        ColumnLayout {
            visible: page.section === 0
            Layout.fillWidth: true; Layout.fillHeight: true
            spacing: 8
            RowLayout {
                spacing: 5
                Repeater {
                    model: page.available
                    delegate: Tab {
                        required property string modelData
                        caption: modelData
                        selected: page.active.name === modelData
                        onActivated: page.interfaceRequested(modelData)
                    }
                }
                Item { Layout.fillWidth: true }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 8
                Readout { heading: "DOWNLOAD / RX"; value: page.rate(page.active.rx); detail: "TOTAL  " + page.bytes(page.interfaceInfo.totalRx) }
                Readout { heading: "UPLOAD / TX"; value: page.rate(page.active.tx); detail: "TOTAL  " + page.bytes(page.interfaceInfo.totalTx) }
            }
            Panel {
                Layout.fillWidth: true; Layout.fillHeight: true
                Layout.minimumHeight: 105
                Label { anchors.left: parent.left; anchors.top: parent.top; anchors.margins: 10; text: "TRAFFIC HISTORY / RX —  TX - - -"; color: page.bright; font.bold: true }
                Label { anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 10; text: "SCALE " + page.rate(Math.max(1024,...page.rxHistory,...page.txHistory)); font.pixelSize: 10 }
                Canvas {
                    id: trafficPlot
                    anchors.fill: parent
                    anchors.margins: 12
                    anchors.topMargin: 32
                    onPaint: {
                        let ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
                        ctx.lineWidth = 1; ctx.strokeStyle = "#414651";
                        for (let i = 1; i < 4; i++) {
                            let y = height * i / 4;
                            ctx.beginPath(); ctx.moveTo(0,y); ctx.lineTo(width,y); ctx.stroke();
                        }
                        const rx = page.rxHistory, tx = page.txHistory;
                        let max = Math.max(1024,...rx,...tx) * 1.1;
                        function draw(arr, dashed) {
                            ctx.beginPath();ctx.strokeStyle = dashed ? "#9ca0a8" : "#e2e7ed";
                            ctx.lineWidth=1.8;ctx.setLineDash(dashed ? [5,4] : []);
                            for(let i=0;i<arr.length;i++) {
                                let x=arr.length===1 ? 0 : i*width/(arr.length-1);
                                let y=height*(1-arr[i]/max);
                                if(i===0)ctx.moveTo(x,y);else ctx.lineTo(x,y);
                            }
                            ctx.stroke();ctx.setLineDash([]);
                        }
                        draw(rx,false);draw(tx,true);
                    }
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                    Connections {
                        target: page
                        function onRxHistoryChanged() { trafficPlot.requestPaint(); }
                        function onTxHistoryChanged() { trafficPlot.requestPaint(); }
                    }
                }
            }
            Panel {
                Layout.fillWidth: true; Layout.preferredHeight: 115
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 10; spacing: 4
                    Label { text: "INTERFACE / IDENTITY"; color: page.bright; font.bold: true }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 18
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 3
                            InfoLine { heading: "STATE"; value: page.interfaceInfo.state || "—" }
                            InfoLine { heading: "IPv4"; value: page.interfaceInfo.ipv4 || "—" }
                            InfoLine { heading: "IPv6"; value: page.interfaceInfo.ipv6 || "—" }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 3
                            InfoLine { heading: "LINK"; value: page.interfaceInfo.speed ? page.interfaceInfo.speed + " Mb/s" : "—" }
                            InfoLine { heading: "GATEWAY"; value: page.diagnostics.gateway || "—" }
                            InfoLine { heading: "DNS"; value: (page.diagnostics.dns || []).join(", ") || "—" }
                        }
                    }
                }
            }
        }
        // Sockets: passive local ss output, never kills or alters processes.
        ColumnLayout {
            visible: page.section === 1
            Layout.fillWidth: true; Layout.fillHeight: true
            spacing: 8
            RowLayout {
                Layout.fillWidth: true
                Panel {
                    Layout.fillWidth: true; Layout.preferredHeight: 32
                    TextInput {
                        clip: true
                        selectByMouse: true
                        id: socketSearch
                        anchors.fill: parent; anchors.margins: 8
                        color: page.bright; font.pixelSize: 11; font.family: "monospace"
                        text: page.socketFilter
                        onTextChanged: page.socketFilter = text
                        Text { anchors.fill: parent; visible: !socketSearch.text && !socketSearch.activeFocus; text: "Filter address, process, PID, port..."; color: "#9298a2"; font.pixelSize: 11 }
                    }
                }
                Tab { caption: "ALL"; selected: page.stateFilter === "ALL"; onActivated: page.stateFilter = "ALL" }
                Tab { caption: "ESTAB"; selected: page.stateFilter === "ESTAB"; onActivated: page.stateFilter = "ESTAB" }
                Tab { caption: "LISTEN"; selected: page.stateFilter === "LISTEN"; onActivated: page.stateFilter = "LISTEN" }
            }
            Panel {
                Layout.fillWidth: true; Layout.fillHeight: true
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 8; spacing: 2
                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        Label { text: "PROTO"; Layout.preferredWidth: 38; font.bold: true }
                        Label { text: "STATE"; Layout.preferredWidth: 52; font.bold: true }
                        Label { text: "LOCAL"; Layout.fillWidth: true; Layout.preferredWidth: 170; font.bold: true }
                        Label { text: "REMOTE / HOSTNAME"; Layout.fillWidth: true; Layout.preferredWidth: 260; font.bold: true }
                        Label { text: "PROCESS / PID"; Layout.preferredWidth: 120; font.bold: true }
                    }
                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: page.edge }
                    ListView {
                        id: socketList
                        Layout.fillWidth: true; Layout.fillHeight: true
                        clip: true
                        model: page.filteredSockets
                        spacing: 1
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: socketList.width; height: 32
                            color: page.selectedSocket && page.selectedSocket.local === modelData.local && page.selectedSocket.remote === modelData.remote && page.selectedSocket.protocol === modelData.protocol && page.selectedSocket.pid === modelData.pid ? "#50545c" : (index % 2 === 0 ? "#28303438" : "transparent")
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: page.selectedSocket = modelData }
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 3; anchors.rightMargin: 3; spacing: 8
                                Label { text: modelData.protocol; Layout.preferredWidth: 38 }
                                Label { text: modelData.state; Layout.preferredWidth: 52 }
                                Value { text: modelData.local; Layout.fillWidth: true; Layout.preferredWidth: 170 }
                                ColumnLayout {
                                    Layout.fillWidth: true; Layout.preferredWidth: 260
                                    spacing: 0
                                    Value { Layout.fillWidth: true; text: modelData.remoteName || modelData.remote; font.pixelSize: 11 }
                                    Label { Layout.fillWidth: true; text: modelData.remoteName ? modelData.remote : ""; font.pixelSize: 9; visible: !!modelData.remoteName }
                                }
                                Label { text: modelData.process + " / " + modelData.pid; Layout.preferredWidth: 120 }
                            }
                        }
                    }
                    Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: page.edge }
                    ColumnLayout {
                        Layout.fillWidth: true; Layout.preferredHeight: 126; spacing: 4
                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: "SOCKET INSPECTOR / CLICK A ROW"; color: page.bright; font.bold: true; font.pixelSize: 12 }
                            Item { Layout.fillWidth: true }
                            Tab { caption: "DNS"; enabled: page.canInspect; minimumWidth: 48; onActivated: { let host = page.endpointHost(page.selectedSocket?.remote); if (host) { page.lookupTarget = host; page.lookupType = "PTR"; page.section = 2; page.diagnosticTool = 1; } } }
                            Tab { caption: "TRACE"; enabled: page.canInspect; minimumWidth: 55; onActivated: { let host = page.endpointHost(page.selectedSocket?.remote); if (host) { page.traceTarget = host; page.section = 2; page.diagnosticTool = 2; } } }
                            Tab { caption: "CLEAR"; enabled: !!page.selectedSocket; minimumWidth: 55; onActivated: page.selectedSocket = null }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                Layout.fillWidth: true
                                InfoLine { heading: "PROCESS"; value: page.selectedSocket ? (page.selectedSocket.pid === "—" ? "Process details unavailable" : page.selectedSocket.process + " / PID " + page.selectedSocket.pid) : "Select a socket" }
                                InfoLine { heading: "PROTOCOL"; value: page.selectedSocket ? page.selectedSocket.protocol + " / " + page.selectedSocket.state : "—" }
                                InfoLine { heading: "LOCAL"; value: page.selectedSocket ? page.selectedSocket.local : "—" }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                InfoLine { heading: "REMOTE"; value: page.selectedSocket ? page.selectedSocket.remote : "—" }
                                InfoLine { heading: "HOSTNAME"; value: page.selectedSocket ? (page.selectedSocket.remoteName || "Not resolved") : "—" }
                                Label { text: page.socketStale ? "SOCKET CLOSED / LAST SNAPSHOT" : "DETAILS ARE READ-ONLY"; font.pixelSize: 9 }
                            }
                        }
                    }
                }
            }
            Label { Layout.fillWidth: true; text: page.diagnostics.socketError || (page.filteredSockets.length + " displayed / " + page.sockets.length + " sampled  •  reverse DNS may query your DNS resolver  •  process names may require permissions"); font.pixelSize: 10 }
        }
        // Diagnostics: probes never run until user turns them on.
        ColumnLayout {
            visible: page.section === 2
            Layout.fillWidth: true; Layout.fillHeight: true
            spacing: 9
            RowLayout {
                Layout.fillWidth: true
            Controls.ComboBox {
                id: diagnosticSelector
                Layout.preferredWidth: 164
                Layout.preferredHeight: 28
                model: ["HEALTH", "DNS LOOKUP", "TRACE ROUTE"]
                currentIndex: page.diagnosticTool
                onActivated: index => page.diagnosticTool = index
                font.family: "monospace"
                font.pixelSize: page.textSize
                font.bold: true
                leftPadding: 10
                rightPadding: 28
                background: Rectangle {
                    color: "#303034"
                    border.color: diagnosticSelector.activeFocus ? page.bright : "#565b64"
                }
                contentItem: Text {
                    text: diagnosticSelector.displayText
                    font: diagnosticSelector.font
                    color: page.bright
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                indicator: Text {
                    x: diagnosticSelector.width - width - 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: "▾"
                    color: page.bright
                    font.pixelSize: 14
                }
                delegate: Controls.ItemDelegate {
                    required property int index
                    required property string modelData
                    width: diagnosticSelector.width - 2
                    height: 28
                    highlighted: diagnosticSelector.highlightedIndex === index
                    background: Rectangle { color: highlighted ? "#555962" : "#303034" }
                    contentItem: Text {
                        text: modelData
                        font: diagnosticSelector.font
                        color: page.bright
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                popup: Controls.Popup {
                    y: diagnosticSelector.height + 2
                    width: diagnosticSelector.width
                    padding: 1
                    implicitHeight: contentItem.implicitHeight + 2
                    background: Rectangle { color: "#303034"; border.color: "#565b64" }
                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: diagnosticSelector.popup.visible ? diagnosticSelector.delegateModel : null
                        currentIndex: diagnosticSelector.highlightedIndex
                    }
                }
                onVisibleChanged: if (!visible) popup.close()
            }
                Item { Layout.fillWidth: true }
                Label { text: "MANUAL TOOLS / HEALTH PROBES OPT-IN"; font.pixelSize: 10 }
            }
            RowLayout {
                visible: page.diagnosticTool === 0
                Layout.fillWidth: true
                Label { text: "ACTIVE PROBES / PING + DNS"; color: page.bright; font.bold: true }
                Item { Layout.fillWidth: true }
                Tab { caption: page.probesEnabled ? "PROBES ON" : "PROBES OFF"; selected: page.probesEnabled; onActivated: page.probesEnabled = !page.probesEnabled }
                Tab { caption: probeProcess.running ? "RUNNING" : "RUN ONCE"; enabled: !probeProcess.running; onActivated: { if (!probeProcess.running) probeProcess.running = true; } }
            }
            RowLayout {
                visible: page.diagnosticTool === 0
                Layout.fillWidth: true; spacing: 8
                Readout { heading: "WAN LATENCY"; value: page.latency(page.probeData.wan?.latencyMs); detail: "ICMP / 1.1.1.1" }
                Readout { heading: "PACKET LOSS"; value: page.probeData.wan?.lossPercent === null || page.probeData.wan?.lossPercent === undefined ? "—" : page.probeData.wan.lossPercent + "%"; detail: "2 PINGS PER CHECK" }
                Readout { heading: "DNS RESOLUTION"; value: page.latency(page.probeData.dnsProbe?.latencyMs); detail: "example.com" }
            }
            Panel {
                visible: page.diagnosticTool === 0
                Layout.fillWidth: true; Layout.preferredHeight: 130
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 12; spacing: 6
                    Label { text: "NETWORK REACHABILITY"; color: page.bright; font.bold: true }
                    InfoLine { heading: "GATEWAY"; value: page.diagnostics.gateway || "Unavailable" }
                    InfoLine { heading: "GATEWAY PING"; value: page.probeData.gateway?.status || "Not tested" }
                    InfoLine { heading: "WAN PING"; value: page.probeData.wan?.status || "Not tested" }
                    InfoLine { heading: "DNS STATUS"; value: page.probeData.dnsProbe?.status || "Not tested" }
                }
            }
            Panel {
                visible: page.diagnosticTool === 0
                Layout.fillWidth: true; Layout.fillHeight: true
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 12; spacing: 7
                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "WAN LATENCY HISTORY"; color: page.bright; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Label { text: page.latencyHistory.length + " SAMPLES" }
                    }
                    Canvas {
                        id: latencyPlot
                        Layout.fillWidth: true; Layout.fillHeight: true
                        onPaint: {
                            let ctx=getContext('2d');ctx.clearRect(0,0,width,height);
                            let data=page.latencyHistory;
                            let max=Math.max(10,...data)*1.2;
                            ctx.strokeStyle='#414651';ctx.lineWidth=1;
                            for(let i=1;i<4;i++){let y=i*height/4;ctx.beginPath();ctx.moveTo(0,y);ctx.lineTo(width,y);ctx.stroke();}
                            ctx.beginPath();ctx.strokeStyle='#e2e7ed';ctx.lineWidth=2;
                            for(let i=0;i<data.length;i++){
                                let x=data.length===1?0:i*width/(data.length-1);
                                let y=height*(1-data[i]/max);
                                if(i===0)ctx.moveTo(x,y);else ctx.lineTo(x,y);
                            }
                            ctx.stroke();
                        }
                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()
                        Connections { target: page; function onLatencyHistoryChanged() { latencyPlot.requestPaint(); } }
                    }
                }
            }
            RowLayout {
                visible: page.diagnosticTool === 0
                Layout.fillWidth: true
                Label { text: "PUBLIC IP  " + page.publicIp }
                Item { Layout.fillWidth: true }
                Tab { caption: "LOOK UP IP"; enabled: !publicIpProcess.running; onActivated: { if (!publicIpProcess.running) { page.publicIp = "Querying..."; publicIpProcess.running = true; } } }
            }
            Label { visible: page.diagnosticTool === 0; text: "ICMP and DNS generate traffic only when enabled; public IP makes an HTTPS request only on click."; font.pixelSize: 10 }
            Panel {
                visible: page.diagnosticTool === 1
                Layout.fillWidth: true; Layout.fillHeight: true
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 12; spacing: 12
                    Label { text: "DNS RECORD INSPECTION / MANUAL QUERY"; color: page.bright; font.bold: true }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 7
                        Panel {
                            Layout.fillWidth: true; Layout.preferredHeight: 34
                            TextInput { clip: true; enabled: !page.dnsBusy; anchors.fill: parent; anchors.margins: 9; color: page.bright; font.family: "monospace"; font.pixelSize: 12; text: page.lookupTarget; onTextChanged: page.lookupTarget = text; selectByMouse: true }
                        }
                        Repeater {
                            model: ["A", "AAAA", "MX", "TXT", "CNAME", "PTR"]
                            delegate: Tab { required property string modelData; minimumWidth: modelData === "CNAME" ? 66 : 48; caption: modelData; selected: page.lookupType === modelData; onActivated: page.lookupType = modelData }
                        }
                        Tab { caption: page.dnsBusy ? "QUERYING" : "QUERY"; enabled: !page.dnsBusy && !!page.lookupTarget.trim(); onActivated: { if (!page.dnsBusy && page.lookupTarget.trim()) { page.dnsOutput = "Querying..."; dnsToolProcess.running = true; } } }
                    }
                    Label { text: "Results / TTL / elapsed time • dig required for bounded DNS queries"; font.pixelSize: 10 }
                    Panel {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        Flickable {
                            anchors.fill: parent; anchors.margins: 12; contentWidth: width; contentHeight: dnsResult.implicitHeight; clip: true
                            Text { id: dnsResult; width: parent.width; text: page.dnsOutput; color: page.bright; font.family: "monospace"; font.pixelSize: 12; wrapMode: Text.WrapAnywhere; textFormat: Text.PlainText }
                        }
                    }
                }
            }
            Panel {
                visible: page.diagnosticTool === 2
                Layout.fillWidth: true; Layout.fillHeight: true
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 12; spacing: 12
                    Label { text: "ROUTE INSPECTION / MAX 12 HOPS / UP TO 20s"; color: page.bright; font.bold: true }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 8
                        Panel {
                            Layout.fillWidth: true; Layout.preferredHeight: 34
                            TextInput { clip: true; enabled: !page.traceBusy; anchors.fill: parent; anchors.margins: 9; color: page.bright; font.family: "monospace"; font.pixelSize: 12; text: page.traceTarget; onTextChanged: page.traceTarget = text; selectByMouse: true }
                        }
                        Tab { caption: page.traceBusy ? "TRACING" : "TRACE"; enabled: !page.traceBusy && !!page.traceTarget.trim(); onActivated: { if (!page.traceBusy && page.traceTarget.trim()) { page.traceOutput = "Tracing route..."; traceToolProcess.running = true; } } }
                    }
                    Label { text: "Route discovery sends packets to the selected destination. Intermediate hops may not reply."; font.pixelSize: 10 }
                    Panel {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        Flickable {
                            anchors.fill: parent; anchors.margins: 12; contentWidth: width; contentHeight: traceResult.implicitHeight; clip: true
                            Text { id: traceResult; width: parent.width; text: page.traceOutput; color: page.bright; font.family: "monospace"; font.pixelSize: 12; wrapMode: Text.WrapAnywhere; textFormat: Text.PlainText }
                        }
                    }
                }
            }
        }
    }
}
