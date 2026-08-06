// NotifBackend.qml --- mako list / dismiss / silent / dnd
import QtQuick
import Quickshell
import Quickshell.Io
import "../../../.."

Item {
    id: root

    property string statusMsg: ""
    property bool silent: Globals.notifSilent
    property bool dnd: Globals.notifDnd

    ListModel { id: notifModel }
    property alias notifications: notifModel

    Component.onCompleted: {
        modeQuery.running = true
        refresh()
    }

    function refresh() {
        listProc.running = true
    }

    function dismissAll() {
        dismissAllProc.running = true
    }

    function dismissId(id) {
        dismissOne.idArg = String(id)
        dismissOne.running = true
    }

    function setSilent(on) {
        Globals.notifSilent = on
        root.silent = on
        if (on) {
            modeAdd.mode = "silent"
            modeAdd.running = true
            root.statusMsg = "SILENT MODE"
            Globals.toast("Silent mode", "Notifications muted", "Notifications")
        } else {
            modeRemove.mode = "silent"
            modeRemove.running = true
            root.statusMsg = "AUDIBLE"
            Globals.toast("Audible", "Silent mode off", "Notifications")
        }
    }

    function setDnd(on) {
        Globals.notifDnd = on
        root.dnd = on
        if (on) {
            modeAdd.mode = "dnd"
            modeAdd.running = true
            root.statusMsg = "DO NOT DISTURB"
            Globals.toast("Do not disturb", "Notifications hidden", "Notifications")
        } else {
            modeRemove.mode = "dnd"
            modeRemove.running = true
            root.statusMsg = "DND OFF"
            Globals.toast("DND off", "Notifications visible", "Notifications")
        }
    }

    function toggleSilent() { setSilent(!root.silent) }
    function toggleDnd()    { setDnd(!root.dnd) }

    function parseList(text) {
        notifModel.clear()
        try {
            const arr = JSON.parse(text)
            if (!Array.isArray(arr))
                return
            for (let i = 0; i < arr.length; i++) {
                const n = arr[i]
                notifModel.append({
                    notifId: n.id,
                    appName: n.app_name || "unknown",
                    summary: n.summary || "",
                    body:    n.body || "",
                    urgency: n.urgency || "normal"
                })
            }
            root.statusMsg = notifModel.count + " ACTIVE"
            Globals.notifCount = notifModel.count
        } catch (e) {
            root.statusMsg = "PARSE ERROR"
        }
    }

    Process {
        id: listProc
        command: ["makoctl", "list", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root.parseList(text.length ? text : "[]")
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length)
                    root.statusMsg = "MAKO? " + text.trim()
            }
        }
    }

    Process {
        id: dismissAllProc
        command: ["makoctl", "dismiss", "--all"]
        onExited: root.refresh()
    }

    Process {
        id: dismissOne
        property string idArg: "0"
        command: ["makoctl", "dismiss", "-n", idArg]
        onExited: root.refresh()
    }

    Process {
        id: modeQuery
        command: ["makoctl", "mode"]
        stdout: StdioCollector {
            onStreamFinished: {
                const modes = text.trim().split(/\s+/)
                root.silent = modes.indexOf("silent") >= 0
                root.dnd = modes.indexOf("dnd") >= 0
                Globals.notifSilent = root.silent
                Globals.notifDnd = root.dnd
            }
        }
    }

    Process {
        id: modeAdd
        property string mode: "dnd"
        command: ["makoctl", "mode", "-a", mode]
        onExited: modeQuery.running = true
    }

    Process {
        id: modeRemove
        property string mode: "dnd"
        command: ["makoctl", "mode", "-r", mode]
        onExited: modeQuery.running = true
    }

    Timer {
        interval: 3000
        running: root.visible
        repeat: true
        onTriggered: root.refresh()
    }
}
