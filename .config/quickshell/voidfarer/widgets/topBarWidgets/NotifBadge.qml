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
        color: badgeMouse.containsMouse ? Theme.bgElevated : Theme.bgSurface
        border.color: Globals.notifDnd
            ? Theme.stateCritical
            : (Globals.notifCount > 0 ? Theme.borderActive : Theme.borderIdle)
        border.width: Tokens.strokeWidth

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
                ? Theme.stateCritical
                : (Globals.notifCount > 0 ? Theme.accent : Theme.textDim)
        }

        MouseArea {
            id: badgeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Globals.toggleEdgePanel("notifications")
        }
    }
}
