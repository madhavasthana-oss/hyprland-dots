// CalendarCard.qml --- month grid, pure QML
import QtQuick
import QtQuick.Layouts
import "../../.."

Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.minimumHeight: 0
    radius: Tokens.radiusMd
    color: Theme.bgSurface
    border.color: Theme.borderIdle
    border.width: Tokens.strokeWidth
    clip: true

    property int viewYear:  new Date().getFullYear()
    property int viewMonth: new Date().getMonth() // 0-11

    readonly property var monthNames: [
        "JAN", "FEB", "MAR", "APR", "MAY", "JUN",
        "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"
    ]

    function daysInMonth(y, m) {
        return new Date(y, m + 1, 0).getDate()
    }

    // JS: 0=Sun ... 6=Sat --- convert so week starts Monday
    function leadingBlanks(y, m) {
        const dow = new Date(y, m, 1).getDay() // 0 Sun
        return (dow + 6) % 7 // Mon=0
    }

    function buildCells() {
        const cells = []
        const blanks = leadingBlanks(viewYear, viewMonth)
        const dim = daysInMonth(viewYear, viewMonth)
        for (let i = 0; i < blanks; i++)
            cells.push({ day: 0, inMonth: false })
        for (let d = 1; d <= dim; d++)
            cells.push({ day: d, inMonth: true })
        while (cells.length % 7 !== 0)
            cells.push({ day: 0, inMonth: false })
        return cells
    }

    property var cells: buildCells()

    function shiftMonth(delta) {
        let m = viewMonth + delta
        let y = viewYear
        if (m < 0)  { m = 11; y-- }
        if (m > 11) { m = 0;  y++ }
        viewMonth = m
        viewYear = y
        cells = buildCells()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.paddingH
        spacing: Tokens.spacingXs

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "CALENDAR"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.accent
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "‹"
                font.pixelSize: Tokens.fontSizeMedium
                color: prevMouse.containsMouse ? Theme.accent : Theme.textDim
                MouseArea {
                    id: prevMouse
                    anchors.fill: parent
                    anchors.margins: -Tokens.spacingXs
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.shiftMonth(-1)
                }
            }
            Text {
                text: root.monthNames[root.viewMonth] + " " + root.viewYear
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.textPrimary
            }
            Text {
                text: "›"
                font.pixelSize: Tokens.fontSizeMedium
                color: nextMouse.containsMouse ? Theme.accent : Theme.textDim
                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    anchors.margins: -Tokens.spacingXs
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.shiftMonth(1)
                }
            }
        }

        // Weekday headers
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacingXss
            Repeater {
                model: ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    font.family: Theme.fontMono
                    font.pixelSize: Tokens.fontSizeTiny
                    color: Theme.textDim
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 7
            rowSpacing: Tokens.spacingXss
            columnSpacing: Tokens.spacingXss

            Repeater {
                model: root.cells

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 0
                    Layout.minimumWidth: 0
                    radius: Tokens.radiusSm
                    clip: true
                    readonly property bool isToday: {
                        const n = new Date()
                        return modelData.inMonth
                            && modelData.day === n.getDate()
                            && root.viewMonth === n.getMonth()
                            && root.viewYear === n.getFullYear()
                    }
                    color: isToday ? Theme.bgElevated : "transparent"
                    border.color: isToday ? Theme.borderActive : "transparent"
                    border.width: Tokens.strokeWidth

                    Text {
                        anchors.centerIn: parent
                        text: modelData.inMonth ? String(modelData.day) : ""
                        font.family: Theme.fontMono
                        font.pixelSize: Tokens.fontSizeTiny
                        color: isToday ? Theme.accent : Theme.textSecondary
                    }
                }
            }
        }
    }
}
