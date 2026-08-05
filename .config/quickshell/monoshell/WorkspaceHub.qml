// WorkspaceHub.qml --- live hyprctl client list + Lua-era Hyprland move/focus
// Hyprland 0.56+ with hyprland.lua requires hl.dsp.* forms. Classic dispatchers
// (workspace N, movetoworkspacesilent, focuswindow) fail with:
//   "dispatch in lua is a shorthand for hl.dispatch(...)"
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

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

    property int maxWorkspace: Globals.workspaceNumber

    // Hyprland 0.56 lua config — classic string dispatchers do not work.
    // Always use hl.dsp.* (verified working via hyprctl dispatch).
    readonly property bool useLuaDispatch: true

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

    function iconForClass(cls) {
        if (!cls || !String(cls).length)
            return ""
        const c = String(cls)
        let p = Quickshell.iconPath(c, true)
        if (p && p.length)
            return p
        // reverse-domain → last segment (com.mitchellh.ghostty → ghostty)
        const parts = c.split(".")
        if (parts.length > 1) {
            p = Quickshell.iconPath(parts[parts.length - 1], true)
            if (p && p.length)
                return p
            p = Quickshell.iconPath(parts[parts.length - 1].toLowerCase(), true)
            if (p && p.length)
                return p
        }
        p = Quickshell.iconPath(c.toLowerCase(), true)
        return (p && p.length) ? p : ""
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
        clientsProc.running = true
    }

    function parseClients(text) {
        clientModel.clear()
        let focused = []
        const byWs = ({})
        const maxWs = Globals.workspaceNumber

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
                // Only regular workspaces in the configured range
                if (isNaN(wsId) || wsId <= 0 || wsId > maxWs)
                    continue

                const at = c.at || [0, 0]
                const sz = c.size || [0, 0]
                const cls = c.class || c.initialClass || ""
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
                    icon: iconForClass(cls)
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

            root.maxWorkspace = maxWs
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

    Component.onCompleted: root.refresh()
}
