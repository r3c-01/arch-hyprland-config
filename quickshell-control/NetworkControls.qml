import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Networking
import Quickshell.Bluetooth

Rectangle {
    id: network
    implicitHeight: expanded ? 190 : 104
    radius: 0
    color: "#85303034"
    property bool expanded: false
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool wifiKnown: Networking.backend !== NetworkBackendType.None
    readonly property bool btKnown: adapter !== null
    readonly property var wifiDevices: Networking.devices.values.filter(d => d.type === DeviceType.Wifi)
    readonly property var connections: {
        const names = [];
        for (const device of wifiDevices)
            for (const net of device.networks.values)
                if (net.connected) names.push(net.name);
        return names;
    }
    readonly property var connectedBluetooth: adapter ? adapter.devices.values.filter(d => d.connected).map(d => d.name) : []
    property string notice: ""
    property string pending: ""
    property bool expected: false
    property var targetAdapter: null
    function toggleWifi() {
        if (!wifiKnown || pending || !Networking.wifiHardwareEnabled) return;
        notice = "";
        expected = !Networking.wifiEnabled;
        pending = "wifi";
        Networking.wifiEnabled = expected;
        verify.restart();
    }
    function toggleBluetooth() {
        if (!adapter || pending || adapter.state === BluetoothAdapterState.Blocked) return;
        notice = "";
        targetAdapter = adapter;
        expected = !adapter.enabled;
        pending = "bluetooth";
        targetAdapter.enabled = expected;
        verify.restart();
    }
    Timer {
        id: verify
        interval: 200; repeat: true
        property int elapsed: 0
        onRunningChanged: if (running) elapsed = 0
        onTriggered: {
            elapsed += interval;
            const ok = network.pending === "wifi" ? network.wifiKnown && Networking.wifiEnabled === network.expected
                : network.targetAdapter && network.targetAdapter.enabled === network.expected
                    && network.targetAdapter.state !== BluetoothAdapterState.Enabling && network.targetAdapter.state !== BluetoothAdapterState.Disabling;
            if (ok) {
                network.pending = "";
                stop();
            } else if (elapsed >= 6500) {
                network.notice = "Change not confirmed. Check the hardware radio switch or permissions, then retry.";
                network.pending = "";
                stop();
            }
        }
    }
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 16
        spacing: 10
        RowLayout {
            Layout.fillWidth: true
            spacing: 16
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                Text { text: "WI-FI"; color: "#f0f0f2"; font.pixelSize: 12; font.bold: true; font.letterSpacing: 1 }
                Text {
                    Layout.fillWidth: true; elide: Text.ElideRight
                    text: !network.wifiKnown ? "Service unavailable" : !Networking.wifiHardwareEnabled ? "Hardware blocked"
                        : !Networking.wifiEnabled ? "Radio off" : network.connections.join(", ") || "Not connected"
                    color: "#a5adba"; font.pixelSize: 11
                }
            }
            ControlButton {
                text: network.pending === "wifi" ? "WAIT" : !network.wifiKnown ? "N/A" : Networking.wifiEnabled ? "ON" : "OFF"
                selected: network.wifiKnown && Networking.wifiEnabled
                enabled: network.wifiKnown && Networking.wifiHardwareEnabled && !network.pending
                onClicked: network.toggleWifi()
                Accessible.name: "Wi-Fi radio " + text
            }
            Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 34; color: "#414651" }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                Text { text: "BLUETOOTH"; color: "#f0f0f2"; font.pixelSize: 12; font.bold: true; font.letterSpacing: 1 }
                Text {
                    Layout.fillWidth: true; elide: Text.ElideRight
                    text: !network.adapter ? "No adapter" : network.adapter.state === BluetoothAdapterState.Blocked ? "Hardware blocked"
                        : !network.adapter.enabled ? "Radio off" : network.connectedBluetooth.join(", ") || "No devices connected"
                    color: "#a5adba"; font.pixelSize: 11
                }
            }
            ControlButton {
                text: network.pending === "bluetooth" ? "WAIT" : !network.btKnown ? "N/A" : network.adapter.enabled ? "ON" : "OFF"
                selected: network.btKnown && network.adapter.enabled
                enabled: network.btKnown && !network.pending && network.adapter.state !== BluetoothAdapterState.Blocked
                onClicked: network.toggleBluetooth()
                Accessible.name: "Bluetooth radio " + text
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: network.notice || ""
                color: "#edb49b"; font.pixelSize: 11
                elide: Text.ElideRight
                ToolTip.visible: hovered.hovered && text !== ""
                ToolTip.text: text
                HoverHandler { id: hovered }
            }
            ControlButton { text: network.expanded ? "LESS" : "DETAILS"; implicitHeight: 22; onClicked: network.expanded = !network.expanded }
        }
        Text {
            visible: network.expanded
            Layout.fillWidth: true; Layout.fillHeight: true
            text: "Wi-Fi: " + (network.connections.join(", ") || "No active Wi-Fi connection")
                + "\nBluetooth adapter: " + (network.adapter ? network.adapter.name : "Unavailable")
                + "\nConnected devices: " + (network.connectedBluetooth.join(", ") || "None")
            color: "#b7beca"; font.pixelSize: 11; lineHeight: 1.4; wrapMode: Text.WordWrap
        }
    }
}
