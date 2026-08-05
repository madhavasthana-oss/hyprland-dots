pragma Singleton
import QtQuick 2.15
import Quickshell

QtObject {
    // Visible workspace count (left bar + board); matches hypr workspaceGroupSize
    readonly property int workspaceNumber: 10

    property string activePanel    : ""
    property string lastPanel      : "cpu"


    property string activeCenterPanel : ""
    property string lastCenterPanel   : "dashboard"

    // Right-edge trifold (T.S.S) --- which stack page is active
    property string activeEdgePanel : "wifi"   // "wifi" | "bluetooth" | "settings" | "notifications"
    property string lastEdgePanel   : "wifi"
    // Force edge open (e.g. notif badge) without requiring hover
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

    // Edge tabs now live inside Console (center panel).
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
}