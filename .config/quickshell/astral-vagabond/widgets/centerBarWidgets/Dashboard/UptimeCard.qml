// UptimeCard.qml --- host uptime from /proc/uptime
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../.."

Rectangle {
    id: root
    Layout.fillWidth: true
    implicitHeight: Math.max(Tokens.listRowHeight + 2 * Tokens.paddingV,
                             col.implicitHeight + 2 * Tokens.paddingV)
    radius: Tokens.radiusMd
    color: Theme.bgSurface
    border.color: Theme.borderIdle
    border.width: Tokens.strokeWidth
    clip: true

    property string uptimeText: "--:--:--"

    function formatUptime(secs) {
        secs = Math.floor(secs)
        const d = Math.floor(secs / 86400)
        const h = Math.floor((secs % 86400) / 3600)
        const m = Math.floor((secs % 3600) / 60)
        const s = secs % 60
        const pad = (n) => (n < 10 ? "0" : "") + n
        if (d > 0)
            return d + "d " + pad(h) + "h " + pad(m) + "m"
        return pad(h) + ":" + pad(m) + ":" + pad(s)
    }

    Process {
        id: uptimeProc
        command: ["cat", "/proc/uptime"]
        stdout: StdioCollector {
            onStreamFinished: {
                const sec = parseFloat(text.trim().split(" ")[0])
                if (!isNaN(sec))
                    root.uptimeText = root.formatUptime(sec)
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: uptimeProc.running = true
    }

    // Single compact row — frees vertical room for weather
    RowLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.paddingH
        anchors.rightMargin: Tokens.paddingH
        spacing: Tokens.spacingXs

        Text {
            text: "UPTIME"
            font.family: Theme.fontDisplay
            font.pixelSize: Tokens.fontSizeLabel
            color: Theme.accent
        }
        Text {
            Layout.fillWidth: true
            text: root.uptimeText + " · ONLINE"
            font.family: Theme.fontMono
            font.pixelSize: Tokens.fontSizeTiny
            color: Theme.stateSafe
            elide: Text.ElideRight
            maximumLineCount: 1
            horizontalAlignment: Text.AlignRight
        }
    }
}
