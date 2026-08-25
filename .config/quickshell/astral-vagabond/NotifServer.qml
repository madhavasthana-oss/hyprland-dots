pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property alias inbox: inboxModel
    property alias toasts: toastModel
    property string statusMsg: "INBOX EMPTY"
    property var live: ({})

    readonly property int maxToasts: Tokens.toastMaxVisible

    NotificationServer {
        id: server
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        actionIconsSupported: true
        imageSupported: true
        persistenceSupported: true
        keepOnReload: true

        onNotification: (notification) => root.ingest(notification)
    }

    ListModel { id: inboxModel }
    ListModel { id: toastModel }

    function trackedList() {
        const m = server.trackedNotifications
        if (!m)
            return []
        if (m.values)
            return m.values
        return []
    }

    function urgencyName(u) {
        if (u === NotificationUrgency.Critical)
            return "critical"
        if (u === NotificationUrgency.Low)
            return "low"
        return "normal"
    }

    function timeoutMs(n) {
        if (!n)
            return Tokens.toastTimeoutMs
        if (n.urgency === NotificationUrgency.Critical)
            return 0
        const t = n.expireTimeout
        if (t === undefined || t === null || t < 0)
            return Tokens.toastTimeoutMs
        if (t === 0)
            return 0
        // spec is ms; Quickshell documents seconds — accept both
        if (t > 100)
            return Math.round(t)
        return Math.round(t * 1000)
    }

    function remember(n) {
        if (!n)
            return
        const next = Object.assign({}, root.live)
        next[String(n.id)] = n
        root.live = next
    }

    function forget(id) {
        const key = String(id)
        if (!root.live[key])
            return
        const next = Object.assign({}, root.live)
        delete next[key]
        root.live = next
    }

    function lookup(id) {
        const key = String(id)
        if (root.live[key])
            return root.live[key]
        const list = root.trackedList()
        for (let i = 0; i < list.length; i++) {
            if (list[i] && String(list[i].id) === key)
                return list[i]
        }
        return null
    }

    function ingest(n) {
        if (!n)
            return
        if (Globals.notifDnd) {
            n.tracked = false
            return
        }
        n.tracked = true
        root.remember(n)
        if (!n.transient && !n.lastGeneration)
            root.enqueueToast(n)
        root.rebuildInbox()
    }

    function enqueueToast(n) {
        if (!n || Globals.notifSilent)
            return
        if (n.transient && n.urgency !== NotificationUrgency.Critical) {
            // still show transients as toasts, skip inbox via rebuild filter
        }
        root.hideToast(n.id)
        while (toastModel.count >= root.maxToasts)
            toastModel.remove(toastModel.count - 1)
        toastModel.insert(0, {
            notifId: n.id,
            appName: n.appName || "notification",
            summary: n.summary || "",
            body: n.body || "",
            urgency: root.urgencyName(n.urgency),
            icon: n.appIcon || n.image || "",
            timeoutMs: root.timeoutMs(n)
        })
    }

    function hideToast(id) {
        const key = String(id)
        for (let i = toastModel.count - 1; i >= 0; i--) {
            if (String(toastModel.get(i).notifId) === key)
                toastModel.remove(i)
        }
    }

    function rowOf(n) {
        return {
            notifId: n.id,
            appName: n.appName || "unknown",
            summary: n.summary || "",
            body: n.body || "",
            urgency: root.urgencyName(n.urgency),
            icon: n.appIcon || n.image || ""
        }
    }

    function rebuildInbox() {
        const list = root.trackedList()
        const rows = []
        for (let i = 0; i < list.length; i++) {
            const n = list[i]
            if (!n)
                continue
            if (n.transient)
                continue
            const key = String(n.id)
            if (Globals.notifClearedIds[key])
                continue
            root.remember(n)
            rows.push(root.rowOf(n))
        }
        if (rows.length === inboxModel.count) {
            let same = true
            for (let r = 0; r < rows.length; r++) {
                const a = inboxModel.get(r)
                const b = rows[r]
                if (String(a.notifId) !== String(b.notifId)
                        || a.summary !== b.summary
                        || a.body !== b.body
                        || a.appName !== b.appName) {
                    same = false
                    break
                }
            }
            if (same) {
                root.syncCount()
                return
            }
        }
        inboxModel.clear()
        for (let r = 0; r < rows.length; r++)
            inboxModel.append(rows[r])
        root.syncCount()
    }

    function syncInbox() {
        root.rebuildInbox()
    }

    function syncCount() {
        Globals.notifCount = inboxModel.count
        let msg = inboxModel.count === 0 ? "INBOX EMPTY" : (inboxModel.count + " IN INBOX")
        if (Globals.notifDnd)
            msg = "DND · " + msg
        else if (Globals.notifSilent)
            msg = "SILENT · " + msg
        root.statusMsg = msg
    }

    function dismissId(id) {
        Globals.notifClearId(id)
        root.hideToast(id)
        const n = root.lookup(id)
        if (n)
            n.dismiss()
        else
            root.rebuildInbox()
        root.forget(id)
    }

    function dismissAll() {
        const list = root.trackedList().slice()
        toastModel.clear()
        for (let i = 0; i < list.length; i++) {
            const n = list[i]
            if (!n)
                continue
            Globals.notifClearId(n.id)
            n.dismiss()
        }
        inboxModel.clear()
        root.live = ({})
        root.syncCount()
    }

    function invokeId(id) {
        const n = root.lookup(id)
        if (!n)
            return
        const acts = n.actions || []
        if (acts.length)
            acts[0].invoke()
        if (!n.resident)
            root.dismissId(id)
        else
            root.hideToast(id)
    }

    function setSilent(on) {
        Globals.notifSilent = !!on
        if (on)
            toastModel.clear()
        root.syncCount()
    }

    function setDnd(on) {
        Globals.notifDnd = !!on
        if (on)
            toastModel.clear()
        root.syncCount()
    }

    function toggleSilent() {
        const next = !Globals.notifSilent
        root.setSilent(next)
        if (!next)
            Globals.toast("Audible", "Silent mode off", "Notifications")
    }

    function toggleDnd() {
        const next = !Globals.notifDnd
        root.setDnd(next)
        if (!next)
            Globals.toast("DND off", "Notifications visible", "Notifications")
    }

    Connections {
        target: server.trackedNotifications
        function onValuesChanged() { root.rebuildInbox() }
        function onObjectRemovedPost(object, index) {
            if (object)
                root.hideToast(object.id)
            root.rebuildInbox()
        }
    }

    Component.onCompleted: {
        root.rebuildInbox()
        root.syncCount()
    }
}
