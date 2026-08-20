// BatteryWatch.qml --- plug / low / full toasts (no bar chrome)
import Quickshell.Services.UPower
import QtQuick
import "../.."

Item {
    id: root
    width: 0
    height: 0
    visible: false

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
        if (root.batteryInitialized)
            return true
        if (!root.batteryDataReady())
            return false
        root.wasOnAC = !UPower.onBattery
        root.lastBatteryState = UPower.displayDevice.state
        root.batteryInitialized = true
        armTimer.restart()
        return true
    }

    function batteryPct() {
        const pct = Math.round((UPower.displayDevice.percentage || 0) * 100)
        return isNaN(pct) ? 0 : Math.max(0, Math.min(100, pct))
    }

    function notifyBattery(summary, opts) {
        if (!root.batteryInitialized)
            return
        opts = opts || {}
        const holdMs = opts.holdMs || 4000
        Globals.toast(
            summary,
            opts.body || "",
            "Battery",
            opts.urgency || "normal",
            holdMs
        )
    }

    function evaluateLowBattery() {
        if (!root.batteryInitialized)
            return

        const pct = UPower.displayDevice.percentage * 100
        const discharging = UPower.onBattery
            || UPower.displayDevice.state === UPowerDeviceState.Discharging

        const shown = Math.round(pct)
        if (discharging && pct <= 5 && !root.criticalBatteryWarned) {
            root.criticalBatteryWarned = true
            root.notifyBattery("CRITICAL BATTERY", {
                holdMs: 6000,
                urgency: "critical",
                body: shown + "% remaining — plug in"
            })
        } else if (discharging && pct <= 15 && !root.lowBatteryWarned) {
            root.lowBatteryWarned = true
            root.notifyBattery("LOW BATTERY", {
                holdMs: 5000,
                urgency: "critical",
                body: shown + "% remaining"
            })
        }

        if (!discharging || pct > 20) {
            root.lowBatteryWarned = false
            root.criticalBatteryWarned = false
        }
    }

    Component.onCompleted: root.initBatteryState()

    Timer {
        id: armTimer
        interval: 2000
        repeat: false
        onTriggered: root.batteryEventsArmed = true
    }

    Timer {
        interval: 500
        repeat: true
        running: !root.batteryInitialized
        onTriggered: {
            root.initBatteryState()
            if (root.batteryInitialized)
                root.evaluateLowBattery()
        }
    }

    Connections {
        target: UPower

        function onOnBatteryChanged() {
            if (!root.batteryInitialized) {
                root.initBatteryState()
                return
            }

            const nowOnAC = !UPower.onBattery
            if (!root.batteryEventsArmed) {
                root.wasOnAC = nowOnAC
                return
            }
            if (nowOnAC === root.wasOnAC)
                return

            const pct = root.batteryPct()
            if (nowOnAC) {
                root.notifyBattery("AC CONNECTED · CHARGING", {
                    holdMs: 4000,
                    body: "Charging — " + pct + "%"
                })
                root.lowBatteryWarned = false
                root.criticalBatteryWarned = false
            } else {
                root.notifyBattery("ON BATTERY", {
                    holdMs: 4000,
                    body: "Discharging — " + pct + "%"
                })
            }

            root.wasOnAC = nowOnAC
        }
    }

    Connections {
        target: UPower.displayDevice

        function onReadyChanged() {
            if (!root.batteryInitialized)
                root.initBatteryState()
            else if (UPower.displayDevice.ready)
                root.lastBatteryState = UPower.displayDevice.state
        }

        function onStateChanged() {
            if (!root.batteryInitialized) {
                root.initBatteryState()
                return
            }

            const state = UPower.displayDevice.state
            const prev = root.lastBatteryState

            if (!root.batteryEventsArmed) {
                root.lastBatteryState = state
                return
            }

            if (state === UPowerDeviceState.FullyCharged
                && prev === UPowerDeviceState.Charging) {
                root.notifyBattery("BATTERY FULL", {
                    holdMs: 4000,
                    body: "Charge complete"
                })
            }

            if (state === UPowerDeviceState.Charging
                || state === UPowerDeviceState.FullyCharged
                || state === UPowerDeviceState.PendingCharge) {
                root.lowBatteryWarned = false
                root.criticalBatteryWarned = false
            }

            root.lastBatteryState = state
        }

        function onPercentageChanged() {
            if (!root.batteryInitialized) {
                root.initBatteryState()
                if (!root.batteryInitialized)
                    return
            }
            root.evaluateLowBattery()
        }
    }
}
