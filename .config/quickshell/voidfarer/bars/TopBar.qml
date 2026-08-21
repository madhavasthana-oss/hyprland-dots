// TopBar.qml --- full-width cutout bar
// Three fillWidth zones; Item { Layout.fillWidth } spacers share leftover room.
//
//   [ workspaces ]  title…     [ clock · greeting ]     [ launch · rings · notif · power ]
//
import QtQuick
import QtQuick.Layouts 1.15
import "../utils"
import ".."
import "../widgets/topBarWidgets"

Item {
    id: root

    readonly property color barColor: Theme.bgSurface
    readonly property int barHeight: Tokens.topBarHeight
    readonly property int cornerSize: Tokens.topBarCorner

    width: parent ? parent.width : Tokens.topBarWidth
    height: parent ? parent.height : (barHeight + cornerSize)

    BatteryWatch {}

    Rectangle {
        id: body
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.barHeight
        color: root.barColor

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: Math.max(1, Math.round(Tokens.strokeWidth))
            color: Theme.borderIdle
            opacity: 0.45
        }
    }

    BarCorner {
        anchors.left: parent.left
        anchors.top: body.bottom
        corner: "topLeft"
        color: root.barColor
        implicitSize: root.cornerSize
    }

    BarCorner {
        anchors.right: parent.right
        anchors.top: body.bottom
        corner: "topRight"
        color: root.barColor
        implicitSize: root.cornerSize
    }

    RowLayout {
        id: hud
        anchors.fill: body
        anchors.leftMargin:  Tokens.paddingH + Tokens.spacingSm
        anchors.rightMargin: Tokens.paddingH + Tokens.spacingSm
        spacing: Tokens.spacingSm
        clip: true

        // --- LEFT: workspaces + eliding title ---
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 0
            Layout.preferredWidth: 3
            spacing: Tokens.spacingSm

            Workspaces {
                Layout.fillWidth: false
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignVCenter
            }

            WindowTitle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 0
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // --- CENTER: clock + greeting / weather ---
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 0
            Layout.preferredWidth: 2
            spacing: Tokens.spacingSm

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 0
            }

            ClockHud {
                Layout.fillWidth: false
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignVCenter
            }

            MetaHud {
                Layout.fillWidth: false
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignVCenter
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 0
            }
        }

        // --- RIGHT: console, then CPU/GPU rings, notif, power ---
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 0
            Layout.preferredWidth: 2
            spacing: Tokens.spacingSm

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 0
            }

            QuickLaunch {
                Layout.fillWidth: false
                Layout.fillHeight: false
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: implicitWidth
                Layout.preferredHeight: implicitHeight
            }

            Telemetry {
                Layout.fillWidth: false
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignVCenter
            }

            NotifBadge {
                Layout.fillWidth: false
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignVCenter
            }

            PowerButton {
                Layout.fillWidth: false
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
