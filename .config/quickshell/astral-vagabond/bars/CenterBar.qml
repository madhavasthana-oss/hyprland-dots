import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Io
import QtQuick
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Shapes
import "../utils"
import ".."
import "../widgets"

Item {
    id: centerBar
    // Window size is driven by shell.qml chrome.
    // Collapsed: HUD strip. Expanded: HUD + separator + chosen widget.
    width: parent ? parent.width : Tokens.leftWidth
    height: parent ? parent.height : Tokens.leftHeight

    readonly property bool expanded: Globals.activeWidget !== ""

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
    // Last status string (typed only while expanded)
    property string pendingStatus: statusMessages[0]

    property bool overrideActive: false
    property bool alertActive: false

    // --- Live clock (astral-vagabond style: ring + day / date / time) ---
    property int hours: 0
    property int minutes: 0
    property int seconds: 0
    property string dayName: ""
    property string dateLine: ""
    property string timeLine: ""

    // --- Live HUD fields (weather / wifi) ---
    property string weatherEmoji: ""
    property string weatherTemp:  ""
    property string wifiSsid:     ""
    property int    wifiSignal:   -1   // -1 = unknown / offline
    property bool   wifiLinked:   false

    function tickClock() {
        const now = new Date()
        centerBar.hours = now.getHours()
        centerBar.minutes = now.getMinutes()
        centerBar.seconds = now.getSeconds()
        centerBar.dayName = Qt.formatDate(now, "ddd").toUpperCase()
        centerBar.dateLine = Qt.formatDate(now, "dd MMM")
        centerBar.timeLine = Qt.formatTime(now, "hh:mm:ss")
        centerBar.checkTimeOfDay()
    }

    readonly property string wifiBars: {
        const s = wifiSignal
        if (!wifiLinked || s < 0)
            return "····"
        if (s >= 75) return "▂▄▆█"
        if (s >= 50) return "▂▄▆·"
        if (s >= 25) return "▂▄··"
        return "▂···"
    }

    // Weather · wifi only (battery removed to free HUD width for launch icons)
    readonly property string metaLine: {
        const bits = []
        if (weatherTemp.length || weatherEmoji.length) {
            bits.push(
                [weatherEmoji, weatherTemp].filter(s => s && s.length).join(" ")
            )
        }
        if (wifiLinked) {
            bits.push(wifiBars)
        } else if (wifiSsid === "offline") {
            bits.push("wifi ·")
        }
        return bits.join("  ·  ")
    }

    function pushStatus(msg, opts) {
        opts = opts || {}
        pendingStatus = msg
        overrideActive = true
        alertActive = !!opts.alert
        overrideHoldTimer.interval = opts.holdMs || 4000
        overrideHoldTimer.restart()
    }

    function pickStatusMessage() {
        let idx
        do {
            idx = Math.floor(Math.random() * statusMessages.length)
        } while (idx === lastMessageIndex && statusMessages.length > 1)
        lastMessageIndex = idx
        pendingStatus = statusMessages[idx]
        return pendingStatus
    }

    // Reveal status with typewriter after expand width has started moving
    function revealStatus() {
        messageAnimator.stop()
        messageAnimator.displayedText = ""
        messageAnimator.mode = AnimatedText.Mode.Typewriter
        const msg = pendingStatus && pendingStatus.length
            ? pendingStatus
            : pickStatusMessage()
        // Slight delay so width expansion leads, then type
        typeRevealTimer.restart()
        typeRevealTimer.pending = msg
    }

    function clearStatus() {
        typeRevealTimer.stop()
        messageTimer.stop()
        overrideHoldTimer.stop()
        messageAnimator.stop()
        messageAnimator.displayedText = ""
        overrideActive = false
        // keep alertActive if still in warning window — cleared by overrideHoldTimer
    }

    Timer {
        id: typeRevealTimer
        property string pending: ""
        interval: Tokens.animInstant
        repeat: false
        onTriggered: {
            if (!centerBar.expanded)
                return
            messageAnimator.transitionTo(pending)
            messageTimer.restart()
        }
    }

    Timer {
        id: overrideHoldTimer
        repeat: false
        onTriggered: {
            centerBar.overrideActive = false
            centerBar.alertActive = false
        }
    }

    AnimatedText {
        id: messageAnimator
        mode: AnimatedText.Mode.Typewriter
        duration: Tokens.animFadeDelay
    }

    Component.onCompleted: {
        pendingStatus = statusMessages[0]
        centerBar.tickClock()
        centerBar.initBatteryState()
        weatherProc.running = true
        wifiProc.running = true
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: centerBar.tickClock()
    }

    Timer {
        id: messageTimer
        running: false
        repeat: true
        interval: 60000

        function pickAndShow() {
            if (!centerBar.expanded)
                return
            const msg = centerBar.pickStatusMessage()
            messageAnimator.transitionTo(msg)
        }

        onTriggered: {
            if (centerBar.overrideActive || !centerBar.expanded)
                return
            pickAndShow()
        }
    }

    // Lightweight weather — wttr one-liner, same cadence as dashboard
    Process {
        id: weatherProc
        command: [
            "bash", "-c",
            "curl -s --max-time " + Tokens.weatherFetchTimeoutSec
                + " 'wttr.in/?format=%c|%t' 2>/dev/null || echo ''"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = text.trim()
                if (!raw.length) {
                    // keep last good reading on blip
                    return
                }
                const parts = raw.split("|")
                // %c can include trailing space / emoji variation selectors
                centerBar.weatherEmoji = (parts[0] || "").trim()
                let temp = (parts[1] || "").trim()
                // normalize "+22°C" → "22°"
                temp = temp.replace(/^\+/, "").replace(/C$/i, "").replace(/°$/, "°")
                if (temp.length && temp.indexOf("°") < 0)
                    temp = temp + "°"
                centerBar.weatherTemp = temp
            }
        }
    }

    Timer {
        interval: Tokens.weatherRefreshMs
        running: true
        repeat: true
        onTriggered: weatherProc.running = true
    }

    // Active wifi: SSID + signal (nmcli)
    Process {
        id: wifiProc
        command: [
            "bash", "-c",
            "line=$(nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi 2>/dev/null"
                + " | awk -F: '$1==\"yes\"{print $2\"|\"$3; exit}')\n"
                + "if [ -n \"$line\" ]; then echo \"$line\"; exit 0; fi\n"
                // wired / no wifi association
                + "state=$(nmcli -t -f STATE g 2>/dev/null | head -1)\n"
                + "echo \"|$state\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = text.trim()
                if (!raw.length) {
                    centerBar.wifiLinked = false
                    centerBar.wifiSsid = ""
                    centerBar.wifiSignal = -1
                    return
                }
                const parts = raw.split("|")
                const ssid = (parts[0] || "").trim()
                const sigOrState = (parts[1] || "").trim()
                if (ssid.length) {
                    centerBar.wifiLinked = true
                    centerBar.wifiSsid = ssid
                    const n = parseInt(sigOrState)
                    centerBar.wifiSignal = isNaN(n) ? 0 : n
                } else {
                    centerBar.wifiLinked = false
                    centerBar.wifiSsid = ""
                    centerBar.wifiSignal = -1
                    // soft label when fully offline
                    if (sigOrState.toLowerCase().indexOf("disconnect") >= 0
                        || sigOrState.toLowerCase().indexOf("unavail") >= 0)
                        centerBar.wifiSsid = "offline"
                }
            }
        }
    }

    Timer {
        interval: 8000
        running: true
        repeat: true
        onTriggered: wifiProc.running = true
    }

    // Prefer UPower.onBattery for plug/unplug: with charge thresholds enabled,
    // displayDevice.state is often PendingCharge (not Charging) while AC is connected,
    // so state-based AC detection never flips and status messages never fire.
    property var battery: UPower.displayDevice
    property bool batteryInitialized: false
    property bool batteryEventsArmed: false
    property bool wasOnAC: false
    property int lastBatteryState: UPowerDeviceState.Unknown
    property bool lowBatteryWarned: false
    property bool criticalBatteryWarned: false

    function batteryDataReady() {
        const dev = UPower.displayDevice
        if (!dev || !dev.ready)
            return false
        const state = dev.state
        if (state === undefined || state === null || state === UPowerDeviceState.Unknown)
            return false
        const raw = dev.percentage
        if (raw === undefined || raw === null || isNaN(raw) || raw <= 0)
            return false
        return true
    }

    // Snapshot current AC/charge state without toasting. Returns false until
    // both percent and a real charging/discharging/full state are known —
    // UPower reports 0% + Unknown at session start.
    function initBatteryState() {
        if (centerBar.batteryInitialized)
            return true
        if (!centerBar.batteryDataReady())
            return false
        centerBar.wasOnAC = !UPower.onBattery
        centerBar.lastBatteryState = UPower.displayDevice.state
        centerBar.batteryInitialized = true
        armBatteryTimer.restart()
        return true
    }

    function batteryPct() {
        const pct = Math.round((UPower.displayDevice.percentage || 0) * 100)
        return isNaN(pct) ? 0 : Math.max(0, Math.min(100, pct))
    }

    // Bar status + mako toast. Same event, two surfaces.
    function notifyBattery(summary, opts) {
        if (!centerBar.batteryInitialized)
            return
        opts = opts || {}
        const holdMs = opts.holdMs || 4000
        centerBar.pushStatus(summary, { holdMs: holdMs, alert: !!opts.alert })
        Globals.toast(
            summary,
            opts.body || "",
            "Battery",
            opts.urgency || "normal",
            holdMs
        )
    }

    function evaluateLowBattery() {
        if (!centerBar.batteryInitialized)
            return

        const pct = UPower.displayDevice.percentage * 100
        const discharging = UPower.onBattery
            || UPower.displayDevice.state === UPowerDeviceState.Discharging

        const shown = Math.round(pct)
        if (discharging && pct <= 5 && !centerBar.criticalBatteryWarned) {
            centerBar.criticalBatteryWarned = true
            centerBar.notifyBattery("CRITICAL BATTERY", {
                holdMs: 6000,
                alert: true,
                urgency: "critical",
                body: shown + "% remaining — plug in"
            })
        } else if (discharging && pct <= 15 && !centerBar.lowBatteryWarned) {
            centerBar.lowBatteryWarned = true
            centerBar.notifyBattery("LOW BATTERY", {
                holdMs: 5000,
                alert: true,
                urgency: "critical",
                body: shown + "% remaining"
            })
        }

        if (!discharging || pct > 20) {
            centerBar.lowBatteryWarned = false
            centerBar.criticalBatteryWarned = false
        }
    }

    Timer {
        id: armBatteryTimer
        interval: 2000
        repeat: false
        onTriggered: centerBar.batteryEventsArmed = true
    }

    Timer {
        interval: 500
        repeat: true
        running: !centerBar.batteryInitialized
        onTriggered: {
            centerBar.initBatteryState()
            if (centerBar.batteryInitialized)
                centerBar.evaluateLowBattery()
        }
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
            if (!centerBar.batteryEventsArmed) {
                centerBar.wasOnAC = nowOnAC
                return
            }
            if (nowOnAC === centerBar.wasOnAC)
                return

            const pct = centerBar.batteryPct()
            if (nowOnAC) {
                centerBar.notifyBattery("AC CONNECTED · CHARGING", {
                    holdMs: 4000,
                    body: "Charging — " + pct + "%"
                })
                centerBar.lowBatteryWarned = false
                centerBar.criticalBatteryWarned = false
            } else {
                centerBar.notifyBattery("ON BATTERY", {
                    holdMs: 4000,
                    body: "Discharging — " + pct + "%"
                })
            }

            centerBar.wasOnAC = nowOnAC
        }
    }

    Connections {
        target: UPower.displayDevice

        function onReadyChanged() {
            if (!centerBar.batteryInitialized)
                centerBar.initBatteryState()
            else if (UPower.displayDevice.ready)
                centerBar.lastBatteryState = UPower.displayDevice.state
        }

        function onStateChanged() {
            if (!centerBar.batteryInitialized) {
                centerBar.initBatteryState()
                return
            }

            const state = UPower.displayDevice.state
            const prev = centerBar.lastBatteryState

            if (!centerBar.batteryEventsArmed) {
                centerBar.lastBatteryState = state
                return
            }

            // Only a completed charge cycle: Charging → FullyCharged.
            // Do NOT treat PendingCharge as full — with charge thresholds that
            // state means "plugged in, not charging yet", and brief
            // Charging→PendingCharge blips on plug-in were false positives.
            if (state === UPowerDeviceState.FullyCharged
                && prev === UPowerDeviceState.Charging) {
                centerBar.notifyBattery("BATTERY FULL", {
                    holdMs: 4000,
                    body: "Charge complete"
                })
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
            if (!centerBar.batteryInitialized) {
                centerBar.initBatteryState()
                if (!centerBar.batteryInitialized)
                    return
            }
            centerBar.evaluateLowBattery()
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
        barWidth:     centerBar.width
        barHeight:    centerBar.height
        radius:       Tokens.radiusLg
        alertActive:  centerBar.alertActive
        expanded:     centerBar.expanded
    }

    Item {
        id: hudStrip
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: Tokens.centerHeight

        // Collapsed/expanded HUD is the same: clock | fill | launch | fill | meta
        RowLayout {
            id: hudRow
            anchors.fill: parent
            anchors.leftMargin:  Tokens.paddingH + Tokens.spacingSm
            anchors.rightMargin: (notifBadge.visible
                ? notifBadge.width + Tokens.paddingH + Tokens.spacingSm
                : Tokens.paddingH + Tokens.spacingSm)
            anchors.topMargin:    Tokens.spacingXss
            anchors.bottomMargin: Tokens.spacingXss
            spacing: Tokens.spacingSm

        // --- clock ring + day / date / time (astral-vagabond) ---
        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: false
            spacing: Tokens.spacingSm

            // Analog-ish ring clock
            Item {
                id: clockFace
                // Stay within collapsed bar height so expand doesn't balloon the face
                readonly property int faceSize: Math.round(
                    Math.max(18, Tokens.leftHeight * 0.78)
                )
                Layout.preferredWidth: faceSize
                Layout.preferredHeight: faceSize
                Layout.alignment: Qt.AlignVCenter

                readonly property real cx: width / 2
                readonly property real cy: height / 2
                readonly property real r: Math.min(width, height) / 2 - 1.5

                // Soft fill
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - 4
                    height: width
                    radius: width / 2
                    color: Qt.rgba(Theme.bgElevated.r, Theme.bgElevated.g, Theme.bgElevated.b, 0.55)
                }

                // Second arc
                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                        strokeWidth: 1.5
                        strokeColor: Theme.accent
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap

                        PathAngleArc {
                            centerX: clockFace.cx
                            centerY: clockFace.cy
                            radiusX: clockFace.r
                            radiusY: clockFace.r
                            startAngle: -90
                            sweepAngle: (centerBar.seconds / 60) * 360
                        }
                    }
                }

                // Hour hand
                Rectangle {
                    width: 1.5
                    height: clockFace.r * 0.42
                    radius: 1
                    color: Theme.textPrimary
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.verticalCenter
                    transformOrigin: Item.Bottom
                    rotation: ((centerBar.hours % 12) + centerBar.minutes / 60) * 30
                }

                // Minute hand
                Rectangle {
                    width: 1.2
                    height: clockFace.r * 0.62
                    radius: 1
                    color: Theme.accent
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.verticalCenter
                    transformOrigin: Item.Bottom
                    rotation: (centerBar.minutes + centerBar.seconds / 60) * 6
                }

                // Hub
                Rectangle {
                    anchors.centerIn: parent
                    width: 3
                    height: 3
                    radius: 1.5
                    color: Theme.accent
                }
            }

            // Day / date / time column
            Column {
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                Text {
                    text: centerBar.dayName
                    font.family: Theme.fontDisplay
                    font.pixelSize: Tokens.fontSizeLabel
                    font.letterSpacing: 1.2
                    color: Theme.accent
                }
                Text {
                    text: centerBar.dateLine
                    font.family: Theme.fontMono
                    font.pixelSize: Tokens.fontSizeTiny
                    color: Theme.textSecondary
                }
                Text {
                    text: centerBar.timeLine
                    font.family: Theme.fontMono
                    font.pixelSize: Tokens.fontSizeSmall
                    color: Theme.textPrimary
                }
            }
        }

        // dynamic gap
        Item { Layout.fillWidth: true; Layout.minimumWidth: Tokens.spacingXs }

        // --- launch icons (fixed footprint) ---
        Item {
            id: launchSlot
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: false
            Layout.preferredWidth: quickLaunch.implicitWidth
            Layout.maximumWidth: quickLaunch.implicitWidth
            Layout.minimumWidth: quickLaunch.implicitWidth
            Layout.preferredHeight: quickLaunch.implicitHeight
        }

        // dynamic gap
        Item { Layout.fillWidth: true; Layout.minimumWidth: Tokens.spacingXs }

        // --- weather · wifi (content-sized) ---
        ColumnLayout {
            id: metaCol
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: false
            Layout.preferredWidth: Math.max(metaTop.implicitWidth, metaSsid.implicitWidth)
            Layout.maximumWidth: parent.width * 0.26
            spacing: 0

            Text {
                id: metaTop
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: metaCol.Layout.maximumWidth
                font.family: Theme.fontMono
                font.pixelSize: Tokens.fontSizeSmall
                color: Theme.textSecondary
                elide: Text.ElideRight
                text: centerBar.metaLine
            }

            Text {
                id: metaSsid
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: metaCol.Layout.maximumWidth
                font.family: Theme.fontMono
                font.pixelSize: Tokens.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.textPrimary
                elide: Text.ElideRight
                visible: centerBar.wifiLinked && centerBar.wifiSsid.length > 0
                text: centerBar.wifiSsid
            }
        }
            }

            QuickLaunch {
                id: quickLaunch
                z: 3
                x: hudRow.x + launchSlot.x
                y: hudRow.y + launchSlot.y + Math.round((launchSlot.height - height) / 2)
            }

            Item {
                id: notifBadge
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: Tokens.paddingH
                width: badgeChrome.width
                height: badgeChrome.height
                z: 3
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
                        onClicked: (mouse) => {
                            Globals.toggleWidget("notifications")
                            mouse.accepted = true
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                anchors.rightMargin: notifBadge.visible ? notifBadge.width + Tokens.paddingH : 0
                z: 1

                onClicked: {
                    const lx = quickLaunch.x
                    const ly = quickLaunch.y
                    if (mouseX >= lx && mouseX <= lx + quickLaunch.width
                        && mouseY >= ly && mouseY <= ly + quickLaunch.height)
                        return

                    if (Globals.activeWidget !== "")
                        Globals.closeWidget()
                    else
                        Globals.openWidget(Globals.lastWidget)
                }
            }
        }

    Rectangle {
        id: morphSep
        anchors.top: hudStrip.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Tokens.paddingH
        anchors.rightMargin: Tokens.paddingH
        height: centerBar.expanded ? Math.max(1, Math.round(Tokens.strokeWidth)) : 0
        color: Theme.borderIdle
        opacity: centerBar.expanded ? 0.5 : 0
        Behavior on opacity {
            NumberAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
        }
    }

    // Clip only the expanding body, never the HUD / chrome border.
    Item {
        id: bodySlot
        anchors.top: morphSep.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: Tokens.paddingH
        anchors.rightMargin: Tokens.paddingH
        anchors.bottomMargin: Tokens.paddingV
        clip: true
        opacity: centerBar.expanded ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
        }

        WidgetHost {
            id: widgetHost
            anchors.fill: parent
        }
    }
}
