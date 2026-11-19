import Quickshell
import Quickshell.Io
import QtQuick

PopupWindow {
    id: popup
    property var barWindow: null
    property date currentDate: new Date()
    property date displayedMonth: new Date(currentDate.getFullYear(), currentDate.getMonth(), 1)
    property var weekDays: ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]
    property date selectedDate: new Date()
    property var tasks: []
    property bool tasksReady: false
    property string taskMessage: "Loading tasks..."
    property string inputError: ""
    property bool remindEarly: true
    property int editingIndex: -1

    implicitWidth: 342
    // Follow the real content height instead of reserving blank space.
    implicitHeight: calendarContent.implicitHeight + 36
    visible: false
    color: "transparent"
    grabFocus: true

    // Position in full bar-window coordinates, not item-local coordinates.
    // Top-left of popup is at the bar's horizontal center minus half popup width.
    anchor.window: popup.barWindow
    anchor.rect: Qt.rect(
        popup.barWindow ? Math.round((popup.barWindow.width - popup.implicitWidth) / 2) : 0,
        popup.barWindow ? popup.barWindow.height + 6 : 42,
        1, 1
    )
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right

    function shiftMonth(step) {
        displayedMonth = new Date(displayedMonth.getFullYear(), displayedMonth.getMonth() + step, 1)
        selectedDate = new Date(displayedMonth.getFullYear(), displayedMonth.getMonth(), 1)
        clearEditor()
    }
    function resetMonth() {
        currentDate = new Date()
        displayedMonth = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1)
        selectedDate = new Date(currentDate.getFullYear(), currentDate.getMonth(), currentDate.getDate())
        clearEditor()
    }
    function dateKey(date) {
        return Qt.formatDate(date, "yyyy-MM-dd")
    }
    function chooseDay(day) {
        if (day > 0) {
            selectedDate = new Date(displayedMonth.getFullYear(), displayedMonth.getMonth(), day)
            clearEditor()
        }
    }
    function clearEditor() {
        editingIndex = -1
        taskEntry.text = ""
        timeEntry.text = ""
        remindEarly = true
        inputError = ""
    }
    function beginEdit(index) {
        if (index < 0 || index >= tasks.length) return
        const task = tasks[index]
        editingIndex = index
        taskEntry.text = task.title
        timeEntry.text = task.time || ""
        remindEarly = task.remindMinutes !== 0
        inputError = ""
        taskEntry.forceActiveFocus()
    }
    function timeLabel(time) {
        if (!time || !/^([01]\d|2[0-3]):[0-5]\d$/.test(time)) return ""
        const bits = time.split(":")
        const hour = Number(bits[0])
        return ((hour % 12) || 12) + ":" + bits[1] + (hour >= 12 ? " PM" : " AM")
    }
    function dayHasTasks(day) {
        if (day <= 0) return false
        const key = dateKey(new Date(displayedMonth.getFullYear(), displayedMonth.getMonth(), day))
        return tasks.some(task => task.date === key)
    }
    function datedTasks() {
        const key = dateKey(selectedDate)
        const result = []
        for (let i = 0; i < tasks.length; i++) {
            if (tasks[i].date === key)
                result.push({index: i, title: tasks[i].title, done: tasks[i].done, time: tasks[i].time || "", repeat: tasks[i].repeat || "none"})
        }
        return result
    }
    function writeTasks(next) {
        if (!tasksReady) return
        tasks = next
        taskFile.setText(JSON.stringify({tasks: next}, null, 2) + "\n")
    }
    function addTask() {
        if (!tasksReady) return
        const title = taskEntry.text.trim()
        const clock = timeEntry.text.trim()
        if (!title || title.length > 200) {
            inputError = "Enter a task title"
            return
        }
        if (clock && !/^([01]\d|2[0-3]):[0-5]\d$/.test(clock)) {
            inputError = "Use 24-hour time, e.g. 15:30"
            return
        }
        const next = tasks.slice()
        const old = editingIndex >= 0 ? next[editingIndex] : null
        const update = Object.assign({}, old || {}, {
            title: title,
            done: old ? old.done : false,
            date: dateKey(selectedDate)
        })
        if (!update.uid)
            update.uid = String(Date.now()) + "-" + String(Math.floor(Math.random() * 1000000))
        if (clock) {
            update.time = clock
            update.remindMinutes = remindEarly ? 10 : 0
        } else {
            delete update.time
            delete update.remindMinutes
        }
        if (old) next[editingIndex] = update
        else next.push(update)
        writeTasks(next)
        clearEditor()
    }
    // Keep recurrence behavior identical to the Control Center.
    function dateValid(value) {
        if (!/^\d{4}-\d{2}-\d{2}$/.test(value || "")) return false
        const bits = value.split("-").map(Number)
        const dt = new Date(bits[0], bits[1] - 1, bits[2], 12)
        return dt.getFullYear() === bits[0] && dt.getMonth() === bits[1] - 1 && dt.getDate() === bits[2]
    }
    function nextRecurringDate(task) {
        if (!dateValid(task.date)) return ""
        const bits = task.date.split("-").map(Number)
        let dt = new Date(bits[0], bits[1] - 1, bits[2], 12)
        const current = new Date()
        const today = new Date(current.getFullYear(), current.getMonth(), current.getDate(), 12)
        const preferred = task.repeatDay || bits[2]
        for (let i = 0; i < 12000; i++) {
            if (task.repeat === "daily") dt.setDate(dt.getDate() + 1)
            else if (task.repeat === "weekly") dt.setDate(dt.getDate() + 7)
            else if (task.repeat === "monthly") {
                const year = dt.getFullYear()
                const month = dt.getMonth() + 1
                dt = new Date(year, month,
                    Math.min(preferred, new Date(year, month + 1, 0).getDate()), 12)
            } else return ""
            if (dt > today) return Qt.formatDate(dt, "yyyy-MM-dd")
        }
        return ""
    }
    function toggleTask(index) {
        if (!tasksReady || index < 0 || index >= tasks.length) return
        const next = tasks.slice()
        const task = next[index]
        if (!task.done && task.repeat && task.repeat !== "none") {
            const future = nextRecurringDate(task)
            if (future) {
                next[index] = Object.assign({}, task, {date: future, done: false})
                writeTasks(next)
                return
            }
        }
        next[index] = Object.assign({}, task, {done: !task.done})
        writeTasks(next)
    }
    function removeTask(index) {
        if (!tasksReady || index < 0 || index >= tasks.length) return
        const next = tasks.slice()
        next.splice(index, 1)
        writeTasks(next)
        clearEditor()
    }
    function calendarCellCount() {
        const year = displayedMonth.getFullYear()
        const month = displayedMonth.getMonth()
        const firstDayOffset = (new Date(year, month, 1).getDay() + 6) % 7
        const days = new Date(year, month + 1, 0).getDate()
        return Math.ceil((firstDayOffset + days) / 7) * 7
    }
    function dayNumber(index) {
        let offset = (displayedMonth.getDay() + 6) % 7
        let number = index - offset + 1
        let count = new Date(displayedMonth.getFullYear(), displayedMonth.getMonth() + 1, 0).getDate()
        return number >= 1 && number <= count ? number : 0
    }
    function isToday(number) {
        return number > 0 && displayedMonth.getFullYear() === currentDate.getFullYear()
            && displayedMonth.getMonth() === currentDate.getMonth() && number === currentDate.getDate()
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        enabled: popup.visible
        onActivated: popup.visible = false
    }
    Timer {
        interval: 30000
        repeat: true
        running: popup.visible
        onTriggered: popup.currentDate = new Date()
    }
    onVisibleChanged: {
        if (visible) {
            resetMonth()
            taskFile.reload()
        }
    }

    // Shared with the Control Center To-Do overlay. Old entries without dates remain valid.
    FileView {
        id: taskFile
        path: Quickshell.env("HOME") + "/.local/state/quickshell-control/tasks.json"
        atomicWrites: true
        blockWrites: true
        watchChanges: true
        onFileChanged: taskFile.reload()
        onLoaded: {
            try {
                const data = JSON.parse(taskFile.text())
                if (!data || !Array.isArray(data.tasks))
                    throw new Error("Missing tasks array")
                for (const task of data.tasks) {
                    if (!task || typeof task.title !== "string" || typeof task.done !== "boolean")
                        throw new Error("Invalid task")
                }
                popup.tasks = data.tasks
                popup.tasksReady = true
                popup.taskMessage = ""
            } catch (error) {
                popup.tasksReady = false
                popup.taskMessage = "Task file error"
                console.warn("Calendar task load failed:", error)
            }
        }
        onLoadFailed: error => {
            popup.tasksReady = false
            popup.taskMessage = "Task file unavailable"
            console.warn("Calendar task load failed:", error)
        }
        onSaveFailed: error => {
            popup.taskMessage = "Save failed"
            console.warn("Calendar task save failed:", error)
        }
        onSaved: popup.taskMessage = ""
    }

    Rectangle {
        anchors.fill: parent
        radius: 0
        color: Qt.rgba(0.055, 0.059, 0.07, 0.70)
        border.color: "#565b64"
        border.width: 1
    }

    Column {
        id: calendarContent
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        Column {
            spacing: 5
            Text {
                text: Qt.formatDateTime(popup.currentDate, "h:mm AP")
                color: "#f0f0f2"
                font.family: "Tintoretto"
                font.pixelSize: 35
                font.weight: Font.DemiBold
            }
            Text {
                text: Qt.formatDateTime(popup.currentDate, "dddd, MMMM d, yyyy")
                color: "#aeb4bf"
                font.family: "Inter"
                font.pixelSize: 12
            }
        }

        Rectangle { width: parent.width; height: 1; color: "#565b64" }

        Item {
            width: parent.width
            height: 29
            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDate(popup.displayedMonth, "MMMM yyyy")
                font.family: "Tintoretto"
                color: "#f0f0f2"
                font.pixelSize: 20
                font.bold: true
            }
            Row {
                anchors.right: parent.right
                height: parent.height
                spacing: 8
                Repeater {
                    model: ["‹", "›"]
                    delegate: Rectangle {
                        required property int index
                        required property string modelData
                        width: 30; height: 29; radius: 0
                        color: pointer.containsMouse ? "#505058" : "#303034"
                        border.color: "#565b64"
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: "#f0f0f2"
                            font.pixelSize: 21
                        }
                        MouseArea {
                            id: pointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: popup.shiftMonth(index === 0 ? -1 : 1)
                        }
                    }
                }
            }
        }

        Grid {
            width: parent.width
            columns: 7
            rowSpacing: 7
            columnSpacing: 0
            Repeater {
                model: popup.weekDays
                delegate: Item {
                    required property string modelData
                    width: 43
                    height: 20
                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: "#979da8"
                        font.pixelSize: 10
                        font.bold: true
                    }
                }
            }
            Repeater {
                model: popup.calendarCellCount()
                delegate: Rectangle {
                    required property int index
                    readonly property int day: popup.dayNumber(index)
                    width: 43
                    height: 26
                    radius: 0
                    readonly property bool selected: day > 0 &&
                        popup.dateKey(popup.selectedDate) ===
                        popup.dateKey(new Date(popup.displayedMonth.getFullYear(), popup.displayedMonth.getMonth(), day))
                    readonly property bool marked: popup.dayHasTasks(day)
                    color: selected ? "#d1d5dc" : (dateMouse.containsMouse && day > 0 ? "#39414b" : "transparent")
                    border.width: popup.isToday(day) && !selected ? 1 : 0
                    border.color: "#b3bcc8"
                    Text {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: marked ? -3 : 0
                        text: day ? day : ""
                        color: selected ? "#15171c" : "#e0e3e8"
                        font.pixelSize: 12
                        font.bold: selected || popup.isToday(day)
                    }
                    Rectangle {
                        width: 3; height: 3; radius: 1.5
                        visible: marked
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 3
                        color: selected ? "#27303a" : "#d1d5dc"
                    }
                    MouseArea {
                        id: dateMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: day > 0
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.chooseDay(day)
                    }
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: "#565b64" }

        Item {
            width: parent.width
            height: 25
            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDate(popup.selectedDate, "ddd, MMM d")
                color: "#f0f0f2"
                font.family: "Tintoretto"
                font.pixelSize: 19
            }
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: popup.datedTasks().filter(task => !task.done).length + " remaining"
                color: "#aeb4bf"
                font.pixelSize: 10
            }
        }

        Row {
            width: parent.width
            height: 32
            spacing: 8
            Rectangle {
                width: parent.width - 40
                height: 32
                radius: 0
                color: "#85303034"
                border.color: "#565b64"
                border.width: 1
                TextInput {
                    id: taskEntry
                    anchors.fill: parent
                    anchors.margins: 8
                    verticalAlignment: TextInput.AlignVCenter
                    color: "#f0f0f2"
                    selectionColor: "#738190"
                    font.family: "Inter"
                    font.pixelSize: 12
                    enabled: popup.tasksReady
                    maximumLength: 200
                    clip: true
                    onAccepted: popup.addTask()
                }
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Add a task for this day..."
                    color: "#939ba8"
                    font.pixelSize: 11
                    visible: taskEntry.text.length === 0 && !taskEntry.activeFocus
                }
            }
            Rectangle {
                width: 32; height: 32; radius: 0
                color: addMouse.containsMouse ? "#505058" : "#303034"
                border.color: "#565b64"
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: popup.editingIndex >= 0 ? "✓" : "+"
                    color: "#f0f0f2"
                    font.pixelSize: 20
                }
                MouseArea {
                    id: addMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: popup.tasksReady
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.addTask()
                }
            }
        }

        Row {
            width: parent.width
            height: 28
            spacing: 8
            Text {
                text: "REMIND AT"
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                color: "#aeb4bf"
                font.pixelSize: 10
            }
            Rectangle {
                width: 63; height: 26
                color: "#85303034"
                border.color: "#565b64"
                border.width: 1
                TextInput {
                    id: timeEntry
                    anchors.fill: parent
                    anchors.margins: 6
                    verticalAlignment: TextInput.AlignVCenter
                    maximumLength: 5
                    font.pixelSize: 11
                    color: "#f0f0f2"
                    onAccepted: popup.addTask()
                }
                Text {
                    anchors.centerIn: parent
                    visible: timeEntry.text.length === 0 && !timeEntry.activeFocus
                    text: "HH:MM"
                    color: "#939ba8"
                    font.pixelSize: 11
                }
            }
            Rectangle {
                width: 102; height: 26
                border.width: 1
                border.color: "#565b64"
                color: earlyMouse.containsMouse ? "#505058" : "#303034"
                Text {
                    anchors.centerIn: parent
                    text: popup.remindEarly ? "10 MIN EARLY" : "AT DUE TIME"
                    color: "#f0f0f2"
                    font.pixelSize: 10
                }
                MouseArea {
                    id: earlyMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.remindEarly = !popup.remindEarly
                }
            }
            Text {
                text: popup.editingIndex >= 0 ? "EDIT" : "24H"
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                color: "#939ba8"
                font.pixelSize: 10
            }
        }

        Flickable {
            id: taskScroll
            width: parent.width
            // Grow with tasks, but cap the list so longer days can scroll.
            height: Math.min(116, Math.max(24, taskRows.implicitHeight))
            clip: true
            contentHeight: taskRows.height
            boundsBehavior: Flickable.StopAtBounds
            Column {
                id: taskRows
                width: taskScroll.width
                spacing: 5
                Text {
                    visible: popup.datedTasks().length === 0
                    height: visible ? 24 : 0
                    text: popup.tasksReady ? "No tasks for this date" : popup.taskMessage
                    color: "#939ba8"
                    font.pixelSize: 11
                }
                Repeater {
                    model: popup.datedTasks()
                    delegate: Rectangle {
                        required property var modelData
                        width: taskRows.width
                        height: 31
                        color: "#34383e"
                        radius: 0
                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 5
                            anchors.rightMargin: 5
                            spacing: 8
                            Rectangle {
                                width: 19; height: 19
                                radius: 0
                                anchors.verticalCenter: parent.verticalCenter
                                color: "#303034"
                                border.width: 1
                                border.color: "#8a939e"
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.done ? "✓" : ""
                                    color: "#f0f0f2"
                                    font.pixelSize: 14
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: popup.toggleTask(modelData.index)
                                }
                            }
                            Text {
                                width: taskRows.width - 98
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                text: modelData.title + (modelData.time ? " · " + popup.timeLabel(modelData.time) : "")
                                     + (modelData.repeat !== "none" ? " · " + modelData.repeat : "")
                                color: modelData.done ? "#939ba8" : "#f0f0f2"
                                font.pixelSize: 11
                                font.strikeout: modelData.done
                                elide: Text.ElideRight
                            }
                            Text {
                                width: 17
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                text: "✎"
                                color: editMouse.containsMouse ? "#ffffff" : "#aeb4bf"
                                font.pixelSize: 14
                                MouseArea {
                                    id: editMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: popup.beginEdit(modelData.index)
                                }
                            }
                            Text {
                                width: 18
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                text: "×"
                                color: deleteMouse.containsMouse ? "#ffffff" : "#aeb4bf"
                                font.pixelSize: 17
                                MouseArea {
                                    id: deleteMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: popup.removeTask(modelData.index)
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: 17
            Text {
                text: "TODAY"
                color: todayMouse.containsMouse ? "#ffffff" : "#aeb4bf"
                font.pixelSize: 11
                font.bold: true
                MouseArea {
                    id: todayMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.resetMonth()
                }
            }
            Text {
                anchors.right: parent.right
                text: popup.inputError || (popup.tasksReady ? "TASK PLANNER" : popup.taskMessage)
                color: "#939ba8"
                font.pixelSize: 10
            }
        }
    }
}