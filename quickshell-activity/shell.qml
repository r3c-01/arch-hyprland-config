import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

ShellRoot {
    id: root

    property var days: ({})
    property string activeApp: ""
    property bool ready: false
    property bool dirty: false
    property bool gotFocusEvent: false
    property bool wasIdle: false
    property double lastMs: 0

    function checkpoint() {
        const now = Date.now();

        if (lastMs === 0) {
            lastMs = now;
            return;
        }

        // Cap gaps caused by suspend or event-loop stalls.
        const seconds = Math.max(0,
            Math.min((now - lastMs) / 1000, 15));

        lastMs = now;

        if (!ready || wasIdle || !activeApp || seconds <= 0)
            return;

        let cursor = now - seconds * 1000;

        // Split intervals that cross local midnight.
        while (cursor < now) {
            const d = new Date(cursor);
            const key = Qt.formatDate(d, "yyyy-MM-dd");
            const midnight = new Date(
                d.getFullYear(), d.getMonth(),
                d.getDate() + 1
            ).getTime();

            const end = Math.min(now, midnight);
            const portion = (end - cursor) / 1000;

            if (!days[key])
                days[key] = {};

            days[key][activeApp] =
                (Number(days[key][activeApp]) || 0)
                + portion;

            cursor = end;
        }

        dirty = true;
    }


    // Keep today and the preceding 29 local calendar days.
    function pruneOldDays() {
        const cutoff = new Date();

        // Noon avoids edge cases around daylight-saving transitions.
        cutoff.setHours(12, 0, 0, 0);
        cutoff.setDate(cutoff.getDate() - 29);

        const oldestAllowed =
            Qt.formatDate(cutoff, "yyyy-MM-dd");

        for (const key of Object.keys(days)) {
            // Preserve unknown keys instead of deleting them.
            if (!/^\d{4}-\d{2}-\d{2}$/.test(key))
                continue;

            if (key < oldestAllowed) {
                delete days[key];
                dirty = true;
            }
        }
    }

    function save() {
        if (!ready || !dirty)
            return;

        // Only the dedicated tracker writes activity.json.
        dataFile.setText(JSON.stringify({
            days: days
        }, null, 2) + "\n");

        dirty = false;
    }

    function setActiveApp(app) {
        checkpoint();
        activeApp = String(app || "").trim().toLowerCase();

        console.log("Tracking:", activeApp || "(none)");
    }

    FileView {
        id: dataFile

        path: Quickshell.env("HOME")
              + "/.local/state/quickshell-control/activity.json"

        atomicWrites: true
        blockWrites: true

        onLoaded: {
            try {
                const parsed = JSON.parse(dataFile.text());

                if (!parsed || !parsed.days ||
                    typeof parsed.days !== "object" ||
                    Array.isArray(parsed.days))
                    throw new Error("Invalid activity data");

                root.days = parsed.days;
                root.pruneOldDays();
                root.ready = true;
                root.wasIdle = idle.isIdle;
                root.lastMs = Date.now();

                console.log("Activity storage loaded.");
                if (!snapshot.running)
                    snapshot.running = true;
            } catch (e) {
                console.warn("Activity load error:", e);
                root.ready = false;
            }
        }

        onLoadFailed: error => {
            console.warn("Activity file unavailable:", error);
            root.ready = false;
        }

        onSaveFailed: error => {
            console.warn("Activity save error:", error);
            root.dirty = true;
        }
    }

    IdleMonitor {
        id: idle
        timeout: 60
        respectInhibitors: false

        onIsIdleChanged: {
            root.checkpoint();
            root.wasIdle = isIdle;
            root.save();
            console.log("Idle:", isIdle);
        }
    }

    Process {
        id: snapshot
        command: ["hyprctl", "-j", "activewindow"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (root.gotFocusEvent)
                    return;

                try {
                    const obj = JSON.parse(this.text);
                    root.setActiveApp(obj["class"] || "");
                } catch (e) {
                    console.warn("Initial focus lookup failed:", e);
                }
            }
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name !== "activewindow")
                return;

            root.gotFocusEvent = true;

            const raw = String(event.data);
            const comma = raw.indexOf(",");
            const app = comma >= 0
                ? raw.substring(0, comma) : raw;

            root.setActiveApp(app);
        }
    }

    Timer {
        interval: 10000
        repeat: true
        running: true

        onTriggered: {
            root.checkpoint();
            root.pruneOldDays();
            root.save();
        }
    }
}
