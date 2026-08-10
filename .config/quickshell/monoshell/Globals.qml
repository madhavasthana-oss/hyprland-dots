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

    // Screen capture --- edge panel closes itself before launching tools
    property bool screenRecording : false

    // Cava desktop overlay (toggled from Media panel)
    property bool cavaOverlay : false

    // Workspace board (drag windows between workspaces)
    property bool workspaceBoardOpen : false

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

    // Fire a mako toast via notify-send. Empty summary = no-op.
    // appName becomes notify-send -a (mako criteria), not "mako".
    function toast(summary, body, appName) {
        if (summary === undefined || summary === null)
            return
        const sum = String(summary).trim()
        if (!sum.length)
            return

        const app = (appName !== undefined && appName !== null && String(appName).length)
            ? String(appName)
            : "Quickshell"
        const bod = (body !== undefined && body !== null) ? String(body) : ""

        const args = [
            "notify-send",
            "-a", app,
            "-u", "low",
            "-t", "4000",
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