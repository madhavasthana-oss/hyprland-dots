import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Layouts
import "../../../.."
import "."

Item {

    id: gpuFrontend

    implicitHeight:  Tokens.rightWidth
    implicitWidth:   Tokens.rightWidth

    property var freqBars: []
    property var freqTargets: []
    property real freqFrame: 0

    readonly property string usageText: gpu.gpuUsage === -1
                                        ? "[ PROBING ]"
                                        : gpu.gpuUsage + "%"
    readonly property string freqText:  gpu.gpuFreq === -1
                                        ? "[ PROBING ]"
                                        : String(gpu.gpuFreq)
    readonly property string usageBoxText: gpu.gpuUsage === -1
                                           ? "--%"
                                           : gpu.gpuUsage + "%"
    readonly property string freqBoxText:  gpu.gpuFreq === -1
                                           ? "--"
                                           : String(gpu.gpuFreq)

    Process {
        id: nvtopProc
        command: [
            "ghostty",
            "-e",
            "nvtop"
        ]
    }

    GPUBackend {
        id: gpu
    }

    function launchNvtop() {
        nvtopProc.running = true
    }

    function grabFocus() {
        gpuFrontend.forceActiveFocus()
    }

    Component.onCompleted: {
        if (Globals.activePanel === "gpu")
            grabFocus()
        let base = gpu.gpuFreq > 0 ? gpu.gpuFreq : 500

        for (let i = 0; i < 40; i++) {
            freqBars.push(base + (Math.random() - 0.5) * 40)
            freqTargets.push(base)
        }
    }

    Connections {
        target: Globals
        function onActivePanelChanged() {
            if (Globals.activePanel === "gpu")
                Qt.callLater(gpuFrontend.grabFocus)
        }
    }

    focus: true
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            gpuFrontend.launchNvtop()
            event.accepted = true
        }
    }

    Timer {
        id: repaintTimer
        // Keep usage / frequency canvases in lockstep with GPUBackend poll (500 ms)
        interval: 500
        running: gpu.isReady
        repeat: true
        onTriggered: {
            parent.freqFrame++
            let target = gpu.gpuFreq > 0 ? gpu.gpuFreq : 500
            for (let i = 0; i < 40; i++) {
                parent.freqTargets[i] = target + (Math.random() - 0.5) * 30
                parent.freqBars[i] = parent.freqBars[i] + (parent.freqTargets[i] - parent.freqBars[i]) * 0.12
                            + (Math.random() - 0.5) * 5
            }
            usageCanvas.requestPaint()
            freqCanvas.requestPaint()
        }
    }

    ColumnLayout {
        anchors.fill:    parent
        anchors.margins: Tokens.paddingH
        spacing:         Tokens.barMarginTop
        Text {
            id: gpuName

            Layout.fillWidth: true

            text:                gpu.gpuName
            wrapMode:            Text.WordWrap
            horizontalAlignment: Text.AlignHCenter

            font.family:    Theme.fontDisplay
            font.pixelSize: Tokens.fontSizeSmall

            color: Theme.accent
        }

        RowLayout {
            Layout.fillWidth: true
            Text {
                text:               "USAGE"
                font.family:        Theme.fontDisplay
                font.pixelSize:     Tokens.fontSizeLabel
                color:              Theme.textMuted
                font.letterSpacing: Tokens.spacingXss
            }
            Item { Layout.fillWidth: true }
            Text {
                id: liveUsageLabel
                property int liveVal: gpu.gpuUsage
                text:           gpuFrontend.usageText
                font.family:    Theme.fontMono
                font.pixelSize: Tokens.fontSizeSmall
                color:          liveVal > 85 ? Theme.stateCritical
                                : liveVal > 60 ? Theme.stateWarning
                                : Theme.accent
            }
        }

        Rectangle {
            Layout.fillWidth:  true
            Layout.fillHeight: true
            color:             Theme.bgElevated
            radius:            Tokens.radiusSm
            clip:              true
            border.color:      Theme.borderIdle
            border.width:      Tokens.strokeWidth

            Canvas {
                id: usageCanvas
                anchors.fill: parent

                onPaint: {
                    let ctx = getContext("2d")
                    let w   = width
                    let h   = height
                    let usageHistory = gpu.gpuUsageHistory.filter(v => v !== undefined)
                    ctx.clearRect(0, 0, w, h)

                    ctx.strokeStyle = Theme.borderIdle
                    ctx.lineWidth   = Tokens.strokeWidth / 2
                    ctx.setLineDash([Tokens.spacingXss, Tokens.spacingXs])

                    for (let pct of [0.25, 0.5, 0.75]) {
                        let drawAt = h * (1 - pct)
                        ctx.beginPath()
                        ctx.moveTo(0, drawAt)
                        ctx.lineTo(w, drawAt)
                        ctx.stroke()
                    }

                    ctx.setLineDash([])
                    ctx.fillStyle = Theme.textDim
                    ctx.font      = "bold " + Tokens.fontSizeTiny + "px " + Theme.fontMono
                    ctx.fillText("100", Tokens.radiusSm, Tokens.radiusXl)
                    ctx.fillText("50",  Tokens.radiusSm, h * 0.5 - Tokens.spacingXss)
                    ctx.fillText("0",   Tokens.radiusSm, h - Tokens.radiusSm)

                    let numPts = usageHistory.length
                    if (numPts < 1)
                        return

                    const xget = i => numPts === 1 ? w / 2 : i / (numPts - 1) * w
                    const yget = v => h * (1 - v / 100)

                    let a = Theme.accent
                    let grad = ctx.createLinearGradient(0, 0, 0, h)
                    grad.addColorStop(0,   Qt.rgba(a.r, a.g, a.b, 0.55))
                    grad.addColorStop(0.6, Qt.rgba(a.r, a.g, a.b, 0.12))
                    grad.addColorStop(1,   Qt.rgba(a.r, a.g, a.b, 0.0))

                    ctx.beginPath()
                    ctx.moveTo(xget(0), h)
                    ctx.lineTo(xget(0), yget(usageHistory[0]))

                    for (let idx = 1; idx < numPts; idx++) {
                        let pt1 = [xget(idx - 1), yget(usageHistory[idx - 1])]
                        let pt2 = [xget(idx), yget(usageHistory[idx])]
                        let cx  = (pt1[0] + pt2[0]) / 2
                        ctx.bezierCurveTo(cx, pt1[1], cx, pt2[1], pt2[0], pt2[1])
                    }

                    ctx.lineTo(xget(numPts - 1), h)
                    ctx.closePath()
                    ctx.fillStyle = grad
                    ctx.fill()

                    ctx.strokeStyle = Theme.accent
                    ctx.lineWidth   = Tokens.strokeWidthActive
                    ctx.beginPath()
                    ctx.moveTo(xget(0), yget(usageHistory[0]))

                    for (let idx = 1; idx < numPts; idx++) {
                        let pt1 = [xget(idx - 1), yget(usageHistory[idx - 1])]
                        let pt2 = [xget(idx), yget(usageHistory[idx])]
                        let cx  = (pt1[0] + pt2[0]) / 2
                        ctx.bezierCurveTo(cx, pt1[1], cx, pt2[1], pt2[0], pt2[1])
                    }

                    ctx.stroke()

                    let lastX = xget(numPts - 1)
                    let lastY = yget(usageHistory[numPts - 1])
                    ctx.beginPath()
                    ctx.arc(lastX, lastY, Tokens.radiusSm, 0, Math.PI * 2)
                    ctx.fillStyle = Theme.accent
                    ctx.fill()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text {
                text:               "FREQUENCY"
                font.family:        Theme.fontDisplay
                font.pixelSize:     Tokens.fontSizeLabel
                color:              Theme.textMuted
                font.letterSpacing: Tokens.spacingXss
            }
            Item { Layout.fillWidth: true }
            Text {
                id: liveFreqLabel
                property int liveVal: gpu.gpuFreq
                text:           gpuFrontend.freqText
                font.family:    Theme.fontMono
                font.pixelSize: Tokens.fontSizeSmall
                color:          liveVal > 1000 ? Theme.stateCritical
                                : liveVal > 600 ? Theme.stateWarning
                                : Theme.accent
            }
        }

        Rectangle {
            Layout.fillWidth:  true
            Layout.fillHeight: true
            color:             Theme.bgElevated
            radius:            Tokens.radiusSm
            clip:              true
            border.color:      Theme.borderIdle
            border.width:      Tokens.strokeWidth

            Canvas {
                id: freqCanvas
                anchors.fill: parent

                onPaint: {
                    let ctx = getContext("2d")
                    let w = width
                    let h = height
                    ctx.clearRect(0, 0, w, h)

                    let numBars = gpuFrontend.freqBars.length

                    let pad    = Tokens.spacingXs
                    let gap    = Tokens.spacingXss
                    let drawW  = w - pad * 2
                    let barW   = (drawW - gap * (numBars - 1)) / numBars
                    let maxFreq = 1000

                    for (let i = 0; i < numBars; i++) {
                        let v     = Math.max(0, Math.min(maxFreq, gpuFrontend.freqBars[i]))
                        let ratio = v / maxFreq
                        let barH  = ratio * (h - Tokens.barMarginTop)
                        let x     = pad + i * (barW + gap)
                        let y     = h - barH

                        let pulse = Math.abs(Math.sin(gpuFrontend.freqFrame * 0.04 + i * 0.15))
                        let alpha = 0.45 + ratio * 0.55
                        // Ash monochrome bars — Theme.accent body, textPrimary tip
                        let body = Theme.accent
                        let tip  = Theme.textPrimary

                        ctx.fillStyle = Qt.rgba(body.r, body.g, body.b, alpha)
                        ctx.fillRect(x, y, barW, barH)

                        ctx.fillStyle = Qt.rgba(tip.r, tip.g, tip.b, 0.55 + pulse * 0.4)
                        ctx.fillRect(x, y, barW, Tokens.borderXss)
                    }
                }
            }
        }

        RowLayout {
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Tokens.statBoxHeight
                color: Theme.bgElevated
                radius: Tokens.radiusSm
                border.color: Theme.borderIdle
                border.width: Tokens.strokeWidth

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Tokens.spacingXss

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text:               "USAGE"
                        font.family:        Theme.fontDisplay
                        font.pixelSize:     Tokens.fontSizeLabel
                        color:              Theme.textMuted
                        font.letterSpacing: Tokens.spacingXss
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text:           gpuFrontend.usageBoxText
                        font.family:    Theme.fontMono
                        font.pixelSize: Tokens.fontSizeMedium
                        font.bold:      true
                        color:          gpu.gpuUsage > 85 ? Theme.stateCritical
                                        : gpu.gpuUsage > 60 ? Theme.stateWarning
                                        : Theme.accent
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Tokens.statBoxHeight
                color: Theme.bgElevated
                radius: Tokens.radiusSm
                border.color: Theme.borderIdle
                border.width: Tokens.strokeWidth

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Tokens.spacingXss

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "FREQUENCY"
                        font.family: Theme.fontDisplay
                        font.pixelSize: Tokens.fontSizeLabel
                        color: Theme.textMuted
                        font.letterSpacing: Tokens.spacingXss
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: gpuFrontend.freqBoxText
                        font.family: Theme.fontMono
                        font.pixelSize: Tokens.fontSizeMedium
                        font.bold: true
                        color: gpu.gpuFreq > 1000 ? Theme.stateCritical
                                : gpu.gpuFreq > 600 ? Theme.stateWarning
                                : Theme.accent
                    }
                }
            }
        }

        Rectangle {
            id:                     nvtopBtn
            Layout.fillWidth:       true
            Layout.preferredHeight: Tokens.actionBtnHeight
            radius:                 Tokens.radiusLg
            color:                  nvtopHover.containsMouse ? Theme.bgElevated : Theme.bgSurface
            border.color:           nvtopHover.containsMouse ? Theme.accent : Theme.borderIdle
            border.width:           nvtopHover.containsMouse ? Tokens.strokeWidthActive : Tokens.strokeWidth

            Behavior on color {
                ColorAnimation {
                    duration: Tokens.animFast
                }
            }

            Behavior on border.color {
                ColorAnimation {
                    duration: Tokens.animFast
                }
            }

            Text {
                anchors.centerIn:   parent
                text:               "◈  LAUNCH NVTOP"
                font.family:        Theme.fontDisplay
                font.pixelSize:     Tokens.fontSizeLabel
                font.letterSpacing: Tokens.spacingXss
                color:              nvtopHover.containsMouse ? Theme.accent : Theme.textMuted
                Behavior on color   { ColorAnimation { duration: Tokens.animFast } }
            }

            MouseArea {
                id:                 nvtopHover
                anchors.fill:       parent
                hoverEnabled:       true
                onClicked:          gpuFrontend.launchNvtop()
                cursorShape:        Qt.PointingHandCursor
            }
        }
    }
}
