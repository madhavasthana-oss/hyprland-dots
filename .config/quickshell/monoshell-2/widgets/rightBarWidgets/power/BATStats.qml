import Quickshell.Services.UPower
import QtQuick

Item {
    id: batteryStats

    property int percentage: 0
    property string state: ""
    property string timeRemaining: ""
    signal ready

    Timer {
        id: initTimer
        interval: 500
        repeat:   true
        running:  true
        onTriggered: {
            let pct = Math.round(UPower.displayDevice.percentage * 100)
            if (pct > 0) {
                batteryStats.percentage    = pct
                batteryStats.state         = UPower.displayDevice.state
                batteryStats.timeRemaining = UPower.displayDevice.timeToEmpty > 0
                    ? UPower.displayDevice.timeToEmpty
                    : UPower.displayDevice.timeToFull
                batteryStats.ready()
                initTimer.stop()
            }
        }
    }

    Connections {
        target: UPower.displayDevice

        function onPercentageChanged() {
            let pct = Math.round(UPower.displayDevice.percentage * 100)
            batteryStats.percentage = pct
            if (pct > 0) batteryStats.ready()
        }

        function onStateChanged() {
            batteryStats.state = UPower.displayDevice.state
        }

        function onTimeToEmptyChanged() {
            batteryStats.timeRemaining = UPower.displayDevice.timeToEmpty
        }

        function onTimeToFullChanged() {
            batteryStats.timeRemaining = UPower.displayDevice.timeToFull
        }
    }
}