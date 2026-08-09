import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import "../utils"
import ".."

Item {
    id: centerBar
    // Rect width tracks CenterTrapezoid's second-longest edge (pinched bottom).
    width: Tokens.centerSmallerWidth
    height: Tokens.centerHeight

    property var statusMessages: [
        "SYSTEM NOMINAL",
        "SESSION ACTIVE",
        "COMPOSITOR STABLE",
        "WORKSPACE READY",
        "NETWORK STABLE",
        "AUDIO PIPELINE OK",
        "FOCUS MODE",
        "ALL SERVICES UP",
        "IDLE THRESHOLD CLEAR",
        "CLIPBOARD READY",
        "UPDATES CHECKED"
    ]
    property int lastMessageIndex: 0

    property bool overrideActive: false
    property bool alertActive: false

    function pushStatus(msg, opts) {
        opts = opts || {}
        overrideActive = true
        alertActive = !!opts.alert
        messageAnimator.transitionTo(msg)
        overrideHoldTimer.interval = opts.holdMs || 4000
        overrideHoldTimer.restart()
    }

    Timer {
        id: overrideHoldTimer
        repeat: false
        onTriggered: {
            centerBar.overrideActive = false
            centerBar.alertActive = false
            messageTimer.pickAndShow()
            messageTimer.restart()
        }
    }

    AnimatedText {
        id: messageAnimator
        mode: AnimatedText.Mode.Scramble
    }

    Component.onCompleted: {
        messageAnimator.transitionTo(centerBar.statusMessages[0])
        centerBar.checkTimeOfDay()
        centerBar.initBatteryState()
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            timeText.text = Qt.formatDate(new Date(), "ddd") + " × " + Qt.formatDate(new Date(), "dd MMM") + " × " + Qt.formatTime(new Date(), "hh:mm")
            centerBar.checkTimeOfDay()
        }
    }

    Timer {
        id: messageTimer
        running: true
        repeat: true
        interval: 60000

        function pickAndShow() {
            let idx
            do {
                idx = Math.floor(Math.random() * centerBar.statusMessages.length)
            } while (idx === centerBar.lastMessageIndex && centerBar.statusMessages.length > 1)
            centerBar.lastMessageIndex = idx
            messageAnimator.transitionTo(centerBar.statusMessages[idx])
        }

        onTriggered: {
            if (centerBar.overrideActive)
                return
            pickAndShow()
        }
    }

    // Prefer UPower.onBattery for plug/unplug: with charge thresholds enabled,
    // displayDevice.state is often PendingCharge (not Charging) while AC is connected,
    // so state-based AC detection never flips and status messages never fire.
    property var battery: UPower.displayDevice
    property bool batteryInitialized: false
    property bool wasOnAC: false
    property int lastBatteryState: UPowerDeviceState.Unknown
    property bool lowBatteryWarned: false
    property bool criticalBatteryWarned: false

    function initBatteryState() {
        // onBattery is valid even before displayDevice.ready
        centerBar.wasOnAC = !UPower.onBattery
        if (centerBar.battery && centerBar.battery.ready)
            centerBar.lastBatteryState = centerBar.battery.state
        centerBar.batteryInitialized = true
    }

    // Plug / unplug — system AC line, not device charge state
    Connections {
        target: UPower

        function onOnBatteryChanged() {
            if (!centerBar.batteryInitialized) {
                centerBar.initBatteryState()
                return
            }

            const nowOnAC = !UPower.onBattery
            if (nowOnAC === centerBar.wasOnAC)
                return

            if (nowOnAC) {
                centerBar.pushStatus("AC CONNECTED · CHARGING", { holdMs: 4000 })
                centerBar.lowBatteryWarned = false
                centerBar.criticalBatteryWarned = false
            } else {
                centerBar.pushStatus("ON BATTERY", { holdMs: 4000 })
            }

            centerBar.wasOnAC = nowOnAC
        }
    }

    Connections {
        target: UPower.displayDevice

        function onReadyChanged() {
            if (UPower.displayDevice.ready && !centerBar.batteryInitialized)
                centerBar.initBatteryState()
            else if (UPower.displayDevice.ready)
                centerBar.lastBatteryState = UPower.displayDevice.state
        }

        function onStateChanged() {
            if (!UPower.displayDevice.ready)
                return

            if (!centerBar.batteryInitialized) {
                centerBar.initBatteryState()
                return
            }

            const state = UPower.displayDevice.state
            const prev = centerBar.lastBatteryState

            // Only a completed charge cycle: Charging → FullyCharged.
            // Do NOT treat PendingCharge as full — with charge thresholds that
            // state means "plugged in, not charging yet", and brief
            // Charging→PendingCharge blips on plug-in were false positives.
            if (state === UPowerDeviceState.FullyCharged
                && prev === UPowerDeviceState.Charging) {
                centerBar.pushStatus("BATTERY FULL", { holdMs: 4000 })
            }

            if (state === UPowerDeviceState.Charging
                || state === UPowerDeviceState.FullyCharged
                || state === UPowerDeviceState.PendingCharge) {
                centerBar.lowBatteryWarned = false
                centerBar.criticalBatteryWarned = false
            }

            centerBar.lastBatteryState = state
        }

        function onPercentageChanged() {
            if (!UPower.displayDevice.ready)
                return

            const pct = UPower.displayDevice.percentage * 100
            const discharging = UPower.onBattery
                || UPower.displayDevice.state === UPowerDeviceState.Discharging

            if (discharging && pct <= 5 && !centerBar.criticalBatteryWarned) {
                centerBar.criticalBatteryWarned = true
                centerBar.pushStatus("CRITICAL BATTERY", { holdMs: 6000, alert: true })
            } else if (discharging && pct <= 15 && !centerBar.lowBatteryWarned) {
                centerBar.lowBatteryWarned = true
                centerBar.pushStatus("LOW BATTERY", { holdMs: 5000, alert: true })
            }

            if (!discharging || pct > 20) {
                centerBar.lowBatteryWarned = false
                centerBar.criticalBatteryWarned = false
            }
        }
    }

    property string lastTimeGreetingDate: ""

    function checkTimeOfDay() {
        const now = new Date()
        const h = now.getHours()
        const dateStr = Qt.formatDate(now, "yyyy-MM-dd")

        let window = ""
        let msg = ""

        if (h >= 5 && h < 8) {
            window = "dawn"
            msg = "GOOD MORNING"
        } else if (h >= 8 && h < 12) {
            window = "morning"
            msg = "GOOD MORNING"
        } else if (h >= 17 && h < 21) {
            window = "evening"
            msg = "GOOD EVENING"
        } else if (h >= 0 && h < 5) {
            window = "night"
            msg = "LATE SESSION"
        } else {
            return
        }

        const guardKey = dateStr + "|" + window
        if (centerBar.lastTimeGreetingDate === guardKey)
            return

        centerBar.lastTimeGreetingDate = guardKey
        centerBar.pushStatus(msg, { holdMs: 5000 })
    }

    CenterRect {
        anchors.fill: parent
        barWidth:     Tokens.centerSmallerWidth
        barHeight:    Tokens.centerHeight
        radius:       Tokens.radiusLg
        alertActive:  centerBar.alertActive
        expanded:     Globals.activeCenterPanel !== ""
    }

    // Natural-width, fully centered labels — no fixed width, no elide
    Column {
        id: centerLabels
        anchors.centerIn: parent
        spacing: Tokens.spacingXss

        Text {
            id: statusText
            anchors.horizontalCenter: parent.horizontalCenter
            text: "<< " + messageAnimator.displayedText + " >>"
            horizontalAlignment: Text.AlignHCenter
            font.family: Theme.fontDisplay
            font.pixelSize: Tokens.fontSizeMedium
            color: Theme.textPrimary
        }

        Text {
            id: timeText
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(new Date(), "ddd") + " × "
                + Qt.formatDate(new Date(), "dd MMM") + " × "
                + Qt.formatTime(new Date(), "hh:mm")
            horizontalAlignment: Text.AlignHCenter
            font.family: Theme.fontMono
            font.pixelSize: Tokens.fontSizeSmall
            color: Theme.textSecondary
        }
    }

    // Notification badge --- trailing edge of center bar; opens console notifications
    Item {
        id: notifBadge
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: Tokens.paddingH
        width: badgeChrome.width
        height: badgeChrome.height
        z: 2
        visible: Globals.notifCount > 0 || Globals.notifDnd || Globals.notifSilent

        Rectangle {
            id: badgeChrome
            width: Math.max(Tokens.iconSizeLarge + Tokens.spacingXs,
                            badgeLabel.implicitWidth + 2 * Tokens.paddingH)
            height: Tokens.listRowHeight
            radius: Tokens.radiusSm
            color: badgeMouse.containsMouse ? Theme.bgElevated : Theme.bgSurface
            border.color: Globals.notifDnd
                ? Theme.stateCritical
                : (Globals.notifCount > 0 ? Theme.borderActive : Theme.borderIdle)
            border.width: Tokens.strokeWidth

            Text {
                id: badgeLabel
                anchors.centerIn: parent
                text: {
                    if (Globals.notifDnd)
                        return Globals.notifCount > 0 ? "DND " + Globals.notifCount : "DND"
                    if (Globals.notifSilent)
                        return Globals.notifCount > 0 ? "S " + Globals.notifCount : "S"
                    return Globals.notifCount > 99 ? "99+" : String(Globals.notifCount)
                }
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                color: Globals.notifDnd
                    ? Theme.stateCritical
                    : (Globals.notifCount > 0 ? Theme.accent : Theme.textDim)
            }

            MouseArea {
                id: badgeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                // Consume click so center panel toggle does not fire
                onClicked: (mouse) => {
                    Globals.toggleEdgePanel("notifications")
                    mouse.accepted = true
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        // Leave room for badge hit target on the right
        anchors.rightMargin: notifBadge.visible ? notifBadge.width + Tokens.paddingH : 0

        onClicked: {
            if (Globals.activeCenterPanel !== "") {
                Globals.lastCenterPanel = Globals.activeCenterPanel
                Globals.activeCenterPanel = ""
            } else {
                Globals.activeCenterPanel = Globals.lastCenterPanel
            }
        }
    }
}
