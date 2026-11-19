import Quickshell
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: power

    signal closeRequested()

    color: "#26000000"
    radius: 0
    border.color: "#414651"
    border.width: 1
    clip: true

    property string pendingAction: ""
    property string message: ""

    function requestAction(action) {
        if (action === "lock") {
            // Detach the lock screen from Quickshell.
            // Never launch another if one already exists.
            Quickshell.execDetached(["loginctl", "lock-session"]);
            closeRequested();
            return;
        }

        if (["suspend", "restart", "shutdown"].includes(action))
            pendingAction = action;
    }

    function confirmAction() {
        const commands = {
            "suspend":  ["systemctl", "suspend"],
            "restart":  ["systemctl", "reboot"],
            "shutdown": ["systemctl", "poweroff"]
        };

        const command = commands[pendingAction];
        if (!command)
            return;

        const action = pendingAction;
        pendingAction = "";
        message = "Requested " + action;

        Quickshell.execDetached(command);
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 20

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "POWER & SESSION"
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
                    onClicked: {
                        power.pendingAction = "";
                        power.closeRequested();
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#343943"
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 12
            columnSpacing: 12

            Repeater {
                model: [
                    { label: "LOCK", action: "lock",
                      desc: "Secure session" },
                    { label: "SUSPEND", action: "suspend",
                      desc: "Sleep mode" },
                    { label: "RESTART", action: "restart",
                      desc: "Reboot system" },
                    { label: "SHUTDOWN", action: "shutdown",
                      desc: "Power off" }
                ]

                Rectangle {
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: 110
                    radius: 0
                    color: "#85303034"
                    border.color: "#343943"

                    Column {
                        anchors.centerIn: parent
                        spacing: 10

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.label
                            color: "#f0f0f2"
                            font.pixelSize: 15
                            font.bold: true
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.desc
                            color: "#939ba8"
                            font.pixelSize: 12
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: power.pendingAction === ""
                        cursorShape: Qt.PointingHandCursor
                        onClicked: power.requestAction(modelData.action)
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 110
            radius: 0
            color: "#85303034"
            border.width: 1
            border.color: "#33c8cdd4"
            visible: power.pendingAction !== ""

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 12

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Confirm " + power.pendingAction + "?"
                    color: "#f0f0f2"
                    font.pixelSize: 14
                    font.bold: true
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 14

                    Repeater {
                        model: ["CANCEL", "CONFIRM"]

                        Rectangle {
                            required property string modelData

                            Layout.preferredWidth: 110
                            Layout.preferredHeight: 34
                            radius: 0
                            color: modelData === "CONFIRM"
                                ? "#e64b4b4e" : "#a0303034"
                            border.width: 1
                            border.color: modelData === "CONFIRM"
                                ? "#66c8cdd4" : "#33c8cdd4"

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: "#f0f0f2"
                                font.pixelSize: 11
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (modelData === "CONFIRM")
                                        power.confirmAction();
                                    else
                                        power.pendingAction = "";
                                }
                            }
                        }
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: power.message
            color: "#939ba8"
            font.pixelSize: 11
            horizontalAlignment: Text.AlignHCenter
            visible: power.message !== ""
        }

        Item { Layout.fillHeight: true }
    }
}
