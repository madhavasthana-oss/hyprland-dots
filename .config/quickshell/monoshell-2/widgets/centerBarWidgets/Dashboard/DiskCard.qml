// DiskCard.qml --- compact storage with circumferential arc (not a linear bar)
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

    property real rootPct: 0
    property string usedLine: "…"

    function refresh() {
        diskProc.running = true
    }

    function parseDf(text) {
        const lines = text.trim().split("\n")
        for (let i = 0; i < lines.length; i++) {
            const parts = lines[i].split("|")
            if (parts.length < 5 || parts[0] !== "/")
                continue
            const pct = parseFloat(parts[4].replace("%", ""))
            if (isNaN(pct))
                continue
            root.rootPct = Math.max(0, Math.min(1, pct / 100))
            // used / total — full string, UI wraps (no free line)
            root.usedLine = parts[2] + " / " + parts[1]
            arc.requestPaint()
            return
        }
        root.usedLine = "NO DATA"
        arc.requestPaint()
    }

    function arcColor(pct) {
        if (pct >= 0.9) return Theme.stateCritical
        if (pct >= 0.75) return Theme.stateWarning
        return Theme.stateSafe
    }

    Process {
        id: diskProc
        command: [
            "bash", "-c",
            "df -h -P / 2>/dev/null | awk 'NR>1 {print $6\"|\"$2\"|\"$3\"|\"$4\"|\"$5}'"
        ]
        stdout: StdioCollector {
            onStreamFinished: root.parseDf(text.length ? text : "")
        }
    }

    Timer {
        interval: Tokens.diskRefreshMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    onWidthChanged:  arc.requestPaint()
    onHeightChanged: arc.requestPaint()
    onRootPctChanged: arc.requestPaint()

    RowLayout {
        anchors.fill: parent
        anchors.margins: Tokens.paddingH
        spacing: Tokens.spacingXs

        // Circular arc gauge
        Item {
            Layout.preferredWidth: Tokens.diskArcSize
            Layout.preferredHeight: Tokens.diskArcSize
            Layout.alignment: Qt.AlignVCenter

            Canvas {
                id: arc
                anchors.fill: parent
                antialiasing: true

                onPaint: {
                    const ctx = getContext("2d")
                    const w = width
                    const h = height
                    ctx.reset()
                    if (w < 4 || h < 4)
                        return

                    const cx = w / 2
                    const cy = h / 2
                    // Leave room for stroke
                    const stroke = Math.max(2.5, Math.min(w, h) * 0.12)
                    const r = Math.min(w, h) / 2 - stroke

                    // Full track (dim ring)
                    ctx.beginPath()
                    ctx.lineWidth = stroke
                    ctx.lineCap = "round"
                    ctx.strokeStyle = Theme.bgElevated.toString()
                    ctx.arc(cx, cy, r, 0, Math.PI * 2, false)
                    ctx.stroke()

                    // Filled arc from top (-π/2), clockwise with usage %
                    const pct = Math.max(0, Math.min(1, root.rootPct))
                    if (pct > 0.001) {
                        const start = -Math.PI / 2
                        const end = start + Math.PI * 2 * pct
                        ctx.beginPath()
                        ctx.lineWidth = stroke
                        ctx.lineCap = "round"
                        ctx.strokeStyle = root.arcColor(pct).toString()
                        ctx.arc(cx, cy, r, start, end, false)
                        ctx.stroke()
                    }
                }
            }

            // Center percentage
            Text {
                anchors.centerIn: parent
                text: Math.round(root.rootPct * 100) + "%"
                font.family: Theme.fontMono
                font.pixelSize: Tokens.fontSizeTiny
                color: root.arcColor(root.rootPct)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Tokens.spacingXss

            Text {
                text: "DISK"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.accent
            }
            Text {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: root.usedLine
                font.family: Theme.fontMono
                font.pixelSize: Tokens.fontSizeTiny
                color: Theme.textSecondary
                wrapMode: Text.WordWrap
                elide: Text.ElideNone
                maximumLineCount: 3
                verticalAlignment: Text.AlignTop
            }
        }
    }
}
