// WorkspaceHub.qml --- live hyprctl client list + Lua-era Hyprland move/focus
// Hyprland 0.56+ with hyprland.lua requires hl.dsp.* forms. Classic dispatchers
// (workspace N, movetoworkspacesilent, focuswindow) fail with:
//   "dispatch in lua is a shorthand for hl.dispatch(...)"
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

Singleton {
    id: root

    ListModel { id: clientModel }
    property alias clients: clientModel

    // Focused workspace clients (plain JS array for strip/board bindings)
    property var focusedClients: []
    // Map workspaceId (string key) → array of client objects
    property var clientsByWorkspace: ({})

    property int focusedWorkspaceId: Hyprland.focusedWorkspace?.id ?? 1
    property int screenW: Tokens.screenWidth > 0 ? Tokens.screenWidth : 1920
    property int screenH: Tokens.screenHeight > 0 ? Tokens.screenHeight : 1080
    property bool refreshing: false
    // Set while a board chip is mid-drag so poll won't rebuild the model
    property bool dragActive: false

    // class → themed icon URL. Same DesktopEntries catalog SUPER+A console uses.
    property var iconCache: ({})

    // Highest workspace id seen with clients (or focused); grows with infinite nav
    property int maxWorkspace: Globals.workspaceBankSize

    // Active bank (page of N workspaces): 1–10, 11–20, 21–30, …
    readonly property int bankSize: Math.max(1, Globals.workspaceBankSize)
    readonly property int bankStart: bankStartFor(focusedWorkspaceId)
    readonly property int bankEnd: bankStart + bankSize - 1
    // 0-based bank index (0 → 1–10, 1 → 11–20, …)
    readonly property int bankIndex: Math.max(0, Math.floor((Math.max(1, focusedWorkspaceId) - 1) / bankSize))

    // Hyprland 0.56 lua config — classic string dispatchers do not work.
    // Always use hl.dsp.* (verified working via hyprctl dispatch).
    readonly property bool useLuaDispatch: true

    function bankStartFor(wsId) {
        const n = root.bankSize
        const id = Math.max(1, parseInt(wsId) || 1)
        return Math.floor((id - 1) / n) * n + 1
    }

    function bankEndFor(wsId) {
        return root.bankStartFor(wsId) + root.bankSize - 1
    }

    function bankIndexFor(wsId) {
        const n = root.bankSize
        const id = Math.max(1, parseInt(wsId) || 1)
        return Math.floor((id - 1) / n)
    }

    // 0-based slot within the bank for layout (WS 12 → 1 when bank 11–20)
    function bankSlot(wsId) {
        const id = Math.max(1, parseInt(wsId) || 1)
        return id - root.bankStartFor(id)
    }

    function clientsOn(wsId) {
        const key = String(wsId)
        const m = root.clientsByWorkspace
        if (m && m[key])
            return m[key]
        return []
    }

    function normalizeAddress(addr) {
        let a = String(addr || "").trim()
        if (!a.length)
            return ""
        if (a.indexOf("address:") === 0)
            a = a.substring("address:".length)
        // Hyprland addresses look like 0x...
        return a
    }

    function addressSelector(addr) {
        const a = normalizeAddress(addr)
        return a.length ? ("address:" + a) : ""
    }

    function themedIcon(name) {
        if (!name || !String(name).length)
            return ""
        const s = String(name)
        if (s.startsWith("file:"))
            return s
        if (s.startsWith("/"))
            return "file://" + s
        const p = Quickshell.iconPath(s, true)
        return (p && p.length) ? p : ""
    }

    function classKeys(cls) {
        const c = String(cls || "").trim()
        if (!c.length)
            return []
        const keys = []
        const seen = ({})
        function add(s) {
            if (!s || !String(s).length)
                return
            const v = String(s)
            if (seen[v])
                return
            seen[v] = true
            keys.push(v)
        }
        add(c)
        add(c.toLowerCase())
        const noDesktop = c.replace(/\.desktop$/i, "")
        add(noDesktop)
        add(noDesktop.toLowerCase())
        const parts = noDesktop.split(".")
        if (parts.length > 1) {
            const last = parts[parts.length - 1]
            add(last)
            add(last.toLowerCase())
        }
        const stripped = noDesktop.replace(/-bin$/i, "")
        add(stripped)
        add(stripped.toLowerCase())
        return keys
    }

    function desktopEntryForClass(cls) {
        const keys = classKeys(cls)
        for (let i = 0; i < keys.length; i++) {
            const k = keys[i]
            try {
                const heur = DesktopEntries.heuristicLookup(k)
                if (heur)
                    return heur
            } catch (e) {
                // heuristicLookup arrived in later Quickshell; byId still works
            }
            try {
                const exact = DesktopEntries.byId(k)
                if (exact)
                    return exact
            } catch (e) {}
        }

        let list = []
        try {
            const m = DesktopEntries.applications
            list = m && m.values ? m.values : []
        } catch (e) {
            return null
        }

        const lowered = keys.map(function (k) { return k.toLowerCase() })
        for (let i = 0; i < list.length; i++) {
            const entry = list[i]
            if (!entry)
                continue
            const id = String(entry.id || "").toLowerCase().replace(/\.desktop$/i, "")
            const idLast = id.split(".").pop()
            const start = String(entry.startupClass || "").toLowerCase()
            const icon = String(entry.icon || "").toLowerCase()
            const iconBase = icon.split("/").pop().replace(/\.(svg|png|xpm)$/i, "")
            for (let j = 0; j < lowered.length; j++) {
                const n = lowered[j]
                if (!n.length)
                    continue
                if (id === n || idLast === n || start === n || icon === n || iconBase === n)
                    return entry
                if (id.endsWith("." + n) || start.endsWith("." + n))
                    return entry
            }
        }
        return null
    }

    function iconForClass(cls) {
        if (!cls || !String(cls).length)
            return ""
        const key = String(cls)
        if (Object.prototype.hasOwnProperty.call(root.iconCache, key))
            return root.iconCache[key]

        let p = ""
        const entry = desktopEntryForClass(key)
        if (entry)
            p = root.themedIcon(entry.icon)

        if (!p.length) {
            const keys = classKeys(key)
            for (let i = 0; i < keys.length; i++) {
                p = root.themedIcon(keys[i])
                if (p.length)
                    break
            }
        }

        root.iconCache[key] = p
        return p
    }

    function iconForClient(cls, initialClass) {
        let p = iconForClass(cls)
        if (p.length)
            return p
        const initial = String(initialClass || "")
        if (initial.length && initial !== String(cls || ""))
            return iconForClass(initial)
        return ""
    }

    // Bare hex address (no 0x) for matching HyprlandToplevel.address ↔ hyprctl
    function bareAddress(addr) {
        return normalizeAddress(addr).replace(/^0x/i, "").toLowerCase()
    }

    // Resolve a Wayland Toplevel for ScreencopyView (hyprland-toplevel-export-v1).
    // Prefer Hyprland.toplevels[].wayland; fall back to ToplevelManager + attached
    // HyprlandToplevel (quickshell-overview pattern).
    function waylandToplevelFor(addr) {
        const bare = bareAddress(addr)
        if (!bare.length)
            return null

        try {
            const list = Hyprland.toplevels ? Hyprland.toplevels.values : null
            if (list) {
                for (let i = 0; i < list.length; i++) {
                    const ht = list[i]
                    if (!ht)
                        continue
                    const a = String(ht.address || "").replace(/^0x/i, "").toLowerCase()
                    if (a === bare)
                        return ht.wayland || null
                }
            }
        } catch (e) {
            // Hyprland.toplevels may be unavailable on older qs builds
        }

        try {
            const tops = ToplevelManager.toplevels.values
            if (tops) {
                for (let i = 0; i < tops.length; i++) {
                    const top = tops[i]
                    if (!top)
                        continue
                    const ht = top.HyprlandToplevel
                    if (!ht)
                        continue
                    const a = String(ht.address || "").replace(/^0x/i, "").toLowerCase()
                    if (a === bare)
                        return top
                }
            }
        } catch (e) {
            // ToplevelManager optional
        }
        return null
    }

    // --- Hyprland dispatches (Lua-only path for 0.56) ---

    function dispatch(request) {
        if (!request || !String(request).length)
            return
        Hyprland.dispatch(String(request))
    }

    function focusWindow(address) {
        const sel = addressSelector(address)
        if (!sel.length)
            return
        // Pattern from illogical-impulse / quickshell-overview
        dispatch("hl.dsp.focus({ window = \"" + sel + "\" })")
        refreshSoon.restart()
    }

    function moveToWorkspace(address, wsId, silent) {
        const sel = addressSelector(address)
        const ws = parseInt(wsId)
        if (!sel.length || isNaN(ws) || ws <= 0)
            return

        const sil = silent !== false  // default silent
        // Matches overview: hl.dsp.window.move({ workspace, follow=false, window })
        let args = "workspace = " + ws
            + ", window = \"" + sel + "\""
            + ", follow = false"
        if (sil)
            args += ", silent = true"
        dispatch("hl.dsp.window.move({ " + args + " })")
        refreshSoon.restart()
        // Second refresh after compositor settles
        Qt.callLater(function () { root.refresh() })
    }

    function switchToWorkspace(id) {
        const ws = parseInt(id)
        if (isNaN(ws) || ws <= 0)
            return
        dispatch("hl.dsp.focus({ workspace = " + ws + " })")
    }

    // --- Client polling ---

    function refresh() {
        if (refreshing || dragActive)
            return
        refreshing = true
        // Keep HyprlandToplevel address ↔ wayland handles fresh for previews
        try { Hyprland.refreshToplevels() } catch (e) {}
        clientsProc.running = true
    }

    function parseClients(text) {
        clientModel.clear()
        let focused = []
        const byWs = ({})
        // Infinite workspaces: track highest seen id (at least current bank end / focused)
        let highest = Math.max(root.bankEnd, root.focusedWorkspaceId, root.bankSize)

        try {
            const arr = JSON.parse(text.length ? text : "[]")
            if (!Array.isArray(arr)) {
                root.focusedClients = []
                root.clientsByWorkspace = ({})
                root.refreshing = false
                return
            }

            const rows = []
            for (let i = 0; i < arr.length; i++) {
                const c = arr[i]
                if (!c || c.mapped === false || c.hidden === true)
                    continue
                const wsId = c.workspace && c.workspace.id !== undefined
                    ? parseInt(c.workspace.id) : 0
                // Regular numeric workspaces only (skip special / invalid)
                if (isNaN(wsId) || wsId <= 0)
                    continue
                if (wsId > highest)
                    highest = wsId

                const at = c.at || [0, 0]
                const sz = c.size || [0, 0]
                const cls = c.class || c.initialClass || ""
                const initial = c.initialClass || ""
                rows.push({
                    address: normalizeAddress(c.address),
                    className: cls,
                    title: c.title || cls || "Window",
                    workspaceId: wsId,
                    x: at[0] || 0,
                    y: at[1] || 0,
                    w: sz[0] || 0,
                    h: sz[1] || 0,
                    floating: !!c.floating,
                    icon: iconForClient(cls, initial)
                })
            }

            rows.sort(function (a, b) {
                if (a.workspaceId !== b.workspaceId)
                    return a.workspaceId - b.workspaceId
                if (a.x !== b.x)
                    return a.x - b.x
                return a.y - b.y
            })

            const fw = root.focusedWorkspaceId
            for (let j = 0; j < rows.length; j++) {
                const r = rows[j]
                clientModel.append(r)
                const key = String(r.workspaceId)
                if (!byWs[key])
                    byWs[key] = []
                byWs[key].push(r)
                if (r.workspaceId === fw)
                    focused.push(r)
            }

            // Round max up to full bank end so empty bank slots still exist in range
            const bankCeil = root.bankEndFor(highest)
            root.maxWorkspace = Math.max(highest, bankCeil, root.bankSize)
            root.focusedClients = focused
            root.clientsByWorkspace = byWs
        } catch (e) {
            root.focusedClients = []
            root.clientsByWorkspace = ({})
            console.warn("WorkspaceHub: parse failed", e)
        }
        root.refreshing = false
    }

    Process {
        id: clientsProc
        command: ["hyprctl", "-j", "clients"]
        stdout: StdioCollector {
            onStreamFinished: root.parseClients(text)
        }
        onExited: function () {
            root.refreshing = false
        }
    }

    Timer {
        id: pollTimer
        interval: Tokens.workspacePollMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        id: refreshSoon
        interval: 180
        repeat: false
        onTriggered: root.refresh()
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            root.focusedWorkspaceId = Hyprland.focusedWorkspace?.id ?? 1
            root.refresh()
        }
        function onActiveToplevelChanged() {
            refreshSoon.restart()
        }
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            root.iconCache = ({})
            root.refresh()
        }
    }

    Component.onCompleted: root.refresh()
}
