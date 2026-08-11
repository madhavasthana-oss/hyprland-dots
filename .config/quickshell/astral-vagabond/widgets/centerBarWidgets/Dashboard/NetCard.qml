// NetCard.qml --- stylized RX/TX equalizer bars (compact, side-by-side with DISK)
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../.."

Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: Tokens.diskNetCardHeight
    Layout.minimumHeight: Tokens.diskNetCardHeight
    Layout.maximumHeight: Tokens.diskNetCardHeight
    radius: Tokens.radiusMd
    color: Theme.bgSurface
    border.color: Theme.borderIdle
    border.width: Tokens.strokeWidth
    clip: true

    property string ssid: ""
    property string iface: "—"
    property real rxBps: 0
    property real txBps: 0
    property string rxLabel: "0"
    property string txLabel: "0"
    property real lastRx: -1
    property real lastTx: -1
    property real lastTs: 0

    // Peak tracking so bars feel responsive without always pegging
    property real peakBps: 256 * 1024   // floor peak 256 KB/s
    readonly property int barCount: Tokens.netBarCount

    function formatShort(bps) {
        if (bps < 0 || isNaN(bps))
            return "0"
        const units = ["B", "K", "M", "G"]
        let v = bps
        let i = 0
        while (v >= 1024 && i < units.length - 1) {
            v /= 1024
            i++
        }
        const digits = v >= 100 || i === 0 ? 0 : (v >= 10 ? 1 : 1)
        return v.toFixed(digits) + units[i]
    }

    // 0..1 level from bytes/sec using soft log against rolling peak
    function levelFromBps(bps) {
        if (bps <= 0 || isNaN(bps))
            return 0
        const peak = Math.max(root.peakBps, 1024)
        // log2 scale: quiet activity still lights low bars
        const n = Math.log(1 + bps) / Math.log(1 + peak)
        return Math.max(0, Math.min(1, n))
    }

    readonly property real rxLevel: levelFromBps(rxBps)
    readonly property real txLevel: levelFromBps(txBps)

    function barLit(level, index) {
        // index 0 = shortest/left (or bottom of group)
        const threshold = (index + 0.35) / barCount
        return level >= threshold
    }

    function parseStats(text) {
        const line = text.trim().split("\n")[0] || ""
        const parts = line.split("|")
        if (parts.length < 3)
            return

        const iface = parts[0] || "—"
        const rx = parseFloat(parts[1])
        const tx = parseFloat(parts[2])
        const ssid = parts.length > 3 ? parts[3] : ""

        root.iface = iface.length ? iface : "—"
        root.ssid = ssid

        const now = Date.now() / 1000
        if (root.lastRx >= 0 && root.lastTs > 0 && !isNaN(rx) && !isNaN(tx)) {
            const dt = Math.max(0.001, now - root.lastTs)
            const rB = Math.max(0, (rx - root.lastRx) / dt)
            const tB = Math.max(0, (tx - root.lastTx) / dt)
            root.rxBps = rB
            root.txBps = tB
            root.rxLabel = root.formatShort(rB)
            root.txLabel = root.formatShort(tB)
            // Soft peak decay so bars stay meaningful
            const inst = Math.max(rB, tB)
            if (inst > root.peakBps)
                root.peakBps = inst
            else
                root.peakBps = root.peakBps * 0.92 + inst * 0.08
        }
        if (!isNaN(rx)) root.lastRx = rx
        if (!isNaN(tx)) root.lastTx = tx
        root.lastTs = now
    }

    Process {
        id: netProc
        command: [
            "bash", "-c",
            "IFACE=$(ip -4 route show default 2>/dev/null | awk '{print $5; exit}')\n"
                + "if [ -z \"$IFACE\" ]; then IFACE=$(ip -o link show up 2>/dev/null | awk -F': ' '$2!=\"lo\"{print $2; exit}'); fi\n"
                + "if [ -z \"$IFACE\" ]; then echo '—|0|0||'; exit 0; fi\n"
                + "RX=$(cat /sys/class/net/$IFACE/statistics/rx_bytes 2>/dev/null || echo 0)\n"
                + "TX=$(cat /sys/class/net/$IFACE/statistics/tx_bytes 2>/dev/null || echo 0)\n"
                + "SSID=$(nmcli -t -f DEVICE,ACTIVE,SSID dev wifi 2>/dev/null | awk -F: -v d=\"$IFACE\" '$1==d && $2==\"yes\"{print $3; exit}')\n"
                + "IP=$(ip -4 -o addr show dev \"$IFACE\" 2>/dev/null | awk '{print $4; exit}' | cut -d/ -f1)\n"
                + "printf '%s|%s|%s|%s|%s\\n' \"$IFACE\" \"$RX\" \"$TX\" \"$SSID\" \"$IP\""
        ]
        stdout: StdioCollector {
            onStreamFinished: root.parseStats(text.length ? text : "")
        }
    }

    Timer {
        interval: Tokens.netRefreshMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: netProc.running = true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.paddingH
        spacing: Tokens.spacingXss

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacingXs
            Text {
                text: "NET"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.accent
            }
            Text {
                Layout.fillWidth: true
                text: root.ssid.length ? root.ssid : root.iface
                font.family: Theme.fontMono
                font.pixelSize: Tokens.fontSizeTiny
                color: Theme.textDim
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        // Dual equalizer strips: ↓ RX  |  ↑ TX
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: Tokens.iconSizeLarge
            spacing: Tokens.spacingSm

            // RX bars
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 1

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: Tokens.iconSizeMedium

                    Row {
                        id: rxRow
                        anchors.fill: parent
                        spacing: Tokens.netBarGap

                        Repeater {
                            model: root.barCount
                            Item {
                                width: Math.max(2,
                                    (rxRow.width - (root.barCount - 1) * Tokens.netBarGap)
                                    / root.barCount)
                                height: rxRow.height

                                Rectangle {
                                    width: parent.width
                                    height: Math.max(2, parent.height * ((index + 1) / root.barCount))
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    radius: Tokens.radiusSm
                                    color: root.barLit(root.rxLevel, index)
                                        ? Theme.stateSafe
                                        : Theme.bgElevated
                                    opacity: root.barLit(root.rxLevel, index) ? 1.0 : 0.45

                                    Behavior on color {
                                        ColorAnimation { duration: Tokens.animFast }
                                    }
                                    Behavior on opacity {
                                        NumberAnimation { duration: Tokens.animFast }
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "↓ " + root.rxLabel
                    font.family: Theme.fontMono
                    font.pixelSize: Tokens.fontSizeTiny
                    color: Theme.stateSafe
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }

            // TX bars
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 1

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: Tokens.iconSizeMedium

                    Row {
                        id: txRow
                        anchors.fill: parent
                        spacing: Tokens.netBarGap

                        Repeater {
                            model: root.barCount
                            Item {
                                width: Math.max(2,
                                    (txRow.width - (root.barCount - 1) * Tokens.netBarGap)
                                    / root.barCount)
                                height: txRow.height

                                Rectangle {
                                    width: parent.width
                                    height: Math.max(2, parent.height * ((index + 1) / root.barCount))
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    radius: Tokens.radiusSm
                                    color: root.barLit(root.txLevel, index)
                                        ? Theme.accentWarm
                                        : Theme.bgElevated
                                    opacity: root.barLit(root.txLevel, index) ? 1.0 : 0.45

                                    Behavior on color {
                                        ColorAnimation { duration: Tokens.animFast }
                                    }
                                    Behavior on opacity {
                                        NumberAnimation { duration: Tokens.animFast }
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "↑ " + root.txLabel
                    font.family: Theme.fontMono
                    font.pixelSize: Tokens.fontSizeTiny
                    color: Theme.accentWarm
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
