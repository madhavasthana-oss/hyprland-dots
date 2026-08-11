// MonoScrollBar.qml --- themed vertical scrollbar for ListView / Flickable
// Uses Controls.Basic so Fusion/Material system accent (often red) cannot paint the thumb.
import QtQuick
import QtQuick.Controls.Basic
import ".."

ScrollBar {
    id: root

    // Always show when content overflows; hide when it fits
    policy: {
        const f = parent
        if (!f)
            return ScrollBar.AsNeeded
        const ch = f.contentHeight !== undefined ? f.contentHeight : 0
        const h  = f.height !== undefined ? f.height : 0
        return (ch > h + 1) ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
    }

    width: Math.max(Tokens.borderXs + 1, Math.round(5 * Tokens.scale))
    padding: 1
    // Never inherit red/orange from the platform style palette
    palette {
        mid: Theme.borderIdle
        dark: Theme.borderIdle
        midlight: Theme.bgElevated
        highlight: Theme.accent
        button: Theme.accent
        window: Theme.bgElevated
    }

    contentItem: Rectangle {
        implicitWidth: Math.max(2, root.width - 2)
        radius: Tokens.radiusSm
        // Bright silver when active, softer when idle — never Theme failure → red
        color: root.pressed
                 ? Theme.textPrimary
                 : (root.hovered ? Theme.accent : Theme.accentWarm)
        opacity: root.size < 1.0
                 ? (root.hovered || root.pressed ? 1.0 : 0.85)
                 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
        }
        Behavior on color {
            ColorAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
        }
    }

    background: Rectangle {
        implicitWidth: root.width
        radius: Tokens.radiusSm
        color: Theme.bgElevated
        border.color: Theme.borderIdle
        border.width: Tokens.strokeWidth / 2
        opacity: root.size < 1.0 ? 0.9 : 0.0
        visible: root.size < 1.0
    }
}
