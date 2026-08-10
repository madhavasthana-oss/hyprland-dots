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
    // Fully opaque strip
    readonly property real barOpacity: 1.0
    readonly property int barHeight: Tokens.bar.height
    readonly property bool alertActive: centerZone.alertActive

    // Strip only — parent sizes us
    height: barHeight
    implicitHeight: barHeight

    // Background
    Rectangle {
        id: barBg
        anchors.fill: parent
        color: root.barColor
        border.width: 0

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

    // Three-zone content — no zone dividers, no edge stroke / glow
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

        CenterBar {
            id: centerZone
            Layout.fillHeight: true
            Layout.preferredWidth: Tokens.bar.centerMin * 1.4
            Layout.minimumWidth: Tokens.bar.centerMin
            Layout.fillWidth: true
            Layout.horizontalStretchFactor: 2
        }

        // Quick actions sit in the gap between weather and telemetry
        QuickLaunch {
            id: quickLaunch
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: implicitWidth > 0
                ? implicitWidth
                : Math.round(Tokens.icon.medium * 8 + Tokens.spacing.md * 3)
            Layout.minimumWidth: Math.round(Tokens.icon.medium * 6)
            Layout.fillWidth: false
            // Natural width from icon row
            implicitWidth: {
                const hit = Math.max(
                    Tokens.icon.medium + Tokens.spacing.xs,
                    Tokens.bar.height - 4
                )
                // dashboard + 3 console + media + spacings
                return hit * 5 + Tokens.spacing.sm * 2 + Tokens.spacing.xss * 2
            }
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
