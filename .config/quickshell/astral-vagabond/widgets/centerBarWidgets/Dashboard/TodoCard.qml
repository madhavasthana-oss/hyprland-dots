// TodoCard.qml --- lightweight mission checklist
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../.."
import "../../../utils"

Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.preferredHeight: 1
    Layout.minimumHeight: 0
    Layout.minimumWidth: 0
    radius: Tokens.radiusMd
    color: Theme.bgSurface
    border.color: Theme.borderIdle
    border.width: Tokens.strokeWidth
    clip: true

    ListModel { id: todoModel }

    readonly property string storePath: Quickshell.env("HOME") + "/.cache/astral-vagabond-todos.json"

    Component.onCompleted: loadProc.running = true

    function addTodo(text) {
        const t = (text || "").trim()
        if (!t.length)
            return
        todoModel.append({ text: t, done: false })
        inputField.text = ""
        save()
    }

    function toggle(i) {
        todoModel.setProperty(i, "done", !todoModel.get(i).done)
        save()
    }

    function removeAt(i) {
        todoModel.remove(i)
        save()
    }

    function save() {
        let arr = []
        for (let i = 0; i < todoModel.count; i++) {
            const r = todoModel.get(i)
            arr.push({ text: r.text, done: r.done })
        }
        saveProc.payload = JSON.stringify(arr)
        saveProc.running = true
    }

    Process {
        id: loadProc
        command: ["bash", "-c", "cat '" + root.storePath + "' 2>/dev/null || echo '[]'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const arr = JSON.parse(text.length ? text : "[]")
                    todoModel.clear()
                    for (let i = 0; i < arr.length; i++)
                        todoModel.append({ text: arr[i].text || "", done: !!arr[i].done })
                } catch (e) {
                    todoModel.clear()
                }
            }
        }
    }

    Process {
        id: saveProc
        property string payload: "[]"
        command: [
            "python3", "-c",
            "import pathlib,sys; pathlib.Path(sys.argv[1]).write_text(sys.argv[2], encoding='utf-8')",
            root.storePath,
            payload
        ]
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.paddingH
        spacing: Tokens.spacingXs

        Text {
            text: "TODO"
            font.family: Theme.fontDisplay
            font.pixelSize: Tokens.fontSizeLabel
            color: Theme.accent
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Tokens.spacingXss
            model: todoModel
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            interactive: contentHeight > height

            ScrollBar.vertical: MonoScrollBar {}

            // Explicit height so wrapped multi-line rows scroll correctly
            delegate: Item {
                width: Math.max(0, list.width
                    - (list.contentHeight > list.height
                        ? Tokens.borderXs + Tokens.spacingXss + 2
                        : 0))
                height: row.implicitHeight

                RowLayout {
                    id: row
                    width: parent.width
                    spacing: Tokens.spacingXs

                    Rectangle {
                        Layout.preferredWidth: Tokens.iconSizeMedium
                        Layout.preferredHeight: Tokens.iconSizeMedium
                        Layout.alignment: Qt.AlignTop
                        radius: Tokens.radiusSm
                        color: model.done ? Theme.bgElevated : Theme.bgPrimary
                        border.color: model.done ? Theme.borderActive : Theme.borderIdle
                        border.width: Tokens.strokeWidth
                        Text {
                            anchors.centerIn: parent
                            text: model.done ? "✓" : ""
                            color: Theme.accent
                            font.pixelSize: Tokens.fontSizeTiny
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggle(index)
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: model.text
                        font.family: Theme.fontMono
                        font.pixelSize: Tokens.fontSizeSmall
                        color: model.done ? Theme.textDim : Theme.textPrimary
                        font.strikeout: model.done
                        wrapMode: Text.WordWrap
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            // Don't steal wheel / flick from ListView
                            propagateComposedEvents: true
                            onClicked: (mouse) => {
                                root.toggle(index)
                                mouse.accepted = true
                            }
                            onPressAndHold: root.removeAt(index)
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: list.count === 0
                text: "NO MISSIONS"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.textDim
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacingXs

            TextField {
                id: inputField
                Layout.fillWidth: true
                placeholderText: "add mission..."
                color: Theme.textPrimary
                placeholderTextColor: Theme.textDim
                font.family: Theme.fontMono
                font.pixelSize: Tokens.fontSizeSmall
                background: Rectangle {
                    color: Theme.bgPrimary
                    radius: Tokens.radiusSm
                    border.color: Theme.borderIdle
                    border.width: Tokens.strokeWidth
                }
                onAccepted: root.addTodo(text)
            }

            Rectangle {
                Layout.preferredHeight: Tokens.actionBtnHeight
                Layout.preferredWidth: addLbl.implicitWidth + 2 * Tokens.paddingH
                radius: Tokens.radiusSm
                color: Theme.bgElevated
                border.color: Theme.borderActive
                border.width: Tokens.strokeWidth
                Text {
                    id: addLbl
                    anchors.centerIn: parent
                    text: "ADD"
                    font.family: Theme.fontDisplay
                    font.pixelSize: Tokens.fontSizeLabel
                    color: Theme.accent
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.addTodo(inputField.text)
                }
            }
        }
    }
}
