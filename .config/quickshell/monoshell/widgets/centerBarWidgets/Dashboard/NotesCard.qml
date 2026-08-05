// NotesCard.qml --- freeform notes, persisted
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../.."

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

    readonly property string storePath: Quickshell.env("HOME") + "/.cache/monoshell-notes.txt"
    property string statusMsg: ""

    Component.onCompleted: loadProc.running = true

    function save() {
        saveProc.payload = noteArea.text
        saveProc.running = true
    }

    Process {
        id: loadProc
        command: ["bash", "-c", "cat '" + root.storePath + "' 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                noteArea.text = text
            }
        }
    }

    Process {
        id: saveProc
        property string payload: ""
        command: [
            "python3", "-c",
            "import pathlib,sys; p=pathlib.Path(sys.argv[1]); p.parent.mkdir(parents=True, exist_ok=True); p.write_text(sys.argv[2], encoding='utf-8')",
            root.storePath,
            payload
        ]
        onExited: (code) => {
            root.statusMsg = code === 0 ? "SAVED" : "SAVE FAILED"
            clearStatus.restart()
        }
    }

    Timer {
        id: clearStatus
        interval: 2000
        onTriggered: root.statusMsg = ""
    }

    // debounce autosave
    Timer {
        id: autoSave
        interval: 1500
        onTriggered: root.save()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.paddingH
        spacing: Tokens.spacingXs

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "NOTES"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.accent
            }
            Item { Layout.fillWidth: true }
            Text {
                text: root.statusMsg
                font.family: Theme.fontMono
                font.pixelSize: Tokens.fontSizeTiny
                color: Theme.textSecondary
            }
            Rectangle {
                Layout.preferredHeight: Tokens.listRowHeight
                Layout.preferredWidth: saveLbl.implicitWidth + 2 * Tokens.paddingH
                radius: Tokens.radiusSm
                color: Theme.bgElevated
                border.color: Theme.borderActive
                border.width: Tokens.strokeWidth
                Text {
                    id: saveLbl
                    anchors.centerIn: parent
                    text: "SAVE"
                    font.family: Theme.fontDisplay
                    font.pixelSize: Tokens.fontSizeLabel
                    color: Theme.accent
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.save()
                }
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            TextArea {
                id: noteArea
                width: parent.width
                wrapMode: TextEdit.Wrap
                color: Theme.textPrimary
                font.family: Theme.fontMono
                font.pixelSize: Tokens.fontSizeSmall
                selectByMouse: true
                background: null
                onTextChanged: autoSave.restart()
            }
        }
    }
}
