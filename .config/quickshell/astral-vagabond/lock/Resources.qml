pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    id: root

    property real cpuPct: 0
    property real ramPct: 0
    property real diskPct: 0
    property int cpuTemp: -1
    property var _cpuPrev: null

    implicitHeight: layout.implicitHeight + Tokens.paddingV * 2
    radius: Tokens.radiusMd
    color: Theme.bgSurface
    border.color: Theme.borderIdle
    border.width: Tokens.strokeWidth

    function parseStat(text) {
        const line = text.trim().split("\n")[0]
        if (!line || line.indexOf("cpu ") !== 0)
            return
        const f = line.trim().split(/\s+/)
        let idle = Number(f[4]) + Number(f[5] || 0)
        let total = 0
        for (let i = 1; i < f.length; i++)
            total += Number(f[i])
        if (root._cpuPrev) {
            const dt = total - root._cpuPrev.total
            const di = idle - root._cpuPrev.idle
            if (dt > 0)
                root.cpuPct = Math.max(0, Math.min(1, (dt - di) / dt))
        }
        root._cpuPrev = { idle: idle, total: total }
    }

    function parseMem(text) {
        const lines = text.trim().split("\n")
        let total = 0
        let avail = 0
        for (let i = 0; i < lines.length; i++) {
            if (lines[i].indexOf("MemTotal:") === 0)
                total = parseInt(lines[i].replace(/[^0-9]/g, ""), 10)
            else if (lines[i].indexOf("MemAvailable:") === 0)
                avail = parseInt(lines[i].replace(/[^0-9]/g, ""), 10)
        }
        if (total > 0)
            root.ramPct = Math.max(0, Math.min(1, (total - avail) / total))
    }

    function parseDf(text) {
        const line = text.trim().split("\n")[0] || ""
        const pct = parseFloat(line.replace("%", ""))
        if (!isNaN(pct))
            root.diskPct = Math.max(0, Math.min(1, pct / 100))
    }

    Process {
        id: cpuProc
        command: ["cat", "/proc/stat"]
        stdout: StdioCollector {
            onStreamFinished: root.parseStat(text)
        }
    }

    Process {
        id: memProc
        command: ["cat", "/proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: root.parseMem(text)
        }
    }

    Process {
        id: diskProc
        command: ["bash", "-c", "df -P / | awk 'NR==2 {print $5}'"]
        stdout: StdioCollector {
            onStreamFinished: root.parseDf(text)
        }
    }

    Process {
        id: tempProc
        command: ["bash", "-c", "sensors -j 2>/dev/null | awk 'BEGIN{m=-1} /_input/{gsub(/[^0-9.]/,\"\"); if($0+0>m && $0+0<120) m=$0+0} END{if(m>=0) printf \"%d\", m}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = parseInt(text.trim(), 10)
                root.cpuTemp = isNaN(n) ? -1 : n
            }
        }
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuProc.running = true
            memProc.running = true
            diskProc.running = true
            tempProc.running = true
        }
    }

    RowLayout {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.paddingH
        spacing: Tokens.spacingMd

        ResourcePill {
            label: "CPU"
            value: Math.round(root.cpuPct * 100) + "%"
            fill: root.cpuPct
            extra: root.cpuTemp >= 0 ? (root.cpuTemp + "°") : ""
        }
        ResourcePill {
            label: "RAM"
            value: Math.round(root.ramPct * 100) + "%"
            fill: root.ramPct
        }
        ResourcePill {
            label: "DISK"
            value: Math.round(root.diskPct * 100) + "%"
            fill: root.diskPct
        }
    }

    component ResourcePill: ColumnLayout {
        id: pill
        required property string label
        required property string value
        required property real fill
        property string extra: ""

        Layout.fillWidth: true
        spacing: Tokens.spacingXss

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: pill.label
            font.family: Theme.fontDisplay
            font.pixelSize: Tokens.fontSizeLabel
            color: Theme.accent
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: pill.value
            font.family: Theme.fontMono
            font.pixelSize: Tokens.fontSizeMedium
            color: Theme.textPrimary
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Tokens.usageBarHeight
            radius: height / 2
            color: Theme.bgElevated
            border.color: Theme.borderIdle
            border.width: Tokens.strokeWidth

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.max(0, parent.width * pill.fill)
                radius: parent.radius
                color: Theme.accent
                Behavior on width {
                    NumberAnimation { duration: Tokens.animMedium; easing.type: Easing.OutCubic }
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: pill.extra.length > 0
            text: pill.extra
            font.family: Theme.fontMono
            font.pixelSize: Tokens.fontSizeTiny
            color: Theme.textMuted
        }
    }
}
