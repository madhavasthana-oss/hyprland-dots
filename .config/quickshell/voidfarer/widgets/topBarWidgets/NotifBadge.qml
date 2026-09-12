// NotifBadge.qml --- live mako count / DND / silent; opens console notifications
import QtQuick
import QtQuick.Layouts 1.15
import "../.."

Item {
    id: root
    implicitWidth: visible ? badgeChrome.width : 0
    implicitHeight: Tokens.topBarHeight
    visible: Globals.notifCount > 0 || Globals.notifDnd || Globals.notifSilent

    Rectangle {
        id: badgeChrome
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(Tokens.iconSizeLarge + Tokens.spacingXs,
                        badgeLabel.implicitWidth + 2 * Tokens.paddingH)
        height: Math.min(parent.height - 2, Tokens.listRowHeight)
        radius: Tokens.radiusSm
        color: {
            if (Globals.notifDnd)
                return Qt.rgba(Theme.inkRed.r, Theme.inkRed.g, Theme.inkRed.b, 0.18)
            if (badgeMouse.containsMouse)
                return Theme.bgElevated
            if (Globals.notifCount > 0)
                return Qt.rgba(Theme.inkYellow.r, Theme.inkYellow.g, Theme.inkYellow.b, 0.16)
            return Theme.bgSurface
        }
        border.width: 0

        Text {
            id: badgeLabel
            anchors.centerIn: parent
            text: {
                if (Globals.notifDnd)
                    return Globals.notifCount > 0 ? "DND " + Globals.notifCount : "DND"
                if (Globals.notifSilent)
                    return Globals.notifCount > 0 ? "S " + Globals.notifCount : "S"
                return Globals.notifCount > 99 ? "99+" : String(Globals.notifCount)
            }
            font.family: Theme.fontDisplay
            font.pixelSize: Tokens.fontSizeLabel
            color: Globals.notifDnd
                ? Theme.inkRed
                : (Globals.notifCount > 0 ? Theme.inkYellow : Theme.textDim)
        }

        MouseArea {
            id: badgeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Globals.toggleWidget("notifications", root)
        }
    }
}
