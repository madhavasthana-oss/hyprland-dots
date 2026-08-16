import Quickshell
import Quickshell.Io
import QtQuick
import "../../../.."

Item {
    id: gpuBackend

    // ---
    //  Public API
    // ---

    property bool   isReady   : false
    property bool   nameFound : false
    property string gpuName   : "Loading GPU"
    property int    gpuUsage  : -1
    property int    gpuFreq   : -1

    readonly property int historyLength: 20
    // Match frontend usage/frequency paint windows (500 ms)
    property int intervalLength: 500

    property var gpuUsageHistory: new Array(historyLength).fill(undefined)
    property var gpuFreqHistory:  new Array(historyLength).fill(undefined)

    // Co-located with the shell: astral-vagabond/utils/scripts/gpu-info.sh
    readonly property string gpuInfoScript: Quickshell.shellDir + "/utils/scripts/gpu-info.sh"

    // ---
    //  Sliding window helpers
    // ---

    function getEarliestUndefined(buffer) {
        let nextEntry = 1
        for (let i = -1; i >= -historyLength; i--) {
            let val = buffer[buffer.length + i]
            if (val === undefined) {
                nextEntry = i
            } else {
                break
            }
        }
        return nextEntry
    }

    function pushHistory(value, propertyName) {
        let buf = gpuBackend[propertyName].slice()

        let nextEntry = getEarliestUndefined(buf)

        if (nextEntry === 1) {
            buf = buf.slice(1)
            buf.push(value)
        } else {
            buf[buf.length + nextEntry] = value
        }

        gpuBackend[propertyName] = buf
    }

    // ---
    //  Startup GPU name detection (fires once on login)
    // ---

    Timer {
        id:       nameDetectTimer
        interval: 100
        running:  !gpuBackend.nameFound
        repeat:   false
        onTriggered: {
            if (!gpuBackend.nameFound)
                gpuNameProc.running = true
        }
    }

    Process {
        id:      gpuNameProc
        running: false
        command: ["sh", "-c", "lspci | grep -Ei 'vga|3d|display' | head -n1"]
        stdout: StdioCollector {
            onStreamFinished: {
                let output = text.trim()
                if (output.length > 0) {
                    let fragmentedData    = output.split(":")
                    gpuBackend.gpuName = fragmentedData.slice(2).join(":").trim()
                }
                gpuBackend.nameFound = true
                gpuNameProc.running       = false
            }
        }
    }

    // ---
    //  Polling — gpu-info.sh (nvtop util + sysfs MHz), not turbostat
    // ---

    Timer {
        id:       detector
        interval: gpuBackend.intervalLength
        running:  true
        repeat:   true
        onTriggered: {
            if (!gpuProc.running)
                gpuProc.running = true
        }
    }

    // ---
    //  Telemetry
    // ---

    Process {
        id:      gpuProc
        running: false
        // Raw line: "<usage_pct> <freq_mhz>"  (~150ms, no root)
        command: [gpuBackend.gpuInfoScript, "-r"]
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = text.trim().split(/\s+/)
                if (parts.length < 2)
                    return

                let usage = parseInt(parts[0], 10)
                let freq  = parseInt(parts[1], 10)
                if (isNaN(usage))
                    return

                usage = Math.max(0, Math.min(100, usage))
                gpuBackend.gpuUsage = usage

                if (!isNaN(freq) && freq >= 0)
                    gpuBackend.gpuFreq = freq

                gpuBackend.pushHistory(usage, "gpuUsageHistory")
                gpuBackend.pushHistory(isNaN(freq) ? 0 : freq, "gpuFreqHistory")

                if (!gpuBackend.isReady)
                    gpuBackend.isReady = true
            }
        }
    }
}
