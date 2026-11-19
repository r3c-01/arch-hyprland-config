import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: todo
    signal closeRequested()

    color: "#26000000"
    radius: 0
    border.color: "#414651"
    border.width: 1
    clip: true

    property bool ready: false
    property var tasks: []
    property string message: "Loading tasks..."
    property string errorMessage: ""
    property int editingIndex: -1
    property bool remindEarly: true
    property string repeatMode: "none"
    property date clockNow: new Date()

    readonly property bool editing: editingIndex >= 0
    readonly property var repeatModes: ["none", "daily", "weekly", "monthly"]

    function currentTasks() {
        return Array.isArray(tasks) ? tasks : []
    }

    function dateValid(value) {
        if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return false
        const parts = value.split("-").map(Number)
        const date = new Date(parts[0], parts[1] - 1, parts[2], 12)
        return date.getFullYear() === parts[0] && date.getMonth() === parts[1] - 1
            && date.getDate() === parts[2]
    }

    function timeValid(value) {
        return /^([01]\d|2[0-3]):[0-5]\d$/.test(value)
    }

    function prettyTime(value) {
        if (!timeValid(value)) return ""
        const hour = Number(value.slice(0, 2))
        return ((hour % 12) || 12) + value.slice(2) + (hour >= 12 ? " PM" : " AM")
    }

    function prettyDate(value) {
        if (!dateValid(value)) return ""
        const bits = value.split("-").map(Number)
        return Qt.formatDate(new Date(bits[0], bits[1] - 1, bits[2], 12),
                             "ddd, MMM d" + (bits[0] !== clockNow.getFullYear() ? ", yyyy" : ""))
    }

    function repeatLabel(mode) {
        return mode === "daily" ? "Daily" : mode === "weekly" ? "Weekly"
             : mode === "monthly" ? "Monthly" : "No repeat"
    }

    function scheduleText(task) {
        const result = []
        if (task.date && dateValid(task.date)) {
            let date = prettyDate(task.date)
            if (task.time && timeValid(task.time))
                date += " · " + prettyTime(task.time)
            result.push(date)
            if (task.time && timeValid(task.time))
                result.push(task.remindMinutes === 10 ? "10m early" : "At due time")
        }
        if (task.repeat && task.repeat !== "none")
            result.push(repeatLabel(task.repeat))
        return result.join("  ·  ")
    }

    function isOverdue(task) {
        // Reading clockNow makes the visual state refresh every minute.
        const now = clockNow
        if (task.done || !task.date || !dateValid(task.date)) return false
        const today = Qt.formatDate(now, "yyyy-MM-dd")
        if (task.date < today) return true
        if (task.date > today || !task.time || !timeValid(task.time)) return false
        return task.time < Qt.formatTime(now, "HH:mm")
    }

    function saveTasks(next) {
        if (!ready) return
        tasks = next
        taskFile.setText(JSON.stringify({tasks: next}, null, 2) + "\n")
        message = "Saving..."
    }

    function clearEditor() {
        editingIndex = -1
        taskEntry.text = ""
        dateEntry.text = ""
        timeEntry.text = ""
        remindEarly = true
        repeatMode = "none"
        errorMessage = ""
    }

    function editTask(index) {
        if (!ready || index < 0 || index >= tasks.length) return
        const task = tasks[index]
        editingIndex = index
        taskEntry.text = task.title
        dateEntry.text = task.date || ""
        timeEntry.text = task.time || ""
        remindEarly = task.remindMinutes !== 0
        repeatMode = repeatModes.indexOf(task.repeat) >= 0 ? task.repeat : "none"
        errorMessage = ""
        taskEntry.forceActiveFocus()
        scrolling.contentY = 0
    }

    function saveEditor() {
        if (!ready) return
        const title = taskEntry.text.trim()
        const date = dateEntry.text.trim()
        const time = timeEntry.text.trim()
        if (!title || title.length > 200) {
            errorMessage = "Enter a title (max 200 characters)"
            return
        }
        if (date && !dateValid(date)) {
            errorMessage = "Date must be valid YYYY-MM-DD"
            return
        }
        if (time && !timeValid(time)) {
            errorMessage = "Time must be HH:MM (24-hour)"
            return
        }
        if (time && !date) {
            errorMessage = "Choose a date for timed tasks"
            return
        }
        if (repeatMode !== "none" && !date) {
            errorMessage = "Repeating tasks need a start date"
            return
        }
        const next = currentTasks().slice()
        const old = editingIndex >= 0 && editingIndex < next.length ? next[editingIndex] : null
        const updated = Object.assign({}, old || {}, {
            title: title,
            done: old ? old.done : false
        })
        if (!updated.uid)
            updated.uid = String(Date.now()) + "-" + String(Math.floor(Math.random() * 1000000))
        if (date) updated.date = date
        else delete updated.date
        if (time) {
            updated.time = time
            updated.remindMinutes = remindEarly ? 10 : 0
        } else {
            delete updated.time
            delete updated.remindMinutes
        }
        if (repeatMode !== "none") {
            updated.repeat = repeatMode
            if (repeatMode === "monthly") {
                if (!old || old.date !== date || old.repeat !== "monthly")
                    updated.repeatDay = Number(date.slice(8, 10))
            } else {
                delete updated.repeatDay
            }
        } else {
            delete updated.repeat
            delete updated.repeatDay
        }
        if (old) next[editingIndex] = updated
        else next.push(updated)
        saveTasks(next)
        clearEditor()
    }

    function nextRecurringDate(task) {
        if (!dateValid(task.date)) return ""
        const parts = task.date.split("-").map(Number)
        let date = new Date(parts[0], parts[1] - 1, parts[2], 12)
        const today = new Date(clockNow.getFullYear(), clockNow.getMonth(), clockNow.getDate(), 12)
        const preferredDay = task.repeatDay || parts[2]
        // Move at least one occurrence forward, and skip missed occurrences.
        for (let i = 0; i < 12000; i++) {
            if (task.repeat === "daily") date.setDate(date.getDate() + 1)
            else if (task.repeat === "weekly") date.setDate(date.getDate() + 7)
            else if (task.repeat === "monthly") {
                const year = date.getFullYear()
                const month = date.getMonth() + 1
                const lastDay = new Date(year, month + 1, 0).getDate()
                date = new Date(year, month, Math.min(preferredDay, lastDay), 12)
            } else return ""
            if (date > today) return Qt.formatDate(date, "yyyy-MM-dd")
        }
        return ""
    }

    function toggleTask(index) {
        if (!ready || index < 0 || index >= tasks.length) return
        const next = currentTasks().slice()
        const task = next[index]
        if (!task.done && task.repeat && task.repeat !== "none") {
            const nextDate = nextRecurringDate(task)
            if (nextDate) {
                next[index] = Object.assign({}, task, {date: nextDate, done: false})
                saveTasks(next)
                message = "Scheduled next " + repeatLabel(task.repeat).toLowerCase() + " occurrence"
                return
            }
        }
        next[index] = Object.assign({}, task, {done: !task.done})
        saveTasks(next)
    }

    function removeTask(index) {
        if (!ready || index < 0 || index >= tasks.length) return
        const next = currentTasks().filter((task, i) => i !== index)
        saveTasks(next)
        if (editingIndex === index) clearEditor()
        else if (editingIndex > index) editingIndex--
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: todo.clockNow = new Date()
    }

    FileView {
        id: taskFile
        path: Quickshell.env("HOME") + "/.local/state/quickshell-control/tasks.json"
        atomicWrites: true
        blockWrites: true
        watchChanges: true
        onFileChanged: taskFile.reload()
        onLoaded: {
            try {
                const parsed = JSON.parse(taskFile.text())
                if (!parsed || !Array.isArray(parsed.tasks))
                    throw new Error("Missing tasks array")
                for (const task of parsed.tasks) {
                    if (!task || typeof task.title !== "string" || typeof task.done !== "boolean")
                        throw new Error("Invalid task entry")
                }
                todo.tasks = parsed.tasks
                todo.ready = true
                todo.message = "Loaded " + todo.tasks.length + " tasks"
            } catch (error) {
                todo.ready = false
                todo.message = "Task load error"
                console.warn("Task load error:", error)
            }
        }
        onLoadFailed: error => {
            todo.ready = false
            todo.message = "Unable to load tasks"
            console.warn("Task file load failed:", error)
        }
        onSaved: todo.message = "Saved"
        onSaveFailed: error => {
            todo.message = "Save failed"
            console.warn("Task save failed:", error)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "TASKS"
                color: "#f0f0f2"
                font.pixelSize: 20
                font.bold: true
                font.letterSpacing: 2
            }
            Item { Layout.fillWidth: true }
            Text {
                text: todo.currentTasks().filter(task => !task.done).length + " remaining"
                color: "#939ba8"
                font.pixelSize: 12
            }
            Rectangle {
                Layout.preferredWidth: 75; Layout.preferredHeight: 32
                color: "#a0303034"; border.width: 1; border.color: "#33c8cdd4"
                Text { anchors.centerIn: parent; text: "CLOSE"; color: "#f0f0f2"; font.pixelSize: 11 }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: todo.closeRequested() }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#343943" }

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: todo.editing ? "EDIT TASK" : "NEW TASK"
                color: "#bfc6d0"; font.bold: true; font.pixelSize: 11; font.letterSpacing: 1
            }
            Item { Layout.fillWidth: true }
            Text {
                visible: todo.editing
                text: "CANCEL"
                font.pixelSize: 11
                color: cancelMouse.containsMouse ? "#ffffff" : "#939ba8"
                MouseArea { id: cancelMouse; anchors.fill: parent; hoverEnabled: true;
                    cursorShape: Qt.PointingHandCursor; onClicked: todo.clearEditor() }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: "#85303034"; border.color: "#565b64"; border.width: 1
                TextInput {
                    id: taskEntry
                    anchors.fill: parent; anchors.margins: 10
                    verticalAlignment: TextInput.AlignVCenter
                    color: "#f0f0f2"; font.pixelSize: 14
                    maximumLength: 200; clip: true; enabled: todo.ready
                    Keys.onReturnPressed: todo.saveEditor()
                }
                Text {
                    anchors.left: parent.left; anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Task title..."; color: "#858b98"; font.pixelSize: 13
                    visible: !taskEntry.text.length && !taskEntry.activeFocus
                }
            }
            Rectangle {
                Layout.preferredWidth: 90; Layout.preferredHeight: 40
                color: saveMouse.containsMouse ? "#454b55" : "#a0303034"
                border.width: 1; border.color: "#66c8cdd4"
                Text {
                    anchors.centerIn: parent
                    text: todo.editing ? "SAVE" : "ADD"
                    color: "#f0f0f2"; font.bold: true; font.pixelSize: 12
                }
                MouseArea {
                    id: saveMouse; anchors.fill: parent; hoverEnabled: true
                    enabled: todo.ready; cursorShape: Qt.PointingHandCursor
                    onClicked: todo.saveEditor()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            ColumnLayout {
                spacing: 4
                Text { text: "DATE"; color: "#939ba8"; font.pixelSize: 10 }
                Rectangle {
                    Layout.preferredWidth: 127; Layout.preferredHeight: 31
                    color: "#85303034"; border.width: 1; border.color: "#565b64"
                    TextInput {
                        id: dateEntry
                        anchors.fill: parent; anchors.margins: 7
                        verticalAlignment: TextInput.AlignVCenter
                        font.pixelSize: 12; color: "#f0f0f2"
                        maximumLength: 10; enabled: todo.ready
                        inputMethodHints: Qt.ImhNoPredictiveText
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "YYYY-MM-DD"; color: "#858b98"; font.pixelSize: 11
                        visible: !dateEntry.text.length && !dateEntry.activeFocus
                    }
                }
            }
            ColumnLayout {
                spacing: 4
                Text { text: "TIME"; color: "#939ba8"; font.pixelSize: 10 }
                Rectangle {
                    Layout.preferredWidth: 71; Layout.preferredHeight: 31
                    color: "#85303034"; border.width: 1; border.color: "#565b64"
                    TextInput {
                        id: timeEntry
                        anchors.fill: parent; anchors.margins: 7
                        verticalAlignment: TextInput.AlignVCenter
                        font.pixelSize: 12; color: "#f0f0f2"
                        maximumLength: 5; enabled: todo.ready
                        inputMethodHints: Qt.ImhNoPredictiveText
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "HH:MM"; color: "#858b98"; font.pixelSize: 11
                        visible: !timeEntry.text.length && !timeEntry.activeFocus
                    }
                }
            }
            ColumnLayout {
                spacing: 4
                Text { text: "REMINDER"; color: "#939ba8"; font.pixelSize: 10 }
                Rectangle {
                    Layout.preferredWidth: 108; Layout.preferredHeight: 31
                    color: earlyMouse.containsMouse ? "#454b55" : "#a0303034"
                    border.width: 1; border.color: "#565b64"
                    Text {
                        anchors.centerIn: parent
                        text: todo.remindEarly ? "10 MIN EARLY" : "AT DUE TIME"
                        color: "#f0f0f2"; font.pixelSize: 10
                    }
                    MouseArea {
                        id: earlyMouse; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: todo.remindEarly = !todo.remindEarly
                    }
                }
            }
            ColumnLayout {
                spacing: 4
                Text { text: "REPEAT"; color: "#939ba8"; font.pixelSize: 10 }
                Rectangle {
                    Layout.preferredWidth: 100; Layout.preferredHeight: 31
                    color: repeatMouse.containsMouse ? "#454b55" : "#a0303034"
                    border.width: 1; border.color: "#565b64"
                    Text {
                        anchors.centerIn: parent
                        text: todo.repeatLabel(todo.repeatMode).toUpperCase()
                        color: "#f0f0f2"; font.pixelSize: 10
                    }
                    MouseArea {
                        id: repeatMouse; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const i = todo.repeatModes.indexOf(todo.repeatMode)
                            todo.repeatMode = todo.repeatModes[(i + 1) % todo.repeatModes.length]
                        }
                    }
                }
            }
            Item { Layout.fillWidth: true }
        }

        Text {
            Layout.fillWidth: true
            visible: todo.errorMessage.length > 0
            text: todo.errorMessage
            font.pixelSize: 11; color: "#dcb2b2"
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: "#343943" }

        Flickable {
            id: scrolling
            Layout.fillWidth: true; Layout.fillHeight: true
            clip: true
            contentHeight: taskList.height
            boundsBehavior: Flickable.StopAtBounds
            Column {
                id: taskList
                width: scrolling.width
                spacing: 8
                Repeater {
                    model: todo.currentTasks()
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        readonly property bool overdue: todo.isOverdue(modelData)
                        width: taskList.width
                        height: todo.scheduleText(modelData).length ? 64 : 48
                        color: overdue ? "#454044" : "#85303034"
                        border.width: overdue ? 1 : 0
                        border.color: "#a18a90"
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 9; spacing: 10
                            Rectangle {
                                Layout.preferredWidth: 25; Layout.preferredHeight: 25
                                color: "#a0303034"; border.width: 1; border.color: "#66c8cdd4"
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.done ? "✓" : ((modelData.repeat && modelData.repeat !== "none") ? "↻" : "")
                                    color: "#f0f0f2"; font.pixelSize: 16
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: todo.toggleTask(index)
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 3
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.title
                                        color: modelData.done ? "#858b98" : "#f0f0f2"
                                        font.pixelSize: 13
                                        font.strikeout: modelData.done
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        visible: overdue
                                        text: "OVERDUE"; color: "#dcb2b2"
                                        font.bold: true; font.pixelSize: 10
                                    }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    visible: todo.scheduleText(modelData).length > 0
                                    text: todo.scheduleText(modelData)
                                    color: overdue ? "#dcb2b2" : "#939ba8"
                                    font.pixelSize: 11; elide: Text.ElideRight
                                }
                            }
                            Rectangle {
                                Layout.preferredWidth: 36; Layout.preferredHeight: 28
                                color: editMouse.containsMouse ? "#454b55" : "#a0303034"
                                border.width: 1; border.color: "#33c8cdd4"
                                Text { anchors.centerIn: parent; text: "✎"; color: "#f0f0f2"; font.pixelSize: 16 }
                                MouseArea {
                                    id: editMouse; anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: todo.editTask(index)
                                }
                            }
                            Rectangle {
                                Layout.preferredWidth: 30; Layout.preferredHeight: 28
                                color: "#a0303034"; border.width: 1; border.color: "#33c8cdd4"
                                Text { anchors.centerIn: parent; text: "×"; color: "#f0f0f2"; font.pixelSize: 20 }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: todo.removeTask(index)
                                }
                            }
                        }
                    }
                }
            }
        }
        Text {
            text: todo.message
            color: "#858b98"; font.pixelSize: 11
        }
    }
}
