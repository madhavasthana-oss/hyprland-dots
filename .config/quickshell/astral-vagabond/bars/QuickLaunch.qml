// QuickLaunch.qml --- dashboard · console · wifi · bluetooth · settings · notifs · media
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
    readonly property int btnCount: 7

    // Fixed footprint so RowLayout cannot push neighbors out of the bar
    implicitWidth: hit * btnCount + gap * (btnCount - 1)
    implicitHeight: hit
    width: implicitWidth
    height: implicitHeight

    function isOpen(id) {
        return Globals.activeWidget === id
    }

    component LaunchBtn: Item {
        id: btn
        property string iconSource: ""
        property string widgetId: ""
        property bool active: root.isOpen(widgetId)
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
                if (btn.widgetId.length)
                    Globals.toggleWidget(btn.widgetId)
                btn.activated()
                mouse.accepted = true
            }
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: root.gap

        LaunchBtn {
            iconSource: Theme.iconDashboard
            widgetId: "dashboard"
        }
        LaunchBtn {
            iconSource: Theme.iconConsole
            widgetId: "console"
        }
        LaunchBtn {
            iconSource: Theme.iconWifi
            widgetId: "wifi"
        }
        LaunchBtn {
            iconSource: Theme.iconBluetooth
            widgetId: "bluetooth"
        }
        LaunchBtn {
            iconSource: Theme.iconSettings
            widgetId: "settings"
        }
        LaunchBtn {
            iconSource: Theme.iconNotif
            widgetId: "notifications"
        }
        LaunchBtn {
            iconSource: Theme.iconMedia
            widgetId: "media"
        }
    }
}
