// ---
//  LeftTrapezoid.qml
//  MONOSHELL --- Command Throne
//  Semi 45° trapezoid. angleOffset == barHeight always.
//  Wider at top on one side, pinched at bottom. Parallel seam edges.
// ---

import QtQuick 2.15
import QtQuick.Shapes 1.15
import ".."
Item {
    id: root

    // ---
    //  PROPERTIES
    // ---

    property real barWidth:    Tokens.centerExpandedWidth
    property real barHeight:   Tokens.edgeToggleHeight
    property real inset: Tokens.barInset

    // True 45° --- offset equals height exactly
    // Do not override this unless you want a different angle
    property real angleOffset: barHeight

    property real fillOpacity:  Theme.opacityBar
    property color fillColor:   Theme.bgSurface
    property color strokeColor: Theme.accent
    property real strokeWidth:  Tokens.strokeWidthActive

    property bool hovered:     false
    property bool alertActive: false

    width:  barWidth
    height: barHeight

    Shape {
        id: trapShape
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            // --- FILL (this is what makes the trapezoid filled) ---
            fillColor: Qt.rgba(
                root.fillColor.r,
                root.fillColor.g,
                root.fillColor.b,
                root.fillOpacity
            )

            // --- STROKE ---
            strokeColor: root.alertActive
                             ? Theme.stateCritical
                             : root.hovered
                                 ? Theme.accentWarm
                                 : root.strokeColor
            strokeWidth: root.hovered
                             ? Tokens.borderXss
                             : root.strokeWidth

            Behavior on strokeColor {
                ColorAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
            }
            Behavior on strokeWidth {
                NumberAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
            }
            
			startX: 0
			startY: 0
			
			PathLine { x: root.barWidth - root.angleOffset; y: 0              }
			PathLine { x: root.barWidth;                    y: root.barHeight }
			PathLine { x: 0;                                y: root.barHeight }
			PathLine { x: 0;                                y: 0              }

        }
    }

    // ---
    //  INNER EMBER GLOW
    //  Inset 6px parallel to outer stroke.
    //  Gives the bar a heated-edge quality.
    //  Fades out when alert is active.
    // ---

    // Shape {
    //     id: innerGlow
    //     anchors.fill: parent
    //     opacity: root.alertActive ? 0.0 : 0.30
    //     layer.enabled: true
    //     layer.samples: 4

    //     Behavior on opacity {
    //         NumberAnimation {
    //             duration: 220
    //             easing.type: Easing.OutCubic
    //         }
    //     }

    //     ShapePath {
    //         fillColor:   "transparent"
    //         strokeColor: "#A3A3A3"
    //         strokeWidth: 0.6

    //         startX: inset
    //         startY: inset
            
    //         PathLine { x: root.barWidth - root.angleOffset - inset; y: inset                  }
    //         PathLine { x: root.barWidth - inset;                    y: root.barHeight - inset }
    //         PathLine { x: inset;                                    y: root.barHeight - inset }
    //         PathLine { x: inset;                                    y: inset                  }
    //     }
    // }

    // ---
    //  ALERT PULSE
    //  Breathes when alertActive is true.
    //  Slow, deliberate --- not a frantic flash.
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

    // Hover only — do not accept buttons or workspace clicks get stolen
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: root.hovered = true
        onExited:  root.hovered = false
    }
}
