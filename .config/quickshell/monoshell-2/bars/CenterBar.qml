// CenterBar.qml --- compact clock column + live weather + notif badge
// Replaces the huge status banner. Ephemeral status toasts still work.
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

Item {
    id: centerBar
    clip: true

    property bool alertActive: false

    // --- live clock ---
    property int hours: 0
    property int minutes: 0
    property int seconds: 0
    property string dayName: ""
    property string dateLine: ""
    property string timeLine: ""

    // --- weather snapshot ---
    property string wxEmoji: "·"
    property string wxTemp: "--°"
    property string wxDesc: "…"
    property string wxDetail: ""

    // ephemeral status (battery / greetings) — tiny overlay, not a banner
    property bool overrideActive: false
    property string toastText: ""

    function pushStatus(msg, opts) {
        opts = opts || {}
        overrideActive = true
        alertActive = !!opts.alert
        toastText = String(msg)
        messageAnimator.transitionTo(String(msg))
        overrideHoldTimer.interval = opts.holdMs || 3500
        overrideHoldTimer.restart()
    }

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

    function weatherEmoji(code) {
        const c = parseInt(code)
        if (isNaN(c)) return "·"
        if (c === 113) return "☀"
        if (c === 116) return "⛅"
        if (c === 119 || c === 122) return "☁"
        if (c === 143 || c === 248 || c === 260) return "fog"
        if (c >= 176 && c <= 266) return "🌦"
        if (c >= 281 && c <= 350) return "❄"
        if (c >= 353 && c <= 377) return "🌧"
        if (c >= 386 && c <= 395) return "⛈"
        return "·"
    }

    function parseWeather(text) {
        try {
            const data = JSON.parse(text)
            const cur = data.current_condition && data.current_condition[0]
            if (!cur) {
                centerBar.wxDesc = "OFFLINE"
                return
            }
            centerBar.wxEmoji = cur.weatherCode ? centerBar.weatherEmoji(cur.weatherCode) : "·"
            centerBar.wxTemp = cur.temp_C !== undefined ? (cur.temp_C + "°") : "--°"
            centerBar.wxDesc = (cur.weatherDesc && cur.weatherDesc[0] && cur.weatherDesc[0].value) || ""
            const bits = []
            if (cur.FeelsLikeC !== undefined) bits.push("feels " + cur.FeelsLikeC + "°")
            if (cur.humidity) bits.push(cur.humidity + "%")
            if (cur.windspeedKmph) bits.push(cur.windspeedKmph + "km/h")
            centerBar.wxDetail = bits.join(" · ")
        } catch (e) {
            centerBar.wxDesc = "ERR"
            centerBar.wxDetail = ""
        }
    }

    Timer {
        id: overrideHoldTimer
        repeat: false
        onTriggered: {
            centerBar.overrideActive = false
            centerBar.alertActive = false
            centerBar.toastText = ""
        }
    }

    AnimatedText {
        id: messageAnimator
        mode: AnimatedText.Mode.Scramble
    }

    Component.onCompleted: {
        centerBar.tickClock()
        centerBar.initBatteryState()
        weatherProc.running = true
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: centerBar.tickClock()
    }

    Process {
        id: weatherProc
        command: [
            "bash", "-c",
            "curl -s --max-time " + Tokens.weatherFetchTimeoutSec
                + " 'wttr.in/?format=j1' 2>/dev/null || echo '{}'"
        ]
        stdout: StdioCollector {
            onStreamFinished: centerBar.parseWeather(text.length ? text : "{}")
        }
    }

    Timer {
        interval: Tokens.weatherRefreshMs
        running: true
        repeat: true
        onTriggered: weatherProc.running = true
    }

    // --- battery / time-of-day hooks (keep toasts) ---
    property var battery: UPower.displayDevice
    property bool batteryInitialized: false
    property bool wasOnAC: false
    property int lastBatteryState: UPowerDeviceState.Unknown
    property bool lowBatteryWarned: false
    property bool criticalBatteryWarned: false
    property string lastTimeGreetingDate: ""

    function initBatteryState() {
        centerBar.wasOnAC = !UPower.onBattery
        if (centerBar.battery && centerBar.battery.ready)
            centerBar.lastBatteryState = centerBar.battery.state
        centerBar.batteryInitialized = true
    }

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
                centerBar.pushStatus("AC · CHARGING", { holdMs: 3500 })
                centerBar.lowBatteryWarned = false
                centerBar.criticalBatteryWarned = false
            } else {
                centerBar.pushStatus("ON BATTERY", { holdMs: 3500 })
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
            if (!UPower.displayDevice.ready) return
            if (!centerBar.batteryInitialized) {
                centerBar.initBatteryState()
                return
            }
            const state = UPower.displayDevice.state
            const prev = centerBar.lastBatteryState
            if (state === UPowerDeviceState.FullyCharged
                && prev === UPowerDeviceState.Charging) {
                centerBar.pushStatus("BATTERY FULL", { holdMs: 3500 })
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
            if (!UPower.displayDevice.ready) return
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

    function checkTimeOfDay() {
        const now = new Date()
        const h = now.getHours()
        const dateStr = Qt.formatDate(now, "yyyy-MM-dd")
        let window = ""
        let msg = ""
        if (h >= 5 && h < 8) { window = "dawn"; msg = "GOOD MORNING" }
        else if (h >= 8 && h < 12) { window = "morning"; msg = "GOOD MORNING" }
        else if (h >= 17 && h < 21) { window = "evening"; msg = "GOOD EVENING" }
        else if (h >= 0 && h < 5) { window = "night"; msg = "LATE SESSION" }
        else return
        const guardKey = dateStr + "|" + window
        if (centerBar.lastTimeGreetingDate === guardKey) return
        centerBar.lastTimeGreetingDate = guardKey
        centerBar.pushStatus(msg, { holdMs: 4500 })
    }

    // ============================================================
    //  LAYOUT — [ clock ring | day/date/time ]  ·  [ weather ]  [badge]
    // ============================================================
    RowLayout {
        id: mainRow
        anchors.fill: parent
        anchors.leftMargin: Tokens.spacing.xs
        anchors.rightMargin: Tokens.spacing.xs
        spacing: Tokens.spacing.md

        // --- mini clock face + datetime column ---
        RowLayout {
            Layout.fillHeight: true
            Layout.fillWidth: false
            spacing: Tokens.spacing.sm

            // Analog-ish ring clock
            Item {
                id: clockFace
                Layout.preferredWidth: Math.round(Tokens.bar.height * 0.78)
                Layout.preferredHeight: Math.round(Tokens.bar.height * 0.78)
                Layout.alignment: Qt.AlignVCenter

                readonly property real cx: width / 2
                readonly property real cy: height / 2
                readonly property real r: Math.min(width, height) / 2 - 1.5

                // Outer ring
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border.width: 0
                }

                // Soft fill
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - 4
                    height: width
                    radius: width / 2
                    color: Qt.rgba(Theme.bgElevated.r, Theme.bgElevated.g, Theme.bgElevated.b, 0.55)
                }

                // Second arc (sweep feel via rotation)
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
                    font.pixelSize: Tokens.type.label
                    font.letterSpacing: 1.2
                    color: Theme.accent
                }
                Text {
                    text: centerBar.dateLine
                    font.family: Theme.fontMono
                    font.pixelSize: Tokens.type.tiny
                    color: Theme.textSecondary
                }
                Text {
                    text: centerBar.timeLine
                    font.family: Theme.fontMono
                    font.pixelSize: Tokens.type.small
                    color: Theme.textPrimary
                }
            }
        }

        // --- weather cluster ---
        RowLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: Tokens.spacing.sm

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: centerBar.wxEmoji
                font.pixelSize: Tokens.type.medium
                color: Theme.accent
            }

            Column {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 0

                Row {
                    spacing: Tokens.spacing.xs
                    Text {
                        text: centerBar.wxTemp
                        font.family: Theme.fontMono
                        font.pixelSize: Tokens.type.small
                        color: Theme.textPrimary
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: centerBar.wxDesc
                        font.family: Theme.fontDisplay
                        font.pixelSize: Tokens.type.tiny
                        color: Theme.textSecondary
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, 90 * Tokens.scale)
                    }
                }
                Text {
                    width: parent.width
                    text: centerBar.wxDetail
                    font.family: Theme.fontMono
                    font.pixelSize: Tokens.type.tiny
                    color: Theme.textDim
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }
        }

        // Notif badge
        Item {
            id: notifBadge
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: badgeChrome.width
            Layout.preferredHeight: badgeChrome.height
            visible: Globals.notifCount > 0 || Globals.notifDnd || Globals.notifSilent
            z: 2

            Rectangle {
                id: badgeChrome
                width: Math.max(Tokens.icon.large + Tokens.spacing.xs,
                                badgeLabel.implicitWidth + 2 * Tokens.padding.h)
                height: Math.max(Tokens.listRowHeight * 0.85, Tokens.type.small + 4)
                radius: Tokens.radius.sm
                color: badgeMouse.containsMouse ? Theme.bgElevated : "transparent"
                border.width: 0

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
                    font.pixelSize: Tokens.type.label
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
                        Globals.toggleEdgePanel("notifications")
                        mouse.accepted = true
                    }
                }
            }
        }
    }

    // Ephemeral toast strip (replaces the banner) — overlays center when active
    Rectangle {
        id: toast
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        height: parent.height - 4
        radius: Tokens.radius.sm
        visible: centerBar.overrideActive
        z: 5
        color: Qt.rgba(Theme.bgElevated.r, Theme.bgElevated.g, Theme.bgElevated.b, 0.92)
        border.width: 0

        Text {
            anchors.centerIn: parent
            text: messageAnimator.displayedText
            font.family: Theme.fontDisplay
            font.pixelSize: Tokens.type.small
            color: centerBar.alertActive ? Theme.stateCritical : Theme.accent
        }

        Behavior on opacity {
            NumberAnimation { duration: Tokens.anim.fast }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        z: 1
        // leave badge alone
        anchors.rightMargin: notifBadge.visible ? notifBadge.width + Tokens.spacing.xs : 0

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
