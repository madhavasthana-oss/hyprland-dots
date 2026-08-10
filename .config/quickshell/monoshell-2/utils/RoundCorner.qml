// RoundCorner.qml --- concave quarter-circle cutout (screen / panel hug)
// Fills the square corner outside the arc so the free area reads as rounded.
import QtQuick
import QtQuick.Shapes
import ".."

Item {
    id: root

    enum CornerEnum {
        TopLeft,
        TopRight,
        BottomLeft,
        BottomRight
    }

    property int corner: RoundCorner.CornerEnum.TopLeft
    property int implicitSize: Tokens.rounding.screen
    property color color: Theme.bgSurface

    implicitWidth:  implicitSize
    implicitHeight: implicitSize
    width:  implicitSize
    height: implicitSize

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        antialiasing: true

        ShapePath {
            id: shapePath
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: root.color
            pathHints: ShapePath.PathSolid | ShapePath.PathNonIntersecting

            // Outer corner of the square:
            //   TopLeft     → (0, 0)
            //   TopRight    → (size, 0)
            //   BottomLeft  → (0, size)
            //   BottomRight → (size, size)
            startX: {
                switch (root.corner) {
                case RoundCorner.CornerEnum.TopLeft:
                case RoundCorner.CornerEnum.BottomLeft:
                    return 0
                default:
                    return root.implicitSize
                }
            }
            startY: {
                switch (root.corner) {
                case RoundCorner.CornerEnum.TopLeft:
                case RoundCorner.CornerEnum.TopRight:
                    return 0
                default:
                    return root.implicitSize
                }
            }

            PathAngleArc {
                moveToStart: false
                // Arc center is the opposite corner of the square
                centerX: root.implicitSize - shapePath.startX
                centerY: root.implicitSize - shapePath.startY
                radiusX: root.implicitSize
                radiusY: root.implicitSize
                // Sweep a quarter-circle into the free desktop / gap
                startAngle: {
                    switch (root.corner) {
                    case RoundCorner.CornerEnum.TopLeft:     return 180
                    case RoundCorner.CornerEnum.TopRight:    return -90
                    case RoundCorner.CornerEnum.BottomLeft:  return 90
                    case RoundCorner.CornerEnum.BottomRight: return 0
                    default: return 180
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
