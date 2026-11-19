import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: activity

    signal closeRequested()

    color: "#26000000"
    radius: 0
    border.color: "#414651"
    border.width: 1
    clip: true

    property var days: ({})
    property var entries: []
    property real totalSeconds: 0
    property int periodDays: 1
    property string status: "Loading activity..."

    function formatDuration(value) {
        const minutes = Math.floor(value / 60);

        if (minutes < 1)
            return "<1m";

        const hours = Math.floor(minutes / 60);
        const remaining = minutes % 60;

        if (hours === 0)
            return minutes + "m";

        return hours + "h " + remaining + "m";
    }

    function rebuild() {
        const totals = {};

        for (let i = 0; i < periodDays; i++) {
            const date = new Date();
            date.setDate(date.getDate() - i);

            const key = Qt.formatDate(date, "yyyy-MM-dd");
            const day = days[key];

            if (!day || typeof day !== "object")
                continue;

            for (const app of Object.keys(day)) {
                const seconds = Number(day[app]);

                if (!Number.isFinite(seconds) || seconds <= 0)
                    continue;

                const name = app || "(unknown)";
                totals[name] =
                    (totals[name] || 0) + seconds;
            }
        }

        const next = Object.keys(totals).map(name => ({
            name: name,
            seconds: totals[name]
        }));

        next.sort((a, b) => b.seconds - a.seconds);

        entries = next;
        totalSeconds = next.reduce(
            (sum, item) => sum + item.seconds, 0
        );
    }

    function selectPeriod(value) {
        periodDays = value;
        rebuild();
    }

    onVisibleChanged: {
        if (visible && activityFile.loaded)
            activityFile.reload();
    }

    FileView {
        id: activityFile

        path: Quickshell.env("HOME")
            + "/.local/state/quickshell-control/activity.json"

        watchChanges: true

        onFileChanged: reload()

        onLoaded: {
            try {
                const parsed = JSON.parse(activityFile.text());

                if (!parsed || !parsed.days ||
                    typeof parsed.days !== "object" ||
                    Array.isArray(parsed.days))
                    throw new Error("Invalid activity data");

                activity.days = parsed.days;
                activity.rebuild();
                activity.status = "";
            } catch (error) {
                activity.status = "Activity data error";
                console.warn("Activity load:", error);
            }
        }

        onLoadFailed: error => {
            activity.status = "Unable to load activity data";
            console.warn("Activity file:", error);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 15

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: "ACTIVITY"
                color: "#f0f0f2"
                font.pixelSize: 20
                font.bold: true
                font.letterSpacing: 2
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.preferredWidth: 75
                Layout.preferredHeight: 32
                radius: 0
                color: "#a0303034"
                border.width: 1
                border.color: "#33c8cdd4"


                Text {
                    anchors.centerIn: parent
                    text: "CLOSE"
                    color: "#f0f0f2"
                    font.pixelSize: 11
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: activity.closeRequested()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#343943"
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Repeater {
                model: [
                    { label: "TODAY", days: 1 },
                    { label: "7 DAYS", days: 7 }
                ]

                Rectangle {
                    required property var modelData

                    Layout.preferredWidth: 90
                    Layout.preferredHeight: 34
                    radius: 0

                    color: activity.periodDays === modelData.days
                        ? "#ae3b3b3d" : "#a0303034"
                    border.width: 1
                    border.color: activity.periodDays === modelData.days
                        ? "#66c8cdd4" : "#33c8cdd4"

                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        color: "#f0f0f2"
                        font.pixelSize: 11
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: activity.selectPeriod(
                            modelData.days
                        )
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Column {
                spacing: 3

                Text {
                    text: activity.formatDuration(
                        activity.totalSeconds
                    )
                    color: "#f0f0f2"
                    font.pixelSize: 21
                    font.bold: true
                    anchors.right: parent.right
                }

                Text {
                    text: "TRACKED TIME"
                    color: "#939ba8"
                    font.pixelSize: 10
                    anchors.right: parent.right
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#85303034"
            radius: 0

            Text {
                anchors.centerIn: parent
                visible: activity.entries.length === 0
                text: activity.status ||
                      "No activity recorded for this period"
                color: "#939ba8"
                font.pixelSize: 13
            }

            Flickable {
                id: scrolling
                anchors.fill: parent
                anchors.margins: 15
                clip: true
                contentHeight: appList.height

                Column {
                    id: appList
                    width: scrolling.width
                    spacing: 15

                    Repeater {
                        model: activity.entries

                        delegate: Column {
                            required property var modelData

                            width: appList.width
                            spacing: 7

                            RowLayout {
                                width: parent.width

                                Text {
                                    text: modelData.name
                                    color: "#f0f0f2"
                                    font.pixelSize: 13
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: activity.formatDuration(
                                        modelData.seconds
                                    )
                                    color: "#939ba8"
                                    font.pixelSize: 12
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 6
                                radius: 0
                                color: "#414651"

                                Rectangle {
                                    height: parent.height
                                    radius: 0
                                    color: "#c4cad4"

                                    width: parent.width *
                                        Math.min(1,
                                            modelData.seconds /
                                            Math.max(
                                                1,
                                                activity.entries[0].seconds
                                            )
                                        )
                                }
                            }
                        }
                    }
                }
            }
        }

        Text {
            text: "Foreground application time · Local data only"
            color: "#858b98"
            font.pixelSize: 11
        }
    }
}
