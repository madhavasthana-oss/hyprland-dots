// ---
//  RightTrapezoid.qml
//  MONOSHELL --- Oracle
//  Semi 45° trapezoid. Flat right, angled left.
//  Mirror of LeftTrapezoid.
// ---

import QtQuick 2.15
import QtQuick.Shapes 2.15
import ".."

Item {
    id: root

    // ---
    //  PROPERTIES
    // ---

    property real barWidth:    Tokens.centerExpandedWidth
    property real barHeight:   Tokens.edgeToggleHeight
    property real angleOffset: barHeight

    property real fillOpacity:  Theme.opacityBar
    property color fillColor:   Theme.bgSurface
    property color strokeColor: Theme.accent
    property real strokeWidth:  Tokens.strokeWidthActive

    property bool hovered:     false
    property bool alertActive: false

    width:  barWidth
    height: barHeight

    // ---
    //  TRAPEZOID SHAPE
    //
    //  /---]
    //
    //  startX: angleOffset   -> top-left pulled RIGHT
    //  bottom-left: x=0      -> kicks OUT left
    //  right edge: flat
    // ---

    Shape {
        id: trapShape
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            fillColor: Qt.rgba(
                root.fillColor.r,
                root.fillColor.g,
                root.fillColor.b,
                root.fillOpacity
            )

            strokeColor: root.alertActive
                             ? Theme.stateCritical
                             : root.hovered
                                 ? Theme.accentWarm
                                 : root.strokeColor
            strokeWidth: root.hovered ? Tokens.borderXss : root.strokeWidth

            Behavior on strokeColor {
                ColorAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
            }
            Behavior on strokeWidth {
                NumberAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
            }

            startX: root.angleOffset
            startY: 0

            PathLine { x: root.barWidth;       y: 0              }
            PathLine { x: root.barWidth;       y: root.barHeight }
            PathLine { x: 0;                   y: root.barHeight }
            PathLine { x: root.angleOffset;    y: 0              }
        }
    }

    // ---
    //  INNER EMBER GLOW
    //  inset referenced as parent.inset inside PathLine children
    // ---

    // Shape {
    //     id: innerGlow
    //     anchors.fill: parent
    //     opacity: root.alertActive ? 0.0 : 0.30
    //     layer.enabled: true
    //     layer.samples: 4

    //     Behavior on opacity {
    //         NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    //     }

    //     ShapePath {
    //         fillColor:   "transparent"
    //         strokeColor: "#A3A3A3"
    //         strokeWidth: 0.6

    //         property real inset: Globals.barInset

    //         startX: root.angleOffset + parent.inset
    //         startY: parent.inset

    //         PathLine { x: root.barWidth - parent.inset; y: parent.inset                  }
    //         PathLine { x: root.barWidth - parent.inset; y: root.barHeight - parent.inset }
    //         PathLine { x: parent.inset;                 y: root.barHeight - parent.inset }
    //         PathLine { x: root.angleOffset + parent.inset; y: parent.inset              }
    //     }
    // }

    // ---
    //  ALERT PULSE
    // ---

    SequentialAnimation {
        id: alertPulse
        running: root.alertActive
        loops:   Animation.Infinite

        NumberAnimation {
            target:   trapShape
            property: "opacity"
            from:     1.0
            to:       0.4
            duration: Tokens.animFadeDelay
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target:   trapShape
            property: "opacity"
            from:     0.4
            to:       1.0
            duration: Tokens.animFadeDelay
            easing.type: Easing.InCubic
        }
    }

    onAlertActiveChanged: {
        if (!alertActive) trapShape.opacity = 1.0
    }

    // ---
    //  HOVER DETECTION
    // ---

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited:  root.hovered = false
    }
}