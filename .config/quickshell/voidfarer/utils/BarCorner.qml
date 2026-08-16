// ---
//  BarCorner.qml
//  VOIDFARER --- inverted quarter-circle cutout
//  Square minus a quarter disk. Used at bar / screen junctions so the
//  desktop appears to wrap the bar (caelestia / end-4).
// ---

import QtQuick
import QtQuick.Shapes
import ".."

Item {
    id: root

    // "topLeft" | "topRight" | "bottomLeft" | "bottomRight"
    property string corner: "bottomLeft"
    property color color: Theme.bgSurface
    property int implicitSize: Tokens.topBarCorner

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    readonly property bool isRight: corner === "topRight" || corner === "bottomRight"
    readonly property bool isBottom: corner === "bottomLeft" || corner === "bottomRight"

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: shapePath
            strokeWidth: 0
            fillColor: root.color
            pathHints: ShapePath.PathSolid & ShapePath.PathNonIntersecting

            startX: root.isRight ? root.implicitSize : 0
            startY: root.isBottom ? root.implicitSize : 0

            PathAngleArc {
                moveToStart: false
                centerX: root.implicitSize - shapePath.startX
                centerY: root.implicitSize - shapePath.startY
                radiusX: root.implicitSize
                radiusY: root.implicitSize
                startAngle: {
                    switch (root.corner) {
                    case "topLeft":     return 180
                    case "topRight":    return -90
                    case "bottomLeft":  return 90
                    case "bottomRight": return 0
                    default:            return 90
                    }
                }
                sweepAngle: 90
            }
            PathLine {
                x: shapePath.startX
                y: shapePath.startY
            }
        }
    }
}
