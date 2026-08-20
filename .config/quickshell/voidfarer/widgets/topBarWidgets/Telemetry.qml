// Telemetry.qml --- minimal caelestia-style CPU / GPU rings
import QtQuick
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Shapes
import "../.."
import "../rightBarWidgets/system/CPU"
import "../rightBarWidgets/system/GPU"

Item {
    id: root
    implicitWidth: pill.implicitWidth
    implicitHeight: Tokens.topBarHeight

    readonly property int ringSize: Math.round(
        Math.max(16, Tokens.topBarHeight * 0.62)
    )
    readonly property real ringStroke: Math.max(1.5, Tokens.strokeWidth * 1.6)

    function blend(color1, color2, alpha) {
        color1 = color1.toString()
        color2 = color2.toString()
        const r1 = parseInt(color1.slice(1, 3), 16)
        const g1 = parseInt(color1.slice(3, 5), 16)
        const b1 = parseInt(color1.slice(5, 7), 16)
        const r2 = parseInt(color2.slice(1, 3), 16)
        const g2 = parseInt(color2.slice(3, 5), 16)
        const b2 = parseInt(color2.slice(5, 7), 16)
        const a = Math.max(0, Math.min(1, alpha))
        return "#"
            + Math.round((1 - a) * r1 + a * r2).toString(16).padStart(2, "0")
            + Math.round((1 - a) * g1 + a * g2).toString(16).padStart(2, "0")
            + Math.round((1 - a) * b1 + a * b2).toString(16).padStart(2, "0")
    }

    function usageColor(pct) {
        if (pct < 0)
            return Theme.textDim
        return root.blend(Theme.stateSafe, Theme.stateCritical, Math.max(0, pct) / 100)
    }

    function togglePanel(panel) {
        if (Globals.activePanel === panel) {
            Globals.lastPanel = panel
            Globals.activePanel = ""
            return
        }
        Globals.lastPanel = panel
        Globals.activePanel = panel
    }

    CPUBackend {
        id: cpuStat
        visible: false

        readonly property int averageUsage: {
            if (!ready || cores.count === 0)
                return -1
            let sum = 0
            let counted = 0
            for (let i = 0; i < cores.count; i++) {
                const u = cores.get(i).usage
                if (u !== -1 && u !== undefined) {
                    sum += u
                    counted++
                }
            }
            return counted > 0 ? Math.round(sum / counted) : -1
        }
    }

    GPUBackend {
        id: gpuStat
        visible: false
    }

    component UsageRing: Item {
        id: ring
        property real value: -1
        property string glyph: ""
        property color ink: Theme.accent
        property string tip: ""
        signal activated()

        implicitWidth: root.ringSize
        implicitHeight: root.ringSize

        readonly property real cx: width / 2
        readonly property real cy: height / 2
        readonly property real r: Math.min(width, height) / 2 - root.ringStroke
        readonly property real sweep: Math.max(0, Math.min(100, value)) * 3.6
        readonly property bool ready: value >= 0

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: root.ringStroke
                strokeColor: Theme.bgElevated
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: ring.cx
                    centerY: ring.cy
                    radiusX: ring.r
                    radiusY: ring.r
                    startAngle: -90
                    sweepAngle: 360
                }
            }
        }

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            opacity: ring.ready ? 1 : 0.25
            ShapePath {
                strokeWidth: root.ringStroke
                strokeColor: ring.ink
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: ring.cx
                    centerY: ring.cy
                    radiusX: ring.r
                    radiusY: ring.r
                    startAngle: -90
                    sweepAngle: ring.ready ? ring.sweep : 0
                }
            }

            Behavior on opacity {
                NumberAnimation { duration: Tokens.animFadeIn; easing.type: Easing.OutCubic }
            }
        }

        Text {
            anchors.centerIn: parent
            text: ring.glyph
            font.family: Theme.fontDisplay
            font.pixelSize: Tokens.fontSizeTiny
            color: ring.ready ? ring.ink : Theme.textDim
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            ToolTip.visible: containsMouse
            ToolTip.delay: 250
            ToolTip.text: ring.tip
            onClicked: ring.activated()
        }
    }

    Rectangle {
        id: pill
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: rings.implicitWidth + Tokens.paddingH * 2
        implicitHeight: Math.min(parent.height - 2, root.ringSize + Tokens.spacingXs)
        radius: Tokens.radiusSm
        color: Qt.rgba(Theme.bgElevated.r, Theme.bgElevated.g, Theme.bgElevated.b, 0.45)
        border.width: Tokens.strokeWidth
        border.color: (Globals.activePanel === "cpu" || Globals.activePanel === "gpu")
            ? Theme.borderActive
            : Theme.borderIdle

        RowLayout {
            id: rings
            anchors.centerIn: parent
            spacing: Tokens.spacingSm

            UsageRing {
                glyph: "C"
                value: cpuStat.averageUsage
                ink: root.usageColor(cpuStat.averageUsage)
                tip: cpuStat.averageUsage >= 0
                    ? ("CPU  " + cpuStat.averageUsage + "%")
                    : "CPU  —"
                onActivated: root.togglePanel("cpu")
            }

            Text {
                Layout.fillWidth: false
                text: cpuStat.averageUsage >= 0 ? (cpuStat.averageUsage + "%") : "—"
                font.family: Theme.fontMono
                font.pixelSize: Tokens.fontSizeTiny
                color: Theme.textSecondary
            }

            UsageRing {
                glyph: "G"
                value: gpuStat.gpuUsage
                ink: root.usageColor(gpuStat.gpuUsage)
                tip: gpuStat.gpuUsage >= 0
                    ? ("GPU  " + gpuStat.gpuUsage + "%")
                    : "GPU  —"
                onActivated: root.togglePanel("gpu")
            }

            Text {
                Layout.fillWidth: false
                text: gpuStat.gpuUsage >= 0 ? (gpuStat.gpuUsage + "%") : "—"
                font.family: Theme.fontMono
                font.pixelSize: Tokens.fontSizeTiny
                color: Theme.textSecondary
            }
        }
    }
}
