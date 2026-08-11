// QuickLaunch.qml --- dashboard · wifi · bluetooth · settings · notifs · media
import QtQuick
import QtQuick.Layouts 1.15
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
    readonly property int gap: Tokens.spacingXss
    readonly property int btnCount: 6

    // Fixed footprint so RowLayout cannot push neighbors out of the bar
    implicitWidth: hit * btnCount + gap * (btnCount - 1)
    implicitHeight: hit
    width: implicitWidth
    height: implicitHeight

    function isCenter(panel) {
        return Globals.activeCenterPanel === panel
    }

    function isConsolePage(page) {
        return Globals.activeCenterPanel === "console" && Globals.activeEdgePanel === page
    }

    component LaunchBtn: Item {
        id: btn
        property string iconSource: ""
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
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: root.gap

        // 1. Dashboard
        LaunchBtn {
            iconSource: Theme.iconDashboard
            active: root.isCenter("dashboard")
            onActivated: Globals.toggleCenterPanel("dashboard")
        }

        // 2–5. Console pages
        LaunchBtn {
            iconSource: Theme.iconWifi
            active: root.isConsolePage("wifi")
            onActivated: Globals.toggleEdgePanel("wifi")
        }
        LaunchBtn {
            iconSource: Theme.iconBluetooth
            active: root.isConsolePage("bluetooth")
            onActivated: Globals.toggleEdgePanel("bluetooth")
        }
        LaunchBtn {
            iconSource: Theme.iconSettings
            active: root.isConsolePage("settings")
            onActivated: Globals.toggleEdgePanel("settings")
        }
        LaunchBtn {
            iconSource: Theme.iconNotif
            active: root.isConsolePage("notifications")
            onActivated: Globals.toggleEdgePanel("notifications")
        }

        // 6. Media
        LaunchBtn {
            iconSource: Theme.iconMedia
            active: root.isCenter("media")
            onActivated: Globals.toggleCenterPanel("media")
        }
    }
}
