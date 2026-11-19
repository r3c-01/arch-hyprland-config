import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io

Item {
    id: page
    property var processes: []
    property string telemetryError: ""
    property string pendingStartTime: ""
    onVisibleChanged: if (!visible) pendingPid = -1
    property int scrollRailWidth: 14
    property string sortBy: "cpu"
    property bool descending: true
    property int pendingPid: -1
    property string pendingName: ""
    property string feedback: ""
    property int terminatingPid: -1
    focus: true

    // Passive pointer observation: clicking any area outside search removes the caret
    // without stealing the click from buttons, the scrollbar, or process rows.
    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: (point, button) => {
            const local = search.mapFromItem(page, point.position.x, point.position.y);
            if (local.x < 0 || local.y < 0 || local.x >= search.width || local.y >= search.height) {
                search.focus = false;
                page.forceActiveFocus();
            }
        }
    }

    readonly property var filtered: {
        let query = search.text.toLowerCase().trim();
        let rows = processes.filter(p => !query || p.name.toLowerCase().includes(query) || String(p.pid).includes(query));
        rows.sort((a,b) => { let av=a[sortBy],bv=b[sortBy]; return (typeof av === "string" ? av.localeCompare(bv) : av-bv) * (descending ? -1 : 1); });
        return rows;
    }
    function choose(key) { if (sortBy === key) descending = !descending; else {sortBy=key; descending=key!=="name";} }
    Process {
        id: terminator
        stderr: StdioCollector { id: err }
        onExited: (code, status) => page.feedback = code === 0 ? "SIGTERM sent to PID " + page.terminatingPid + " (exit is not guaranteed)" : "Failed: " + (err.text.trim() || "worker exited without details")
    }
    ColumnLayout {
        anchors.fill: parent; spacing: 12
        RowLayout {
            Layout.fillWidth: true
            Text { text: "PROCESS MANAGER"; font.pixelSize: 17; font.bold: true; color: "#f0f0f2"; font.letterSpacing: 1 }
            Item { Layout.fillWidth: true }
            Text { text: page.filtered.length + " / " + page.processes.length + " processes"; color: "#a0a5af"; font.pixelSize: 11 }
        }
        TextField {
            id: search; Layout.fillWidth: true; Layout.preferredHeight: 40
            placeholderText: "Search process name or PID..."
            color: "#ffffff"
            placeholderTextColor: "#c9cbd0"
            font.pixelSize: 13
            leftPadding: 16
            rightPadding: 12
            topPadding: 8
            bottomPadding: 8
            background: Rectangle { color: "#303034"; border.color: "#565b64"; radius: 0 }
        }
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 36; color: "#3b3b3f"; border.color: "#565b64"
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10 + page.scrollRailWidth + 8; spacing: 6
                Repeater {
                    model: [{key:"pid",name:"PID",w:80},{key:"name",name:"COMMAND",w:1},{key:"cpu",name:"CPU %",w:70},{key:"mem",name:"MEM %",w:70},{key:"rss",name:"RSS MiB",w:80}]
                    delegate: Item {
                        required property var modelData
                        Layout.preferredWidth: modelData.w===1 ? -1 : modelData.w
                        Layout.fillWidth: modelData.w===1; height: 36
                        Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.name + (page.sortBy===modelData.key ? (page.descending?" ▼":" ▲") : ""); color: "#f0f0f2"; font.pixelSize: 11; font.bold: true; width: parent.width; horizontalAlignment: modelData.key === "name" ? Text.AlignLeft : Text.AlignRight; elide: Text.ElideRight }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: page.choose(modelData.key) }
                    }
                }
                Item { Layout.preferredWidth: 54; Layout.preferredHeight: 36 }
            }
        }
        Flickable {
            id: processScroller
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 0
            clip: true
            contentWidth: width - page.scrollRailWidth - 8
            contentHeight: entries.height
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            ScrollBar.vertical: ScrollBar {
                id: processBar
                policy: ScrollBar.AlwaysOn
                active: true
                width: page.scrollRailWidth
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                padding: 2

                background: Rectangle {
                    implicitWidth: page.scrollRailWidth
                    radius: 0
                    color: "#70303034"
                    border.color: "#565b64"
                    border.width: 1
                }

                contentItem: Rectangle {
                    radius: 0
                    color: processBar.pressed ? "#d5d7dc" : (processBar.hovered ? "#c6cad1" : "#b8bdc6")
                    border.color: "#eef0f3"
                    border.width: 1
                    implicitWidth: page.scrollRailWidth - 4
                }
            }
            Column {
                id: entries; width: processScroller.width - page.scrollRailWidth - 8; spacing: 2
                Repeater {
                    model: page.filtered
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: entries.width; height: 36; color: index % 2 ? "#95303034" : "#bb303034"; border.color: "#304146"
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 6
                            Text { Layout.preferredWidth: 80; text: modelData.pid; color: "#c4cad4"; horizontalAlignment: Text.AlignRight; font.pixelSize: 12; font.family: "monospace" }
                            Text { Layout.fillWidth: true; text: modelData.name; elide: Text.ElideRight; color: "#f0f0f2"; font.pixelSize: 12; font.family: "monospace" }
                            Text { Layout.preferredWidth: 70; text: modelData.cpu.toFixed(1); color: "#c4cad4"; horizontalAlignment: Text.AlignRight; font.pixelSize: 12; font.family: "monospace" }
                            Text { Layout.preferredWidth: 70; text: modelData.mem.toFixed(1); color: "#c4cad4"; horizontalAlignment: Text.AlignRight; font.pixelSize: 12; font.family: "monospace" }
                            Text { Layout.preferredWidth: 80; text: modelData.rss; color: "#c4cad4"; horizontalAlignment: Text.AlignRight; font.pixelSize: 12; font.family: "monospace" }
                            Rectangle {
                                enabled: !!modelData.startTime && !terminator.running
                                opacity: enabled ? 1 : 0.35
                                Layout.preferredWidth: 54; Layout.preferredHeight: 24; color: termMouse.containsMouse ? "#404047" : "transparent"; border.color: "#414651"; radius: 0
                                Text { anchors.centerIn: parent; text: "TERM"; font.pixelSize: 10; color: "#abb1bc"; font.bold: false }
                                MouseArea { id: termMouse; hoverEnabled: true; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { page.pendingStartTime = modelData.startTime; page.pendingPid = modelData.pid; page.pendingName = modelData.name; page.feedback = ""; } }
                            }
                        }
                    }
                }
            }
        }
        Text { Layout.fillWidth: true; text: page.telemetryError || page.feedback || "SIGTERM only • no force kill • confirmation required"; color: "#9ea5b0"; font.pixelSize: 11; elide: Text.ElideRight }
    }
    MouseArea { anchors.fill: parent; visible: page.pendingPid > 0; z: 9; onClicked: page.pendingPid = -1 }
    Rectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width-24,420); height: 170
        visible: page.pendingPid > 0; z: 10
        color: "#24252a"; border.color: "#abb1bc"; border.width: 1
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 18; spacing: 12
            Text { text: "TERMINATE PROCESS?"; color: "#f0f0f2"; font.pixelSize: 16; font.bold: true }
            Text { Layout.fillWidth: true; elide: Text.ElideRight; text: page.pendingName + "  [PID " + page.pendingPid + "]"; color: "#c4cad4"; font.family: "monospace"; font.pixelSize: 12 }
            Text { text: "Send SIGTERM. Unsaved work may be lost."; color: "#a0a5af"; font.pixelSize: 11 }
            RowLayout {
                Item { Layout.fillWidth: true }
                Button { text: "CANCEL"; onClicked: page.pendingPid = -1 }
                Button {
                    text: "TERMINATE"
                    onClicked: {
                        if (page.pendingPid > 1 && !terminator.running) {
                            page.terminatingPid = page.pendingPid;
                            terminator.command = ["python3", Quickshell.shellDir + "/scripts/process_action.py", String(page.terminatingPid), page.pendingStartTime];
                            terminator.running = true;
                        }
                        page.pendingPid = -1;
                    }
                }
            }
        }
    }
}
