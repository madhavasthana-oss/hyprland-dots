pragma Singleton
import QtQuick 2.15
import Quickshell

QtObject {
    // Workspace bank size — board + hub show one bank at a time (1–10, 11–20, …)
    // Matches hypr workspaceGroupSize for Super+1..0; relative nav is infinite.
    readonly property int workspaceBankSize: 10
    // Back-compat alias (count of tiles per board page)
    readonly property int workspaceNumber: workspaceBankSize

    property string activePanel    : ""
    property string lastPanel      : "cpu"


    property string activeCenterPanel : ""
    property string lastCenterPanel   : "dashboard"

    // Console control pane --- which stack page is active (wifi/bt/settings/notifs)
    property string activeEdgePanel : "wifi"   // "wifi" | "bluetooth" | "settings" | "notifications"
    property string lastEdgePanel   : "wifi"
    // Legacy force-pin flag (right-edge panel removed; kept for API stability)
    property bool edgeForced : false

    // Notification modes (mako) + live count for bar badge
    property bool notifSilent : false
    property bool notifDnd    : false
    property int  notifCount  : 0
    // Session-local: mako history cannot be deleted, so the console inbox
    // filters these ids until quickshell restarts.
    property var notifClearedIds: ({})
    property var notifKnownIds: ({})
    property var notifDndDroppedIds: ({})
    property bool notifBaselineReady: false

    function notifIsCleared(id) {
        return !!notifClearedIds[String(id)]
    }

    function notifClearId(id) {
        if (id === undefined || id === null)
            return
        const key = String(id)
        if (notifClearedIds[key])
            return
        const next = Object.assign({}, notifClearedIds)
        next[key] = true
        notifClearedIds = next
    }

    // First snapshot of the session is the baseline (history already received).
    // After that, brand-new ids while DND is on never enter the inbox.
    // Silent still accepts them — mako [mode=silent] invisible=1 hides the toast.
    function notifAcceptIncoming(id) {
        if (id === undefined || id === null)
            return false
        const key = String(id)
        if (notifClearedIds[key] || notifDndDroppedIds[key])
            return false
        const firstSeen = !notifKnownIds[key]
        if (firstSeen)
            notifKnownIds[key] = true
        if (firstSeen && notifBaselineReady && notifDnd) {
            notifDndDroppedIds[key] = true
            return false
        }
        return true
    }

    function notifCloseIncomingBatch() {
        notifBaselineReady = true
    }

    // Screen capture --- edge panel closes itself before launching tools
    property bool screenRecording : false

    // Cava desktop overlay (toggled from Media panel)
    property bool cavaOverlay : false

    // Workspace board (drag windows between workspaces)
    property bool workspaceBoardOpen : false

    // Bottom power menu --- click the bar icon to open/close (not hover)
    property bool powerMenuOpen : false

    // Last toast summary (debug breadcrumb; not an event bus)
    property string lastAction : ""

    function toggleWorkspaceBoard() {
        workspaceBoardOpen = !workspaceBoardOpen
    }

    function openWorkspaceBoard() {
        workspaceBoardOpen = true
    }

    function closeWorkspaceBoard() {
        workspaceBoardOpen = false
    }

    function togglePowerMenu() {
        if (powerMenuOpen)
            closePowerMenu()
        else
            openPowerMenu()
    }

    function openPowerMenu() {
        // Drop the system dropdown so it cannot open under the dim overlay
        if (activePanel !== "") {
            lastPanel = activePanel
            activePanel = ""
        }
        powerMenuOpen = true
    }

    function closePowerMenu() {
        powerMenuOpen = false
    }

    // Fire a mako toast via notify-send. Empty summary = no-op.
    // appName becomes notify-send -a (mako criteria), not "mako".
    // urgency: "low" | "normal" | "critical" (default low, matches existing callers)
    function toast(summary, body, appName, urgency, timeoutMs) {
        if (summary === undefined || summary === null)
            return
        const sum = String(summary).trim()
        if (!sum.length)
            return

        const app = (appName !== undefined && appName !== null && String(appName).length)
            ? String(appName)
            : "Quickshell"
        const bod = (body !== undefined && body !== null) ? String(body) : ""
        const urg = (urgency !== undefined && urgency !== null && String(urgency).length)
            ? String(urgency)
            : "low"
        const timeout = (timeoutMs !== undefined && timeoutMs !== null && timeoutMs !== "")
            ? String(timeoutMs)
            : "4000"

        const args = [
            "notify-send",
            "-a", app,
            "-u", urg,
            "-t", timeout,
            sum
        ]
        if (bod.length)
            args.push(bod)

        lastAction = sum
        Quickshell.execDetached(args)
    }

    // open/toggle open the center CONSOLE tab on the requested page (wifi/bt/settings/notifs).
    function openEdgePanel(panel) {
        if (panel !== undefined && panel !== null && String(panel).length) {
            activeEdgePanel = String(panel)
            lastEdgePanel = String(panel)
        }
        edgeForced = false
        lastCenterPanel = "console"
        activeCenterPanel = "console"
    }

    function releaseEdgePanel() {
        edgeForced = false
    }

    function toggleEdgePanel(panel) {
        const target = (panel !== undefined && panel !== null && String(panel).length)
            ? String(panel)
            : activeEdgePanel
        // Already on console + same page → close center panel
        if (activeCenterPanel === "console" && activeEdgePanel === target) {
            lastCenterPanel = "console"
            activeCenterPanel = ""
            return
        }
        openEdgePanel(target)
    }

    // Toggle a center tab (dashboard / console / media). Same tab again closes.
    function toggleCenterPanel(panel) {
        const target = (panel !== undefined && panel !== null && String(panel).length)
            ? String(panel)
            : lastCenterPanel
        if (activeCenterPanel === target) {
            lastCenterPanel = target
            activeCenterPanel = ""
            return
        }
        lastCenterPanel = target
        activeCenterPanel = target
    }

    function openCenterPanel(panel) {
        const target = (panel !== undefined && panel !== null && String(panel).length)
            ? String(panel)
            : lastCenterPanel
        lastCenterPanel = target
        activeCenterPanel = target
    }
}