pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    id: root

    required property int rootHeight

    property string currentLine: "FETCHING…"
    property string currentDetail: ""
    ListModel { id: weekModel }

    readonly property var dowShort: ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    readonly property bool showForecast: rootHeight >= Tokens.lockShowForecastHeight

    implicitHeight: col.implicitHeight + Tokens.paddingV * 2
    radius: Tokens.radiusMd
    color: Theme.bgSurface
    border.color: Theme.borderIdle
    border.width: Tokens.strokeWidth
    clip: true

    function weatherEmoji(code) {
        const c = parseInt(code)
        if (isNaN(c))
            return "*"
        if (c === 113)
            return "☀"
        if (c === 116)
            return "⛅"
        if (c === 119 || c === 122)
            return "☁"
        if (c === 143 || c === 248 || c === 260)
            return "fog"
        if (c >= 176 && c <= 266)
            return "🌦"
        if (c >= 281 && c <= 350)
            return "❄"
        if (c >= 353 && c <= 377)
            return "🌧"
        if (c >= 386 && c <= 395)
            return "⛈"
        return "*"
    }

    function parseForecast(text) {
        weekModel.clear()
        try {
            const data = JSON.parse(text)
            const cur = data.current_condition && data.current_condition[0]
            if (cur) {
                const desc = (cur.weatherDesc && cur.weatherDesc[0] && cur.weatherDesc[0].value) || ""
                const temp = cur.temp_C !== undefined ? (cur.temp_C + "°C") : ""
                const feels = cur.FeelsLikeC !== undefined ? (cur.FeelsLikeC + "°C") : ""
                root.currentLine = [root.weatherEmoji(cur.weatherCode), temp, desc]
                    .filter(s => s && String(s).length).join("  ")
                root.currentDetail = [
                    feels ? ("feels " + feels) : "",
                    cur.humidity ? (cur.humidity + "% rh") : "",
                    cur.windspeedKmph ? (cur.windspeedKmph + " km/h") : ""
                ].filter(s => s.length).join("  ·  ")
            }

            const days = data.weather || []
            const today = new Date()
            const limit = Math.min(days.length, 3)
            for (let i = 0; i < limit; i++) {
                const d = days[i]
                const dateStr = d.date || ""
                let label = "D" + (i + 1)
                if (dateStr.length) {
                    const parts = dateStr.split("-")
                    if (parts.length === 3) {
                        const dt = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]))
                        label = root.dowShort[dt.getDay()]
                        if (dt.getFullYear() === today.getFullYear()
                                && dt.getMonth() === today.getMonth()
                                && dt.getDate() === today.getDate())
                            label = "NOW"
                    }
                }
                let code = ""
                if (d.hourly && d.hourly.length) {
                    const midIdx = Math.min(Tokens.weatherHourlySampleIndex, d.hourly.length - 1)
                    code = d.hourly[midIdx].weatherCode || ""
                }
                weekModel.append({
                    label: label,
                    hi: (d.maxtempC !== undefined ? d.maxtempC : "?") + "°",
                    lo: (d.mintempC !== undefined ? d.mintempC : "?") + "°",
                    emoji: root.weatherEmoji(code)
                })
            }
            if (weekModel.count === 0 && root.currentLine === "FETCHING…")
                root.currentLine = "NO DATA"
        } catch (e) {
            root.currentLine = "OFFLINE"
            root.currentDetail = ""
        }
    }

    Process {
        id: fetch
        command: [
            "bash", "-c",
            "curl -s --max-time " + Tokens.weatherFetchTimeoutSec
                + " 'wttr.in/?format=j1' 2>/dev/null || echo '{}'"
        ]
        stdout: StdioCollector {
            onStreamFinished: root.parseForecast(text.length ? text : "{}")
        }
    }

    Timer {
        interval: Tokens.weatherRefreshMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: fetch.running = true
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.paddingH
        spacing: Tokens.spacingXs

        Text {
            text: "WEATHER"
            font.family: Theme.fontDisplay
            font.pixelSize: Tokens.fontSizeLabel
            color: Theme.accent
        }

        Text {
            Layout.fillWidth: true
            text: root.currentLine
            font.family: Theme.fontDisplay
            font.pixelSize: Tokens.fontSizeMedium
            color: Theme.textPrimary
            elide: Text.ElideRight
            wrapMode: Text.Wrap
            maximumLineCount: 2
        }

        Text {
            Layout.fillWidth: true
            visible: root.currentDetail.length > 0
            text: root.currentDetail
            font.family: Theme.fontMono
            font.pixelSize: Tokens.fontSizeTiny
            color: Theme.textSecondary
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.showForecast && weekModel.count > 0
            spacing: Tokens.spacingXs

            Repeater {
                model: weekModel
                Rectangle {
                    required property string label
                    required property string hi
                    required property string lo
                    required property string emoji

                    Layout.fillWidth: true
                    implicitHeight: fcol.implicitHeight + Tokens.spacingXs * 2
                    radius: Tokens.radiusSm
                    color: Theme.bgElevated
                    border.color: Theme.borderIdle
                    border.width: Tokens.strokeWidth

                    ColumnLayout {
                        id: fcol
                        anchors.centerIn: parent
                        spacing: 0
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: label
                            font.family: Theme.fontMono
                            font.pixelSize: Tokens.fontSizeTiny
                            color: Theme.textMuted
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: emoji
                            font.pixelSize: Tokens.fontSizeSmall
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: hi + " / " + lo
                            font.family: Theme.fontMono
                            font.pixelSize: Tokens.fontSizeTiny
                            color: Theme.textSecondary
                        }
                    }
                }
            }
        }
    }
}
