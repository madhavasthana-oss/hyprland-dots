// ---
//  SideRect.qml
//  Rounded rectangle bar chrome for left / right bars.
// ---

import QtQuick 2.15
import ".."

Item {
    id: root

    // ---
    //  PROPERTIES
    // ---

    property real barWidth:  Tokens.leftWidth
    property real barHeight: Tokens.leftHeight
    property real radius:    Tokens.radiusXl

    property real fillOpacity:  Theme.opacityBar
    property color fillColor:   Theme.bgSurface
    property color strokeColor: Theme.accent
    property real strokeWidth:  Tokens.strokeWidthActive

    property bool hovered:     false
    property bool alertActive: false

    width:  barWidth
    height: barHeight

    // ---
    //  ROUNDED RECT
    // ---

    Rectangle {
        id: rectShape
        anchors.fill: parent
        radius:       root.radius

        antialiasing: true
        color: Qt.rgba(
            root.fillColor.r,
            root.fillColor.g,
            root.fillColor.b,
            root.fillOpacity
        )

        border.color: root.alertActive
                          ? Theme.stateCritical
                          : root.hovered
                              ? Theme.accentWarm
                              : root.strokeColor
        border.width: root.strokeWidth

        Behavior on border.color {
            ColorAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
        }
    }

    // ---
    //  ALERT PULSE
    // ---

    SequentialAnimation {
        id: alertPulse
        running: root.alertActive
        loops:   Animation.Infinite

        NumberAnimation {
            target:   rectShape
            property: "opacity"
            from:     1.0
            to:       0.4
            duration: Tokens.animFadeDelay
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target:   rectShape
            property: "opacity"
            from:     0.4
            to:       1.0
            duration: Tokens.animFadeDelay
            easing.type: Easing.InCubic
        }
    }

    onAlertActiveChanged: {
        if (!alertActive)
            rectShape.opacity = 1.0
    }

    // ---
    //  HOVER DETECTION
    //  Hover only — do not accept buttons or workspace clicks get stolen
    // ---

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: root.hovered = true
        onExited:  root.hovered = false
    }
}
