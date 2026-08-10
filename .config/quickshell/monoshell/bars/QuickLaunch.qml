// QuickLaunch.qml --- compact dashboard · console · media launch strip
import QtQuick
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects
import ".."

Item {
    id: root
    clip: true

    readonly property int iconSide: Math.max(
        Tokens.iconSizeLarge,
        Math.round(Tokens.centerHeight * 0.42)
    )
    readonly property int hit: Math.max(
        iconSide + Tokens.spacingXs,
        Math.min(Tokens.centerHeight - Tokens.spacingXss * 2, Tokens.listRowHeight + Tokens.spacingXs)
    )

    // Fixed footprint so RowLayout cannot push neighbors out of the bar
    implicitWidth: hit * 3 + Tokens.spacingXs * 2
    implicitHeight: hit
    width: implicitWidth
    height: implicitHeight

    function isCenter(panel) {
        return Globals.activeCenterPanel === panel
    }

    component LaunchBtn: Item {
        id: btn
        property string iconSource: ""
        property string tip: ""
        property bool active: false
        property bool hovered: mouse.containsMouse
        signal activated()

        width: root.hit
        height: root.hit

        Rectangle {
            anchors.centerIn: parent
            width: root.iconSide + (btn.hovered || btn.active ? Tokens.spacingXs : 0)
            height: width
            radius: Tokens.radiusSm
            color: btn.active
                ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16)
                : (btn.hovered ? Theme.bgElevated : "transparent")
            border.width: btn.active ? Tokens.strokeWidth : 0
            border.color: btn.active
                ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.45)
                : "transparent"

            Behavior on color {
                ColorAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
            }
            Behavior on width {
                NumberAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
            }
        }

        Image {
            id: glyph
            anchors.centerIn: parent
            width: root.iconSide
            height: root.iconSide
            source: btn.iconSource
            sourceSize: Qt.size(width * 2, height * 2)
            fillMode: Image.PreserveAspectFit
            smooth: true
            visible: false
            asynchronous: true
        }

        ColorOverlay {
            anchors.fill: glyph
            source: glyph
            color: btn.active
                ? Theme.accent
                : (btn.hovered ? Theme.textPrimary : Theme.textMuted)

            Behavior on color {
                ColorAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            // Consume so the bar-wide toggle does not also fire
            onClicked: (mouse) => {
                btn.activated()
                mouse.accepted = true
            }
            ToolTip.visible: containsMouse && btn.tip.length > 0
            ToolTip.delay: 280
            ToolTip.text: btn.tip
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: Tokens.spacingXs

        LaunchBtn {
            iconSource: Theme.iconDashboard
            tip: "Dashboard"
            active: root.isCenter("dashboard")
            onActivated: Globals.toggleCenterPanel("dashboard")
        }
        LaunchBtn {
            iconSource: Theme.iconConsole
            tip: "Console"
            active: root.isCenter("console")
            onActivated: Globals.toggleCenterPanel("console")
        }
        LaunchBtn {
            iconSource: Theme.iconMedia
            tip: "Media"
            active: root.isCenter("media")
            onActivated: Globals.toggleCenterPanel("media")
        }
    }
}
