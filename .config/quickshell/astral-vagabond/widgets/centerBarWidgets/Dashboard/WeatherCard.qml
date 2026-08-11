// WeatherCard.qml --- current conditions + scrollable week forecast (token-driven)
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../.."
import "../../../utils"

Rectangle {
    id: root
    // Height comes only from parent Layout — never force a floor that overflows
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.minimumHeight: 0
    radius: Tokens.radiusMd
    color: Theme.bgSurface
    border.color: Theme.borderIdle
    border.width: Tokens.strokeWidth
    clip: true

    property string currentLine: "FETCHING..."
    property string currentDetail: ""
    ListModel { id: weekModel }

    readonly property var dowShort: ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    Component.onCompleted: refresh()

    function refresh() {
        fetch.running = true
    }

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
        if (c >= 281 && c <= 314)
            return "❄"
        if (c >= 317 && c <= 350)
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
                root.currentLine = [cur.weatherCode ? root.weatherEmoji(cur.weatherCode) : "", temp, desc]
                    .filter(s => s && String(s).length).join("  ")
                root.currentDetail = [
                    feels ? ("feels " + feels) : "",
                    cur.humidity ? (cur.humidity + "% rh") : "",
                    cur.windspeedKmph ? (cur.windspeedKmph + " km/h") : ""
                ].filter(s => s.length).join(" * ")
            }

            const days = data.weather || []
            const today = new Date()
            const limit = Math.min(days.length, Tokens.forecastDayCount)
            for (let i = 0; i < limit; i++) {
                const d = days[i]
                const dateStr = d.date || ""
                let label = "D" + (i + 1)
                let isToday = false
                if (dateStr.length) {
                    const parts = dateStr.split("-")
                    if (parts.length === 3) {
                        const dt = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]))
                        label = root.dowShort[dt.getDay()]
                        isToday = dt.getFullYear() === today.getFullYear()
                            && dt.getMonth() === today.getMonth()
                            && dt.getDate() === today.getDate()
                        if (isToday)
                            label = "TODAY"
                    }
                }

                let code = ""
                let desc = ""
                let rain = ""
                if (d.hourly && d.hourly.length) {
                    const midIdx = Math.min(Tokens.weatherHourlySampleIndex, d.hourly.length - 1)
                    const mid = d.hourly[midIdx]
                    code = mid.weatherCode || ""
                    desc = (mid.weatherDesc && mid.weatherDesc[0] && mid.weatherDesc[0].value) || ""
                    if (mid.chanceofrain !== undefined && mid.chanceofrain !== "")
                        rain = mid.chanceofrain + "%"
                }

                weekModel.append({
                    label: label,
                    isToday: isToday,
                    hi: (d.maxtempC !== undefined ? d.maxtempC : "?") + "°",
                    lo: (d.mintempC !== undefined ? d.mintempC : "?") + "°",
                    emoji: root.weatherEmoji(code),
                    desc: desc,
                    rain: rain
                })
            }
            if (weekModel.count === 0 && root.currentLine === "FETCHING...")
                root.currentLine = "NO DATA"
        } catch (e) {
            root.currentLine = "PARSE ERROR"
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
        stderr: StdioCollector {
            onStreamFinished: {
                if (root.currentLine === "FETCHING...")
                    root.currentLine = "OFFLINE"
            }
        }
    }

    Timer {
        interval: Tokens.weatherRefreshMs
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.paddingH
        spacing: Tokens.spacingXs

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "WEATHER"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.accent
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "↻"
                font.pixelSize: Tokens.fontSizeSmall
                color: refMouse.containsMouse ? Theme.accent : Theme.textDim
                MouseArea {
                    id: refMouse
                    anchors.fill: parent
                    anchors.margins: -Tokens.spacingXs
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.refresh()
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.currentLine
            font.family: Theme.fontMono
            font.pixelSize: Tokens.fontSizeSmall
            color: Theme.textPrimary
            wrapMode: Text.WordWrap
            maximumLineCount: Tokens.weatherCurrentMaxLines
            elide: Text.ElideRight
            clip: true
        }
        Text {
            Layout.fillWidth: true
            visible: root.currentDetail.length > 0
            text: root.currentDetail
            font.family: Theme.fontMono
            font.pixelSize: Tokens.fontSizeTiny
            color: Theme.textSecondary
            elide: Text.ElideRight
            maximumLineCount: 1
            clip: true
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Tokens.strokeWidth
            color: Theme.borderIdle
            opacity: Theme.opacityMuted
        }

        Text {
            text: "7-DAY"
            font.family: Theme.fontDisplay
            font.pixelSize: Tokens.fontSizeLabel
            color: Theme.textMuted
        }

        // Fixed row height + scroll --- never squeeze days to fit
        ListView {
            id: weekList
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: Tokens.forecastRowHeight
            clip: true
            spacing: Tokens.spacingXss
            model: weekModel
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            interactive: contentHeight > height
            ScrollBar.vertical: MonoScrollBar {}

            delegate: Rectangle {
                // Gutter when scrollbar is visible
                width: Math.max(0, weekList.width
                    - (weekList.contentHeight > weekList.height
                        ? Tokens.borderXs + Tokens.spacingXss + 2
                        : 0))
                height: Tokens.forecastRowHeight
                radius: Tokens.radiusSm
                color: model.isToday ? Theme.bgElevated : Theme.bgPrimary
                border.color: model.isToday ? Theme.borderActive : Theme.borderIdle
                border.width: Tokens.strokeWidth
                clip: true

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Tokens.paddingH
                    anchors.rightMargin: Tokens.paddingH
                    spacing: Tokens.spacingXs

                    Text {
                        text: model.label
                        font.family: Theme.fontDisplay
                        font.pixelSize: Tokens.fontSizeLabel
                        color: model.isToday ? Theme.accent : Theme.textDim
                        Layout.preferredWidth: Tokens.forecastDowWidth
                        elide: Text.ElideRight
                    }

                    Text {
                        text: model.emoji
                        font.pixelSize: Tokens.fontSizeSmall
                        color: Theme.textPrimary
                        Layout.preferredWidth: Tokens.forecastIconWidth
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        Layout.fillWidth: true
                        text: model.desc
                        font.family: Theme.fontMono
                        font.pixelSize: Tokens.fontSizeTiny
                        color: Theme.textSecondary
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    Text {
                        visible: model.rain.length > 0
                        text: model.rain
                        font.family: Theme.fontMono
                        font.pixelSize: Tokens.fontSizeTiny
                        color: Theme.textDim
                    }

                    Text {
                        text: model.lo + " / " + model.hi
                        font.family: Theme.fontMono
                        font.pixelSize: Tokens.fontSizeTiny
                        color: Theme.textPrimary
                        Layout.preferredWidth: Tokens.forecastTempWidth
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: weekList.count === 0
                text: "NO FORECAST"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.textDim
            }
        }
    }
}
