pragma Singleton
import QtQuick 2.15
import Quickshell

QtObject {
    // Workspace bank size — board + hub show one bank at a time (1–10, 11–20, …)
    // Matches hypr workspaceGroupSize for Super+1..0; relative nav is infinite.
    readonly property int workspaceBankSize: 10

    property string activePanel    : ""
    property string lastPanel      : "cpu"

    // Center bar morphs around this: dashboard | console | wifi | bluetooth |
    // settings | notifications | media | ""
    property string activeWidget : ""
    property string lastWidget   : "dashboard"

    // Notification modes + live count for bar badge (owned by NotifServer)
    property bool notifSilent : false
    property bool notifDnd    : false
    property int  notifCount  : 0
    // Session-local dismissed ids (survives toast expiry, not a full restart).
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

    // Screen capture --- settings widget closes itself before launching tools
    property bool screenRecording : false

    // Cava desktop overlay (toggled from Media panel)
    property bool cavaOverlay : false

    // Workspace board (drag windows between workspaces)
    property bool workspaceBoardOpen : false

    // Bottom power menu --- click the bar icon to open/close (not hover)
    property bool powerMenuOpen : false

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
        if (activePanel !== "") {
            lastPanel = activePanel
            activePanel = ""
        }
        powerMenuOpen = true
    }

    function closePowerMenu() {
        powerMenuOpen = false
    }

    // Fire a desktop toast via notify-send (Quickshell NotificationServer).
    // Empty summary = no-op. appName becomes notify-send -a.
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

        Quickshell.execDetached(args)
    }

    function closeWidget() {
        if (activeWidget !== "")
            lastWidget = activeWidget
        activeWidget = ""
    }

    function openWidget(id) {
        const target = (id !== undefined && id !== null && String(id).length)
            ? String(id)
            : lastWidget
        lastWidget = target
        activeWidget = target
    }

    function toggleWidget(id) {
        const target = (id !== undefined && id !== null && String(id).length)
            ? String(id)
            : lastWidget
        if (activeWidget === target) {
            closeWidget()
            return
        }
        openWidget(target)
    }

    // Session lock — Lock.qml listens and raises WlSessionLock.
    signal lockRequested
    function lockSession() {
        lockRequested()
    }
}