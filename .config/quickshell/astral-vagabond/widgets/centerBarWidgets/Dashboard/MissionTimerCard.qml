// MissionTimerCard.qml --- compact combat focus timer
import QtQuick
import QtQuick.Layouts
import "../../.."

Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.minimumWidth: 0
    Layout.maximumHeight: implicitHeight
    implicitHeight: col.implicitHeight + 2 * Tokens.paddingV
    radius: Tokens.radiusMd
    color: Theme.bgSurface
    border.color: running ? Theme.borderActive : Theme.borderIdle
    border.width: Tokens.strokeWidth
    clip: true

    property string mode: "focus"
    property int totalSec: Tokens.missionFocusSec
    property int remainingSec: Tokens.missionFocusSec
    property bool running: false
    property int sessionCount: 0

    readonly property real progress: totalSec > 0
        ? Math.max(0, Math.min(1, 1 - (remainingSec / totalSec)))
        : 0

    function pad(n) {
        return (n < 10 ? "0" : "") + n
    }

    function formatTime(secs) {
        secs = Math.max(0, Math.floor(secs))
        return pad(Math.floor(secs / 60)) + ":" + pad(secs % 60)
    }

    readonly property string clockText: formatTime(remainingSec)

    readonly property string modeLabel: {
        if (mode === "break") return "RELOAD"
        if (mode === "long")  return "DEBRIEF"
        return "COMBAT"
    }

    function applyMode(m) {
        mode = m
        if (m === "break")
            totalSec = Tokens.missionBreakSec
        else if (m === "long")
            totalSec = Tokens.missionLongBreakSec
        else
            totalSec = Tokens.missionFocusSec
        remainingSec = totalSec
        running = false
    }

    function toggle() {
        if (remainingSec <= 0)
            remainingSec = totalSec
        running = !running
    }

    function reset() {
        remainingSec = totalSec
        running = false
    }

    function complete() {
        running = false
        remainingSec = 0
        if (mode === "focus") {
            sessionCount++
            Globals.toast("MISSION COMPLETE", "Combat phase ended", "Mission")
            applyMode(sessionCount % 4 === 0 ? "long" : "break")
        } else {
            Globals.toast("RELOAD COMPLETE", "Back to combat", "Mission")
            applyMode("focus")
        }
    }

    Timer {
        interval: 1000
        running: root.running
        repeat: true
        onTriggered: {
            if (root.remainingSec <= 1) {
                root.complete()
                return
            }
            root.remainingSec--
        }
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.paddingH
        spacing: Tokens.spacingXss

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacingXs
            Text {
                text: "MISSION"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.accent
            }
            Text {
                Layout.fillWidth: true
                text: root.clockText
                font.family: Theme.fontMono
                font.pixelSize: Tokens.fontSizeMedium
                color: root.running ? Theme.textPrimary : Theme.textSecondary
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
            Text {
                text: root.modeLabel
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                color: root.running ? Theme.stateSafe : Theme.textDim
                elide: Text.ElideRight
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Tokens.usageBarHeight
            radius: Tokens.radiusSm
            color: Theme.bgElevated
            Rectangle {
                width: parent.width * root.progress
                height: parent.height
                radius: parent.radius
                color: root.mode === "focus" ? Theme.accent : Theme.stateSafe
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacingXs

            Repeater {
                model: [
                    { key: "toggle", label: root.running ? "HOLD" : "GO" },
                    { key: "reset",  label: "RST" },
                    { key: "cycle",  label: "PH" }
                ]

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Tokens.actionBtnHeight
                    Layout.maximumHeight: Tokens.actionBtnHeight
                    radius: Tokens.radiusSm
                    color: btnMouse.containsMouse ? Theme.bgElevated : Theme.bgPrimary
                    border.color: modelData.key === "toggle" && root.running
                        ? Theme.borderActive : Theme.borderIdle
                    border.width: Tokens.strokeWidth
                    clip: true

                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        font.family: Theme.fontDisplay
                        font.pixelSize: Tokens.fontSizeLabel
                        color: modelData.key === "toggle" && root.running
                            ? Theme.accent : Theme.textSecondary
                    }

                    MouseArea {
                        id: btnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.key === "toggle")
                                root.toggle()
                            else if (modelData.key === "reset")
                                root.reset()
                            else if (root.mode === "focus")
                                root.applyMode("break")
                            else if (root.mode === "break")
                                root.applyMode("long")
                            else
                                root.applyMode("focus")
                        }
                    }
                }
            }
        }
    }
}
