/*
  Console launcher entries from DesktopEntries (apps + desktop actions).
  title, classification, description, icon, desktopId, actionId
*/
import QtQuick
import Quickshell

Item {
    id: root

    property string query: ""
    property alias model: appModel
    property int matchCount: 0

    ListModel { id: appModel }

    function apps() {
        const m = DesktopEntries.applications
        if (!m)
            return []
        if (m.values)
            return m.values
        return []
    }

    function haystack(entry, action) {
        const bits = []
        if (entry) {
            bits.push(entry.name || "")
            bits.push(entry.genericName || "")
            bits.push(entry.comment || "")
            bits.push(entry.id || "")
            const keys = entry.keywords || []
            for (let i = 0; i < keys.length; i++)
                bits.push(keys[i])
            const cats = entry.categories || []
            for (let j = 0; j < cats.length; j++)
                bits.push(cats[j])
        }
        if (action) {
            bits.push(action.name || "")
            bits.push(action.id || "")
        }
        return bits.join(" ").toLowerCase()
    }

    function matches(hay, q) {
        if (!q || !q.length)
            return true
        const parts = q.toLowerCase().trim().split(/\s+/).filter(s => s.length)
        for (let i = 0; i < parts.length; i++) {
            if (hay.indexOf(parts[i]) < 0)
                return false
        }
        return true
    }

    function classificationOf(entry) {
        const generic = (entry.genericName || "").trim()
        if (generic.length)
            return generic
        const cats = entry.categories || []
        if (cats.length && String(cats[0]).length)
            return String(cats[0])
        return "Application"
    }

    function rowForApp(entry) {
        return {
            title: entry.name || entry.id || "app",
            classification: root.classificationOf(entry),
            description: entry.comment || "",
            icon: entry.icon || "",
            desktopId: entry.id || "",
            actionId: "",
            isApplet: false
        }
    }

    function rowForAction(entry, action) {
        return {
            title: action.name || action.id || "action",
            classification: entry.name || "Applet",
            description: "Applet",
            icon: action.icon || entry.icon || "",
            desktopId: entry.id || "",
            actionId: action.id || "",
            isApplet: true
        }
    }

    function rebuild() {
        const q = String(root.query || "").trim()
        const list = root.apps()
        const rows = []
        for (let i = 0; i < list.length; i++) {
            const entry = list[i]
            if (!entry)
                continue
            if (entry.noDisplay)
                continue
            if (root.matches(root.haystack(entry, null), q))
                rows.push(root.rowForApp(entry))
            const actions = entry.actions || []
            for (let a = 0; a < actions.length; a++) {
                const act = actions[a]
                if (!act)
                    continue
                const name = (act.name || "").trim()
                if (!name.length)
                    continue
                if (root.matches(root.haystack(entry, act), q))
                    rows.push(root.rowForAction(entry, act))
            }
        }
        rows.sort((x, y) => {
            if (x.isApplet !== y.isApplet)
                return x.isApplet ? 1 : -1
            return String(x.title).localeCompare(String(y.title), undefined, { sensitivity: "base" })
        })

        appModel.clear()
        for (let r = 0; r < rows.length; r++)
            appModel.append(rows[r])
        root.matchCount = rows.length
    }

    function launchIndex(index) {
        if (index < 0 || index >= appModel.count)
            return false
        const row = appModel.get(index)
        if (!row)
            return false
        const entry = DesktopEntries.byId(row.desktopId)
        if (!entry)
            return false
        if (row.actionId && String(row.actionId).length) {
            const actions = entry.actions || []
            for (let i = 0; i < actions.length; i++) {
                if (String(actions[i].id) === String(row.actionId)) {
                    actions[i].execute()
                    return true
                }
            }
            return false
        }
        entry.execute()
        return true
    }

    onQueryChanged: rebuild()

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() { root.rebuild() }
    }

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { root.rebuild() }
    }

    Component.onCompleted: rebuild()
}
