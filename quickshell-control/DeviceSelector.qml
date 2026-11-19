pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls

ComboBox {
    id: selector
    implicitHeight: 32
    leftPadding: 12
    rightPadding: 28
    displayText: count ? currentText : "No devices available"
    contentItem: Text {
        text: selector.displayText
        color: selector.enabled ? "#f0f0f2" : "#939ba8"
        font.pixelSize: 11
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: Rectangle {
        color: "#303034"
        radius: 0
        border.color: selector.visualFocus ? "#c8cdd4" : "#33c8cdd4"
        border.width: selector.visualFocus ? 2 : 1
    }
    indicator: Text {
        x: selector.width - width - 12
        anchors.verticalCenter: parent.verticalCenter
        text: "⌄"
        color: "#c8cdd4"
    }
    delegate: ItemDelegate {
        id: deviceDelegate
        required property int index
        width: selector.width
        highlighted: selector.highlightedIndex === index
        contentItem: Text {
            text: selector.textAt(deviceDelegate.index)
            color: "#f0f0f2"
            font.pixelSize: 11
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle { color: deviceDelegate.highlighted ? "#41414a" : "#29292e"; radius: 0}
    }
    popup: Popup {
        y: selector.height + 4
        width: selector.width
        padding: 4
        implicitHeight: Math.min(list.contentHeight + 8, 248)
        contentItem: ListView {
            id: list
            clip: true
            model: selector.popup.visible ? selector.delegateModel : null
            currentIndex: selector.highlightedIndex
            ScrollBar.vertical: ScrollBar {}
        }
        background: Rectangle { color: "#29292e"; radius: 0; border.color: "#414651" }
    }
}
