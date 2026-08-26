pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import ".."

Rectangle {
    id: root

    required property int rootHeight

    property string osName: ""
    property string userName: Quickshell.env("USER") || ""
    property string hostName: ""
    property string wmName: Quickshell.env("XDG_CURRENT_DESKTOP") || "Hyprland"
    property string uptimeText: "--:--"

    implicitHeight: col.implicitHeight + Tokens.paddingV * 2
    radius: Tokens.radiusMd
    color: Theme.bgSurface
    border.color: Theme.borderIdle
    border.width: Tokens.strokeWidth
    clip: true

    readonly property bool hasBattery: UPower.displayDevice && UPower.displayDevice.isLaptopBattery
    readonly property string battLine: {
        if (!hasBattery)
            return ""
        const pct = Math.round(UPower.displayDevice.percentage * 100)
        const charging = [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge]
            .indexOf(UPower.displayDevice.state) !== -1
        return (charging ? "(+) " : "") + pct + "%"
    }

    function formatUptime(secs) {
        secs = Math.floor(secs)
        const d = Math.floor(secs / 86400)
        const h = Math.floor((secs % 86400) / 3600)
        const m = Math.floor((secs % 3600) / 60)
        const pad = (n) => (n < 10 ? "0" : "") + n
        if (d > 0)
            return d + "d " + pad(h) + "h " + pad(m) + "m"
        return pad(h) + ":" + pad(m)
    }

    Process {
        running: true
        command: [
            "bash", "-c",
            ". /etc/os-release 2>/dev/null; printf '%s\\n' \"${PRETTY_NAME:-Linux}\"; hostname -s"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                if (lines.length)
                    root.osName = lines[0]
                if (lines.length > 1)
                    root.hostName = lines[1]
            }
        }
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

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.paddingH
        spacing: Tokens.spacingXs

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacingSm

            Rectangle {
                implicitWidth: prompt.implicitWidth + Tokens.paddingH
                implicitHeight: prompt.implicitHeight + Tokens.spacingXss * 2
                radius: Tokens.radiusSm
                color: Theme.accent
                Text {
                    id: prompt
                    anchors.centerIn: parent
                    text: ">"
                    font.family: Theme.fontMono
                    font.pixelSize: Tokens.fontSizeSmall
                    color: Theme.bgPrimary
                }
            }

            Text {
                Layout.fillWidth: true
                text: "fetch"
                font.family: Theme.fontMono
                font.pixelSize: Tokens.fontSizeSmall
                color: Theme.textPrimary
                elide: Text.ElideRight
            }
        }

        Repeater {
            model: {
                const items = []
                if (root.osName.length)
                    items.push("OS    " + root.osName)
                items.push("USER  " + root.userName)
                if (root.hostName.length)
                    items.push("HOST  " + root.hostName)
                items.push("WM    " + root.wmName)
                items.push("UP    " + root.uptimeText)
                if (root.battLine.length)
                    items.push("BATT  " + root.battLine)
                return items
            }

            Text {
                required property string modelData
                Layout.fillWidth: true
                text: modelData
                font.family: Theme.fontMono
                font.pixelSize: Tokens.fontSizeTiny
                color: Theme.textSecondary
                elide: Text.ElideRight
            }
        }
    }
}
