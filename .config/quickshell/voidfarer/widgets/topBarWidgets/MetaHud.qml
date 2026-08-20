// MetaHud.qml --- live weather + wifi (SSID / signal)
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts 1.15
import "../.."

Item {
    id: root
    implicitWidth: col.implicitWidth
    implicitHeight: Tokens.topBarHeight

    property string weatherEmoji: ""
    property string weatherTemp:  ""
    property string wifiSsid:     ""
    property int    wifiSignal:   -1
    property bool   wifiLinked:   false

    readonly property string wifiBars: {
        const s = wifiSignal
        if (!wifiLinked || s < 0)
            return "····"
        if (s >= 75) return "▂▄▆█"
        if (s >= 50) return "▂▄▆·"
        if (s >= 25) return "▂▄··"
        return "▂···"
    }

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

    Component.onCompleted: {
        weatherProc.running = true
        wifiProc.running = true
    }

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
                if (!raw.length)
                    return
                const parts = raw.split("|")
                root.weatherEmoji = (parts[0] || "").trim()
                let temp = (parts[1] || "").trim()
                temp = temp.replace(/^\+/, "").replace(/C$/i, "").replace(/°$/, "°")
                if (temp.length && temp.indexOf("°") < 0)
                    temp = temp + "°"
                root.weatherTemp = temp
            }
        }
    }

    Timer {
        interval: Tokens.weatherRefreshMs
        running: true
        repeat: true
        onTriggered: weatherProc.running = true
    }

    Process {
        id: wifiProc
        command: [
            "bash", "-c",
            "line=$(nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi 2>/dev/null"
                + " | awk -F: '$1==\"yes\"{print $2\"|\"$3; exit}')\n"
                + "if [ -n \"$line\" ]; then echo \"$line\"; exit 0; fi\n"
                + "state=$(nmcli -t -f STATE g 2>/dev/null | head -1)\n"
                + "echo \"|$state\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = text.trim()
                if (!raw.length) {
                    root.wifiLinked = false
                    root.wifiSsid = ""
                    root.wifiSignal = -1
                    return
                }
                const parts = raw.split("|")
                const ssid = (parts[0] || "").trim()
                const sigOrState = (parts[1] || "").trim()
                if (ssid.length) {
                    root.wifiLinked = true
                    root.wifiSsid = ssid
                    const n = parseInt(sigOrState)
                    root.wifiSignal = isNaN(n) ? 0 : n
                } else {
                    root.wifiLinked = false
                    root.wifiSsid = ""
                    root.wifiSignal = -1
                    if (sigOrState.toLowerCase().indexOf("disconnect") >= 0
                        || sigOrState.toLowerCase().indexOf("unavail") >= 0)
                        root.wifiSsid = "offline"
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

    ColumnLayout {
        id: col
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Text {
            id: metaTop
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            font.family: Theme.fontMono
            font.pixelSize: Tokens.fontSizeSmall
            color: Theme.textSecondary
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            text: root.metaLine
        }

        Text {
            id: metaSsid
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            font.family: Theme.fontMono
            font.pixelSize: Tokens.fontSizeSmall
            font.weight: Font.Medium
            color: Theme.textPrimary
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            visible: root.wifiLinked && root.wifiSsid.length > 0
            text: root.wifiSsid
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Globals.toggleEdgePanel("wifi")
    }
}
