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
        Math.round(Tokens.topBarHeight * 0.42)
    )
    readonly property int hit: Math.max(
        iconSide + Tokens.spacingXs,
        Math.min(Tokens.topBarHeight - Tokens.spacingXss * 2, Tokens.listRowHeight + Tokens.spacingXs)
    )
    readonly property int gap: Tokens.spacingXss
    readonly property int btnCount: 6

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
        property color ink: Theme.accent
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
                ? Qt.rgba(btn.ink.r, btn.ink.g, btn.ink.b, 0.18)
                : (btn.hovered ? Theme.bgElevated : "transparent")
            border.width: 0

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
            color: btn.ink
            opacity: btn.active ? 1 : (btn.hovered ? 0.9 : 0.62)

            Behavior on color {
                ColorAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
            }
            Behavior on opacity {
                NumberAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
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
                    Globals.toggleWidget(btn.widgetId, btn)
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
            ink: Theme.inkBlue
        }
        LaunchBtn {
            iconSource: Theme.iconWifi
            widgetId: "wifi"
            ink: Theme.inkCyan
        }
        LaunchBtn {
            iconSource: Theme.iconBluetooth
            widgetId: "bluetooth"
            ink: Theme.inkBlue
        }
        LaunchBtn {
            iconSource: Theme.iconSettings
            widgetId: "settings"
            ink: Theme.inkMagenta
        }
        LaunchBtn {
            iconSource: Theme.iconNotif
            widgetId: "notifications"
            ink: Theme.inkYellow
        }
        LaunchBtn {
            iconSource: Theme.iconMedia
            widgetId: "media"
            ink: Theme.inkMagenta
        }
    }
}
