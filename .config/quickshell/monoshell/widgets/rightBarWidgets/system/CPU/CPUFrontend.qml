import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Layouts
import QtQuick.Controls
import "../../../.."

Item {
    id: cpuFrontend

    implicitHeight:  Tokens.rightWidth
    implicitWidth:   Tokens.rightWidth 

    CPUBackend { id: cpu }
    property int selectedCore: 0

    function selectCore(i) {
        if (i < 0 || i >= cpu.cores.count)
            return
        selectedCore = i
        if (coreList.currentIndex !== i)
            coreList.currentIndex = i
        coreList.positionViewAtIndex(i, ListView.Contain)
        usageCanvas.requestPaint()
        tempCanvas.requestPaint()
    }

    function launchBtop() {
        btopProc.running = true
    }

    function grabListFocus() {
        coreList.forceActiveFocus()
    }

    Component.onCompleted: {
        if (Globals.activePanel === "cpu")
            grabListFocus()
    }

    Connections {
        target: Globals
        function onActivePanelChanged() {
            if (Globals.activePanel === "cpu")
                Qt.callLater(cpuFrontend.grabListFocus)
        }
    }

    focus: true
    Keys.forwardTo: [coreList]
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            cpuFrontend.launchBtop()
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            cpuFrontend.selectCore(cpuFrontend.selectedCore - 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            cpuFrontend.selectCore(cpuFrontend.selectedCore + 1)
            event.accepted = true
        }
    }

    Timer {
        id: repaintTimer
        interval: 150
        running:  cpu.ready
        repeat:   true
        onTriggered: {
            usageCanvas.requestPaint()
            tempCanvas.requestPaint()
        }
    }
    
    onSelectedCoreChanged: {
        usageCanvas.requestPaint()
        tempCanvas.requestPaint()
    }

    //  MAIN LAYOUT

    ColumnLayout {
        id: mainLayout
        anchors.fill:    parent
        anchors.margins: Tokens.paddingH 
        spacing:         Tokens.spacingMd

        //  BODY --- core list (left) + detail panel (right)

        RowLayout {
            Layout.fillWidth:  true
            Layout.fillHeight: true
            spacing:           Tokens.spacingXs

            //  LEFT --- core list

            Rectangle {
                Layout.preferredWidth: Tokens.listPanelWidth
                Layout.fillHeight:     true
                color:                 Theme.bgSurface
                radius:                Tokens.radiusLg
                border.color:          Theme.borderIdle
                border.width:          Tokens.strokeWidth

                Text { 
                    id: coreListHeader
                    anchors.top:              parent.top
                    anchors.topMargin:        Tokens.spacingXs
                    anchors.horizontalCenter: parent.horizontalCenter
                    text:                     "CORES"
                    font.family:              Theme.fontDisplay
                    font.pixelSize:           Tokens.fontSizeLabel
                    color:                    Theme.textMuted
                    font.letterSpacing:       Tokens.spacingXss
                }

                ListView {
                    id: coreList
                    anchors.top:          coreListHeader.bottom
                    anchors.left:         parent.left
                    anchors.right:        parent.right
                    anchors.bottom:       parent.bottom
                    anchors.topMargin:    Tokens.spacingXs
                    anchors.leftMargin:   Tokens.spacingXs
                    anchors.rightMargin:  Tokens.spacingXs
                    anchors.bottomMargin: Tokens.spacingXs
                    spacing:              Tokens.spacingXss
                    clip:                 true
                    currentIndex:         cpuFrontend.selectedCore
                    focus:                true
                    activeFocusOnTab:     true
                    keyNavigationEnabled: false
                    highlightFollowsCurrentItem: true

                    model: cpu.cores

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            cpuFrontend.launchBtop()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up) {
                            cpuFrontend.selectCore(cpuFrontend.selectedCore - 1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Down) {
                            cpuFrontend.selectCore(cpuFrontend.selectedCore + 1)
                            event.accepted = true
                        }
                    }

                    delegate: Item {
                        width:  coreList.width
                        height: Tokens.actionBtnHeight

                        property int   coreUsage: model.usage === -1 ? 0 : model.usage
                        property bool  isSelected: index === cpuFrontend.selectedCore
                        property color usageColor: coreUsage > 85 ? Theme.stateCritical
                                                 : coreUsage > 60 ? Theme.stateWarning
                                                 : Theme.stateSafe

                        Rectangle {
                            anchors.fill: parent
                            color:        isSelected ? Qt.rgba(1, 0.27, 0, 0.18) : "transparent"
                            radius:       Tokens.radiusSm
                            border.color: isSelected ? Theme.accent : "transparent"
                            border.width: isSelected ? Tokens.strokeWidth : 0
                        }

                        Text {
                            id: coreLabel
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left:           parent.left
                            anchors.leftMargin:     Tokens.spacingXs
                            text:                   "C" + model.idx
                            font.family:            Theme.fontDisplay
                            font.pixelSize:         Tokens.fontSizeSmall
                            color:                  isSelected ? Theme.accent : Theme.textMuted
                        }

                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left:           coreLabel.right
                            anchors.leftMargin:     Tokens.spacingXs
                            anchors.right:          usagePct.left
                            anchors.rightMargin:    Tokens.spacingXs
                            height:                 Tokens.usageBarHeight

                            Rectangle {
                                anchors.fill: parent
                                radius:       Tokens.radiusSm
                                color:        Theme.bgElevated
                                opacity:      Theme.opacityBar
                            }

                            Rectangle {
                                width:  Math.max(Tokens.borderXss, parent.width * (coreUsage / 100))
                                height: parent.height
                                radius: Tokens.radiusSm
                                color:  usageColor
                                Behavior on width { NumberAnimation { duration: Tokens.animFast } }
                            }
                        }

                        Text {
                            id: usagePct
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right:          parent.right
                            anchors.rightMargin:    Tokens.spacingXs
                            text:                   model.usage === -1 ? "--" : model.usage + "%"
                            font.family:            Theme.fontMono
                            font.pixelSize:         Tokens.fontSizeTiny
                            color:                  usageColor
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                cpuFrontend.selectCore(index)
                                coreList.forceActiveFocus()
                            }
                        }
                    }
                }
            }

            //  RIGHT --- detail panel

            ColumnLayout {
                Layout.fillWidth:  true
                Layout.fillHeight: true
                spacing:           Tokens.spacingXs

                // USAGE GRAPH
                ColumnLayout {
                    Layout.fillWidth:  true
                    Layout.fillHeight: true
                    spacing:           Tokens.spacingXs

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
                            property int liveVal: cpu.cores.count > 0
                                ? (cpu.cores.get(cpuFrontend.selectedCore)?.usage ?? -1) : -1
                            text:           liveVal === -1 ? "--%"  : liveVal + "%"
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
                        radius:            Tokens.radiusMd
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
                                let row = cpu.cores.count > 0
                                    ? cpu.cores.get(cpuFrontend.selectedCore) : null
                                let buf = (cpu.history[cpuFrontend.selectedCore]?.usage ?? [])
                                    .filter(v => v !== undefined)

                                ctx.clearRect(0, 0, w, h)

                                ctx.strokeStyle = Theme.borderIdle
                                ctx.lineWidth   = Tokens.strokeWidth / 2
                                ctx.setLineDash([Tokens.spacingXss, Tokens.spacingXs])
                                ctx.globalAlpha = 0.5
                                for (let pct of [0.25, 0.5, 0.75]) {
                                    ctx.beginPath()
                                    ctx.moveTo(0, h * (1 - pct))
                                    ctx.lineTo(w, h * (1 - pct))
                                    ctx.stroke()
                                }
                                ctx.setLineDash([])
                                ctx.globalAlpha = 1

                                ctx.fillStyle = Theme.textDim
                                ctx.font      = "bold " + Tokens.fontSizeTiny + "px " + Theme.fontMono
                                ctx.fillText("100", Tokens.radiusSm, Tokens.radiusXl)
                                ctx.fillText("50",  Tokens.radiusSm, h * 0.5 - Tokens.spacingXss)
                                ctx.fillText("0",   Tokens.radiusSm, h - Tokens.radiusSm)

                                if (buf.length < 2) return

                                let pts = buf.length
                                function xAt(i) { return (i / (pts - 1)) * w }
                                function yAt(v) { return h - (v / 100) * h }

                                let grad = ctx.createLinearGradient(0, 0, 0, h)
                                grad.addColorStop(0,   Qt.rgba(1, 0.27, 0, 0.55))
                                grad.addColorStop(0.6, Qt.rgba(1, 0.27, 0, 0.12))
                                grad.addColorStop(1,   Qt.rgba(1, 0.27, 0, 0.0))

                                ctx.beginPath()
                                ctx.moveTo(xAt(0), h)
                                ctx.lineTo(xAt(0), yAt(buf[0]))
                                for (let i = 1; i < pts; i++) {
                                    let x0 = xAt(i - 1), y0 = yAt(buf[i - 1])
                                    let x1 = xAt(i),     y1 = yAt(buf[i])
                                    let cx  = (x0 + x1) / 2
                                    ctx.bezierCurveTo(cx, y0, cx, y1, x1, y1)
                                }
                                ctx.lineTo(xAt(pts - 1), h)
                                ctx.closePath()
                                ctx.fillStyle = grad
                                ctx.fill()

                                ctx.strokeStyle = Theme.accent
                                ctx.lineWidth   = Tokens.strokeWidthActive
                                ctx.beginPath()
                                ctx.moveTo(xAt(0), yAt(buf[0]))
                                for (let i = 1; i < pts; i++) {
                                    let x0 = xAt(i - 1), y0 = yAt(buf[i - 1])
                                    let x1 = xAt(i),     y1 = yAt(buf[i])
                                    let cx  = (x0 + x1) / 2
                                    ctx.bezierCurveTo(cx, y0, cx, y1, x1, y1)
                                }
                                ctx.stroke()

                                let lastX = xAt(pts - 1)
                                let lastY = yAt(buf[pts - 1])
                                ctx.beginPath()
                                ctx.arc(lastX, lastY, Tokens.radiusSm, 0, Math.PI * 2)
                                ctx.fillStyle = Theme.accent
                                ctx.fill()
                            }
                        }
                    }
                }

                // TEMP GRAPH
                ColumnLayout {
                    Layout.fillWidth:  true
                    Layout.fillHeight: true
                    spacing:           Tokens.spacingXss

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text:               "TEMP"
                            font.family:        Theme.fontDisplay
                            font.pixelSize:     Tokens.fontSizeLabel
                            color:              Theme.textMuted
                            font.letterSpacing: Tokens.spacingXss
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            id: liveTempLabel
                            property int liveVal: cpu.cores.count > 0
                                ? (cpu.cores.get(cpuFrontend.selectedCore)?.temp ?? -1) : -1
                            text:           liveVal === -1 ? "--°C" : liveVal + "°C"
                            font.family:    Theme.fontMono
                            font.pixelSize: Tokens.fontSizeSmall
                            color:          liveVal > 85 ? Theme.stateCritical
                                          : liveVal > 70 ? Theme.stateWarning
                                          : Theme.accentWarm
                        }
                    }

                    Rectangle {
                        Layout.fillWidth:  true
                        Layout.fillHeight: true
                        color:             Theme.bgElevated
                        radius:            Tokens.radiusXl
                        clip:              true
                        border.color:      Theme.borderIdle
                        border.width:      Tokens.strokeWidth

                        Canvas {
                            id: tempCanvas
                            anchors.fill: parent

                            onPaint: {
                                let ctx  = getContext("2d")
                                let w    = width
                                let h    = height
                                let row  = cpu.cores.count > 0
                                    ? cpu.cores.get(cpuFrontend.selectedCore) : null
                                let buf = (cpu.history[cpuFrontend.selectedCore]?.temp ?? [])
                                    .filter(v => v !== undefined)   
                                let tMin = 20
                                let tMax = 100

                                ctx.clearRect(0, 0, w, h)

                                ctx.strokeStyle = Theme.borderIdle
                                ctx.lineWidth   = Tokens.strokeWidth / 2
                                ctx.setLineDash([Tokens.spacingXss, Tokens.spacingXs])
                                ctx.globalAlpha = 0.5
                                for (let t of [50, 75]) {
                                    let gy = h - ((t - tMin) / (tMax - tMin)) * h
                                    ctx.beginPath()
                                    ctx.moveTo(0, gy)
                                    ctx.lineTo(w, gy)
                                    ctx.stroke()
                                }
                                ctx.setLineDash([])
                                ctx.globalAlpha = 1.0

                                ctx.fillStyle = Theme.textDim
                                ctx.font      = "bold " + Tokens.fontSizeTiny + "px " + Theme.fontMono
                                ctx.fillText(tMax + "°", Tokens.radiusSm, Tokens.radiusXl)
                                ctx.fillText("75°",      Tokens.radiusSm, h - ((75 - tMin) / (tMax - tMin)) * h - Tokens.radiusSm)
                                ctx.fillText(tMin + "°", Tokens.radiusSm, h - Tokens.radiusSm)

                                if (buf.length < 2) return

                                let pts    = buf.length
                                let latest = buf[pts - 1]

                                function xAt(i) { return (i / (pts - 1)) * w }
                                function yAt(v) { return h - ((v - tMin) / (tMax - tMin)) * h }

                                let lineColor = latest > 85 ? Theme.stateCritical
                                             : latest > 70 ? Theme.stateWarning
                                             : Theme.accentWarm

                                let grad = ctx.createLinearGradient(0, 0, 0, h)
                                if (latest > 85) {
                                    grad.addColorStop(0, Qt.rgba(0.8,  0.13, 0,   0.55))
                                    grad.addColorStop(1, Qt.rgba(0.8,  0.13, 0,   0.0))
                                } else if (latest > 70) {
                                    grad.addColorStop(0, Qt.rgba(1.0,  0.79, 0.5, 0.5))
                                    grad.addColorStop(1, Qt.rgba(1.0,  0.79, 0.5, 0.0))
                                } else {
                                    grad.addColorStop(0, Qt.rgba(1.0,  0.79, 0.5, 0.4))
                                    grad.addColorStop(1, Qt.rgba(1.0,  0.79, 0.5, 0.0))
                                }

                                ctx.beginPath()
                                ctx.moveTo(xAt(0), h)
                                ctx.lineTo(xAt(0), yAt(buf[0]))
                                for (let i = 1; i < pts; i++) {
                                    let x0 = xAt(i - 1), y0 = yAt(buf[i - 1])
                                    let x1 = xAt(i),     y1 = yAt(buf[i])
                                    let cx  = (x0 + x1) / 2
                                    ctx.bezierCurveTo(cx, y0, cx, y1, x1, y1)
                                }
                                ctx.lineTo(xAt(pts - 1), h)
                                ctx.closePath()
                                ctx.fillStyle = grad
                                ctx.fill()

                                ctx.strokeStyle = lineColor
                                ctx.lineWidth   = Tokens.strokeWidthActive
                                ctx.beginPath()
                                ctx.moveTo(xAt(0), yAt(buf[0]))
                                for (let i = 1; i < pts; i++) {
                                    let x0 = xAt(i - 1), y0 = yAt(buf[i - 1])
                                    let x1 = xAt(i),     y1 = yAt(buf[i])
                                    let cx  = (x0 + x1) / 2
                                    ctx.bezierCurveTo(cx, y0, cx, y1, x1, y1)
                                }
                                ctx.stroke()

                                ctx.beginPath()
                                ctx.arc(xAt(pts - 1), yAt(latest), Tokens.radiusSm, 0, Math.PI * 2)
                                ctx.fillStyle = lineColor
                                ctx.fill()
                            }
                        }
                    }
                }

                // STATS ROW
                RowLayout {
                    Layout.fillWidth:       true
                    Layout.preferredHeight: Tokens.statBoxHeight
                    spacing:                Tokens.spacingMd

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight:           Tokens.statBoxHeight
                        color:            Theme.bgElevated
                        radius:           Tokens.radiusMd
                        border.color:     Theme.borderIdle
                        border.width:     Tokens.strokeWidth

                        property int liveUsage: cpu.cores.count > 0
                            ? (cpu.cores.get(cpuFrontend.selectedCore)?.usage ?? -1) : -1

                        Column {
                            anchors.centerIn: parent 
                            spacing:          Tokens.spacingXss

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text:               "USAGE"
                                font.family:        Theme.fontDisplay
                                font.pixelSize:     Tokens.fontSizeLabel
                                color:              Theme.textMuted
                                font.letterSpacing: Tokens.spacingXss
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text:           parent.parent.liveUsage === -1 ? "--%"
                                                    : parent.parent.liveUsage + "%"
                                font.family:    Theme.fontMono
                                font.pixelSize: Tokens.fontSizeMedium
                                font.bold:      true
                                color:          parent.parent.liveUsage > 85 ? Theme.stateCritical
                                              : parent.parent.liveUsage > 60 ? Theme.stateWarning
                                              : Theme.accent
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height:           Tokens.statBoxHeight
                        color:            Theme.bgElevated
                        radius:           Tokens.radiusLg
                        border.color:     Theme.borderIdle

                        property int liveTemp: cpu.cores.count > 0
                            ? (cpu.cores.get(cpuFrontend.selectedCore)?.temp ?? -1) : -1

                        Column {
                            anchors.centerIn: parent

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text:               "TEMP"
                                font.family:        Theme.fontDisplay
                                font.pixelSize:     Tokens.fontSizeLabel
                                color:              Theme.textMuted
                                font.letterSpacing: Tokens.spacingXss
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text:           parent.parent.liveTemp === -1 ? "--°C"
                                                    : parent.parent.liveTemp + "°C"
                                font.family:    Theme.fontMono
                                font.pixelSize: Tokens.fontSizeMedium
                                font.bold:      true
                                color:          parent.parent.liveTemp > 85 ? Theme.stateCritical
                                              : parent.parent.liveTemp > 70 ? Theme.stateWarning
                                              : Theme.accentWarm
                            }
                        }
                    }
                }
            }
        }

        //  LAUNCH BTOP BUTTON
        Text {
            Layout.fillWidth: true
            text: "ARROWS cores * ENTER btop * 1-3 / LEFT-RIGHT tabs"
            font.family: Theme.fontMono
            font.pixelSize: Tokens.fontSizeTiny
            color: Theme.textDim
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            id: btopBtn
            Layout.fillWidth:       true
            Layout.preferredHeight: Tokens.actionBtnHeight
            radius:                 Tokens.radiusLg
            color:                  btopHover.containsMouse ? Theme.bgElevated : Theme.bgSurface
            border.color:           btopHover.containsMouse ? Theme.accent : Theme.borderIdle
            border.width:           btopHover.containsMouse ? Tokens.strokeWidthActive : Tokens.strokeWidth

            Behavior on color        { ColorAnimation { duration: Tokens.animFast } }
            Behavior on border.color { ColorAnimation { duration: Tokens.animFast } }

            Text {
                anchors.centerIn:   parent
                text:               "◈  LAUNCH BTOP"
                font.family:        Theme.fontDisplay
                font.pixelSize:     Tokens.fontSizeLabel
                font.letterSpacing: Tokens.spacingXss
                color:              btopHover.containsMouse ? Theme.accent : Theme.textMuted
                Behavior on color   { ColorAnimation { duration: Tokens.animFast } }
            }

            MouseArea {
                id:           btopHover
                anchors.fill: parent
                hoverEnabled: true
                onClicked:    cpuFrontend.launchBtop()
                cursorShape:  Qt.PointingHandCursor
            }
        }
    }

    Process {
        id:      btopProc
        command: ["ghostty", "-e", "btop", "--force-utf"]
    }
}
