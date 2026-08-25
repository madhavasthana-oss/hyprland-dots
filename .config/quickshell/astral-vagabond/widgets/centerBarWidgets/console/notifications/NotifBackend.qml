// NotifBackend.qml --- mako inbox (live + history) until the user clears
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
        if (snapshotProc.running)
            snapshotProc.running = false
        snapshotProc.running = true
    }

    function removeIdFromModel(id) {
        const key = String(id)
        for (let i = notifModel.count - 1; i >= 0; i--) {
            if (String(notifModel.get(i).notifId) === key)
                notifModel.remove(i)
        }
        syncCount()
    }

    function syncCount() {
        Globals.notifCount = notifModel.count
        const n = notifModel.count
        let msg = n === 0 ? "INBOX EMPTY" : (n + " IN INBOX")
        if (root.dnd)
            msg = "DND · " + msg
        else if (root.silent)
            msg = "SILENT · " + msg
        root.statusMsg = msg
    }

    function dismissAll() {
        for (let i = 0; i < notifModel.count; i++)
            Globals.notifClearId(notifModel.get(i).notifId)
        notifModel.clear()
        syncCount()
        dismissAllProc.running = true
    }

    function dismissId(id) {
        Globals.notifClearId(id)
        removeIdFromModel(id)
        dismissOne.idArg = String(id)
        dismissOne.running = true
    }

    function setSilent(on) {
        Globals.notifSilent = on
        root.silent = on
        if (on) {
            modeAdd.mode = "silent"
            modeAdd.running = true
            Globals.toast("Silent mode", "Notifications muted", "Notifications")
        } else {
            modeRemove.mode = "silent"
            modeRemove.running = true
            Globals.toast("Audible", "Silent mode off", "Notifications")
        }
        root.syncCount()
        root.refresh()
    }

    function setDnd(on) {
        Globals.notifDnd = on
        root.dnd = on
        if (on) {
            modeAdd.mode = "dnd"
            modeAdd.running = true
            Globals.toast("Do not disturb", "Toasts and inbox muted", "Notifications")
        } else {
            modeRemove.mode = "dnd"
            modeRemove.running = true
            Globals.toast("DND off", "Notifications visible", "Notifications")
        }
        root.syncCount()
        root.refresh()
    }

    function toggleSilent() { setSilent(!root.silent) }
    function toggleDnd()    { setDnd(!root.dnd) }

    function toRow(n) {
        return {
            notifId: n.id,
            appName: n.app_name || "unknown",
            summary: n.summary || "",
            body:    n.body || "",
            urgency: n.urgency || "normal"
        }
    }

    function ingestSnapshot(text) {
        let data
        try {
            data = JSON.parse(text.length ? text : "{}")
        } catch (e) {
            root.statusMsg = "PARSE ERROR"
            return
        }

        const active = Array.isArray(data.active) ? data.active : []
        const history = Array.isArray(data.history) ? data.history : []
        const incoming = active.concat(history)
        const rows = []
        const seen = ({})
        for (let i = 0; i < incoming.length; i++) {
            const n = incoming[i]
            if (!n || n.id === undefined || n.id === null)
                continue
            const key = String(n.id)
            if (seen[key])
                continue
            seen[key] = true
            if (!Globals.notifAcceptIncoming(n.id))
                continue
            rows.push(root.toRow(n))
        }
        Globals.notifCloseIncomingBatch()

        if (rows.length === notifModel.count) {
            let same = true
            for (let i = 0; i < rows.length; i++) {
                const a = notifModel.get(i)
                const b = rows[i]
                if (a.notifId !== b.notifId || a.summary !== b.summary
                        || a.body !== b.body || a.appName !== b.appName) {
                    same = false
                    break
                }
            }
            if (same) {
                syncCount()
                return
            }
        }

        notifModel.clear()
        for (let i = 0; i < rows.length; i++)
            notifModel.append(rows[i])
        syncCount()
    }

    Process {
        id: snapshotProc
        command: [
            "python3", "-c",
            "import json, subprocess as s\n"
            + "def load(cmd):\n"
            + "    try:\n"
            + "        d = json.loads(s.check_output(cmd, stderr=s.DEVNULL) or b'[]')\n"
            + "        return d if isinstance(d, list) else []\n"
            + "    except Exception:\n"
            + "        return []\n"
            + "print(json.dumps({'active': load(['makoctl', 'list', '-j']), 'history': load(['makoctl', 'history', '-j'])}))\n"
        ]
        stdout: StdioCollector {
            onStreamFinished: root.ingestSnapshot(text)
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
        command: ["makoctl", "dismiss", "--all", "--no-history"]
        onExited: root.refresh()
    }

    Process {
        id: dismissOne
        property string idArg: "0"
        command: ["makoctl", "dismiss", "-n", idArg, "--no-history"]
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
        interval: Globals.activeWidget === "notifications" ? 1000 : 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Connections {
        target: Globals
        function onActiveWidgetChanged() {
            if (Globals.activeWidget === "notifications")
                root.refresh()
        }
    }
}
