// PowerButton.qml --- opens the bottom power strip
import QtQuick
import QtQuick.Layouts 1.15
import Qt5Compat.GraphicalEffects
import "../.."

Item {
    id: root
    implicitWidth: Tokens.workspaceBarIconSize + Tokens.spacingSm
    implicitHeight: Tokens.topBarHeight

    readonly property bool active: Globals.powerMenuOpen
    readonly property bool hovered: powerMouse.containsMouse

    Rectangle {
        anchors.centerIn: parent
        width: Tokens.workspaceBarIconSize + (root.hovered || root.active ? Tokens.spacingXs : 0)
        height: width
        radius: Tokens.radiusSm
        color: root.active
            ? Qt.rgba(Theme.inkRed.r, Theme.inkRed.g, Theme.inkRed.b, 0.18)
            : (root.hovered ? Theme.bgElevated : "transparent")
        border.width: 0

        Behavior on color {
            ColorAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
        }
        Behavior on width {
            NumberAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
        }
    }

    Image {
        id: powerGlyph
        anchors.centerIn: parent
        width: Tokens.iconSizeLarge + Tokens.spacingXs
        height: Tokens.iconSizeLarge + Tokens.spacingXs
        source: Theme.iconPoweroff
        sourceSize: Qt.size(width * 2, height * 2)
        fillMode: Image.PreserveAspectFit
        smooth: true
        visible: false
        asynchronous: true
    }

    ColorOverlay {
        anchors.fill: powerGlyph
        source: powerGlyph
        color: Theme.inkRed
        opacity: root.active ? 1 : (root.hovered ? 0.9 : 0.62)

        Behavior on color {
            ColorAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        id: powerMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            Globals.togglePowerMenu()
            mouse.accepted = true
        }
    }
}
