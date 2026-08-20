// ClockHud.qml --- analog ring + compact day / date / time
import QtQuick
import QtQuick.Layouts 1.15
import QtQuick.Shapes
import "../.."

Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: Tokens.topBarHeight

    property int hours: 0
    property int minutes: 0
    property int seconds: 0
    property string dayName: ""
    property string dateLine: ""
    property string timeLine: ""
    property string lastTimeGreetingDate: ""

    function tickClock() {
        const now = new Date()
        root.hours = now.getHours()
        root.minutes = now.getMinutes()
        root.seconds = now.getSeconds()
        root.dayName = Qt.formatDate(now, "ddd").toUpperCase()
        root.dateLine = Qt.formatDate(now, "dd MMM").toUpperCase()
        root.timeLine = Qt.formatTime(now, "hh:mm:ss")
        root.checkTimeOfDay()
    }

    function checkTimeOfDay() {
        const now = new Date()
        const h = now.getHours()
        const dateStr = Qt.formatDate(now, "yyyy-MM-dd")

        let window = ""
        let msg = ""

        if (h >= 5 && h < 8) {
            window = "dawn"
            msg = "GOOD MORNING"
        } else if (h >= 8 && h < 12) {
            window = "morning"
            msg = "GOOD MORNING"
        } else if (h >= 17 && h < 21) {
            window = "evening"
            msg = "GOOD EVENING"
        } else if (h >= 0 && h < 5) {
            window = "night"
            msg = "LATE SESSION"
        } else {
            return
        }

        const guardKey = dateStr + "|" + window
        if (root.lastTimeGreetingDate === guardKey)
            return

        root.lastTimeGreetingDate = guardKey
        Globals.toast(msg, Qt.formatTime(now, "hh:mm"), "Clock", "low", 5000)
    }

    Component.onCompleted: root.tickClock()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.tickClock()
    }

    RowLayout {
        id: row
        height: parent.height
        spacing: Tokens.spacingSm

        Item {
            id: clockFace
            readonly property int faceSize: Math.round(
                Math.max(16, Tokens.topBarHeight * 0.72)
            )
            Layout.fillWidth: false
            Layout.fillHeight: false
            Layout.preferredWidth: faceSize
            Layout.preferredHeight: faceSize
            Layout.alignment: Qt.AlignVCenter

            readonly property real cx: width / 2
            readonly property real cy: height / 2
            readonly property real r: Math.min(width, height) / 2 - 1.5

            Rectangle {
                anchors.centerIn: parent
                width: parent.width - 4
                height: width
                radius: width / 2
                color: Qt.rgba(Theme.bgElevated.r, Theme.bgElevated.g, Theme.bgElevated.b, 0.55)
            }

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeWidth: 1.5
                    strokeColor: Theme.accent
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap

                    PathAngleArc {
                        centerX: clockFace.cx
                        centerY: clockFace.cy
                        radiusX: clockFace.r
                        radiusY: clockFace.r
                        startAngle: -90
                        sweepAngle: (root.seconds / 60) * 360
                    }
                }
            }

            Rectangle {
                width: 1.5
                height: clockFace.r * 0.42
                radius: 1
                color: Theme.textPrimary
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.verticalCenter
                transformOrigin: Item.Bottom
                rotation: ((root.hours % 12) + root.minutes / 60) * 30
            }

            Rectangle {
                width: 1.2
                height: clockFace.r * 0.62
                radius: 1
                color: Theme.accent
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.verticalCenter
                transformOrigin: Item.Bottom
                rotation: (root.minutes + root.seconds / 60) * 6
            }

            Rectangle {
                anchors.centerIn: parent
                width: 3
                height: 3
                radius: 1.5
                color: Theme.accent
            }
        }

        ColumnLayout {
            Layout.fillWidth: false
            Layout.fillHeight: false
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: root.dayName + " · " + root.dateLine
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                font.letterSpacing: 1.0
                color: Theme.accent
            }
            Text {
                Layout.fillWidth: true
                text: root.timeLine
                font.family: Theme.fontMono
                font.pixelSize: Tokens.fontSizeSmall
                color: Theme.textPrimary
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Globals.toggleCenterPanel("dashboard")
    }
}
