// WindowTitle.qml --- focused window title; designed to live in a fillWidth slot
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts 1.15
import "../.."

Item {
    id: root
    implicitWidth: title.implicitWidth
    implicitHeight: title.implicitHeight
    clip: true

    readonly property string currentTitle: (
        Hyprland.activeToplevel &&
        Hyprland.activeToplevel.workspace &&
        Hyprland.focusedWorkspace &&
        Hyprland.activeToplevel.workspace.id === Hyprland.focusedWorkspace.id
    ) ? (Hyprland.activeToplevel.title || "Desktop") : "Desktop"

    Text {
        id: title
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        elide: Text.ElideRight
        maximumLineCount: 1
        clip: true
        text: root.currentTitle
        font.family: Theme.fontDisplay
        font.pixelSize: Tokens.fontSizeSmall
        color: Theme.textSecondary
    }
}
