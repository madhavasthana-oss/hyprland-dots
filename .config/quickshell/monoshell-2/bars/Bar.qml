// Bar.qml --- slim full-width top strip only (height = Tokens.bar.height)
// Dropdowns / screen corners live in shell.qml (same PanelWindow).
import Quickshell
import QtQuick
import QtQuick.Layouts 1.15
import "../utils"
import ".."

Item {
    id: root

    readonly property color barColor: Theme.bgSurface
    readonly property real barOpacity: Theme.opacityBar
    readonly property int barHeight: Tokens.bar.height
    readonly property bool alertActive: centerZone.alertActive

    // Strip only — parent sizes us
    height: barHeight
    implicitHeight: barHeight

    // Background
    Rectangle {
        id: barBg
        anchors.fill: parent
        color: Qt.rgba(
            root.barColor.r,
            root.barColor.g,
            root.barColor.b,
            root.barOpacity
        )

        SequentialAnimation {
            running: root.alertActive
            loops: Animation.Infinite
            NumberAnimation {
                target: barBg; property: "opacity"
                from: 1.0; to: 0.55
                duration: Tokens.anim.fadeDelay
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: barBg; property: "opacity"
                from: 0.55; to: 1.0
                duration: Tokens.anim.fadeDelay
                easing.type: Easing.InCubic
            }
        }
    }

    Connections {
        target: root
        function onAlertActiveChanged() {
            if (!root.alertActive)
                barBg.opacity = 1.0
        }
    }

    // Accent hairline
    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: Math.max(1, Math.round(Tokens.stroke.active))
        z: 3
        color: root.alertActive ? Theme.stateCritical : Theme.accent
        opacity: root.alertActive ? 1.0 : 0.85

        Behavior on color {
            ColorAnimation { duration: Tokens.anim.fast; easing.type: Easing.OutCubic }
        }
    }

    // Soft multi-layer glow under the strip (paints into parent below us)
    Item {
        id: glowStack
        anchors {
            left: parent.left
            right: parent.right
            top: parent.bottom
        }
        height: Tokens.bar.glowHeight
        z: 1
        clip: false

        Repeater {
            model: 4
            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                height: Tokens.bar.glowHeight * (1.0 - index * 0.18)
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: Qt.rgba(
                            Theme.accent.r, Theme.accent.g, Theme.accent.b,
                            Tokens.bar.glowOpacity * (0.45 - index * 0.1)
                        )
                    }
                    GradientStop {
                        position: 1.0
                        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0)
                    }
                }
            }
        }
    }

    // Three-zone content
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin:  Tokens.bar.padH
        anchors.rightMargin: Tokens.bar.padH
        spacing: Tokens.bar.sectionGap

        LeftBar {
            id: leftZone
            Layout.fillHeight: true
            Layout.preferredWidth: Tokens.bar.leftPreferred
            Layout.minimumWidth: Tokens.bar.leftPreferred * 0.5
            Layout.maximumWidth: Tokens.bar.leftPreferred * 1.2
            Layout.fillWidth: true
            Layout.horizontalStretchFactor: 3
        }

        Rectangle {
            Layout.preferredWidth: Math.max(1, Math.round(Tokens.stroke.base))
            Layout.preferredHeight: parent.height * 0.5
            Layout.alignment: Qt.AlignVCenter
            color: Theme.borderIdle
            opacity: 0.45
        }

        CenterBar {
            id: centerZone
            Layout.fillHeight: true
            Layout.preferredWidth: Tokens.bar.centerMin * 1.4
            Layout.minimumWidth: Tokens.bar.centerMin
            Layout.fillWidth: true
            Layout.horizontalStretchFactor: 2
        }

        Rectangle {
            Layout.preferredWidth: Math.max(1, Math.round(Tokens.stroke.base))
            Layout.preferredHeight: parent.height * 0.5
            Layout.alignment: Qt.AlignVCenter
            color: Theme.borderIdle
            opacity: 0.45
        }

        RightBar {
            id: rightZone
            Layout.fillHeight: true
            Layout.preferredWidth: Tokens.bar.rightPreferred
            Layout.minimumWidth: Tokens.bar.rightPreferred * 0.5
            Layout.maximumWidth: Tokens.bar.rightPreferred * 1.2
            Layout.fillWidth: true
            Layout.horizontalStretchFactor: 3
        }
    }
}
