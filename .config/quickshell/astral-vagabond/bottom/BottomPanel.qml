import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import ".."

Item {
    id: root

    implicitWidth:  Tokens.bottomBarWidth
    implicitHeight: Tokens.bottomBarHeight

    // Sticky open state --- raw hover alone causes thrash when the
    // PanelWindow height animates under the cursor at the screen edge.
    property bool open: false
    readonly property bool revealed: open

    HoverHandler {
        id: hoverHandler
        onHoveredChanged: {
            if (hovered) {
                hideTimer.stop()
                root.open = true
            } else {
                hideTimer.restart()
            }
        }
    }

    Timer {
        id: hideTimer
        interval: Tokens.bottomHideDelay
        repeat: false
        onTriggered: {
            // Re-check: pointer may have re-entered during the grace period
            if (!hoverHandler.hovered)
                root.open = false
        }
    }

    // --- Shape ---
    Rectangle {
        id: panelBg
        anchors.fill: parent
        radius:       Tokens.radiusMd
        color:        Theme.bgConsole
        opacity:      Theme.opacityConsole
        border.color: Theme.borderConsole
        border.width: Tokens.strokeWidth
    }

    // --- Power actions (left -> right) ---
    // poweroff * reboot * logout * sleep * lock
    RowLayout {
        id: actionRow
        anchors.fill:    parent
        anchors.margins: Tokens.paddingH
        spacing:         Tokens.spacingMd

        Repeater {
            model: [
                { key: "poweroff", icon: Theme.iconPoweroff },
                { key: "reboot",   icon: Theme.iconReboot },
                { key: "logout",   icon: Theme.iconLogout },
                { key: "lock",     icon: Theme.iconLock },
                { key: "sleep",    icon: Theme.iconSleep }
            ]

            Item {
                Layout.fillWidth:  true
                Layout.fillHeight: true

                Image {
                    id: glyph
                    anchors.centerIn: parent
                    width:  Tokens.iconSizeBottom
                    height: Tokens.iconSizeBottom
                    source: modelData.icon
                    sourceSize.width:  Tokens.iconSizeBottom
                    sourceSize.height: Tokens.iconSizeBottom
                    fillMode: Image.PreserveAspectFit
                    visible: false
                    smooth: true
                }

                ColorOverlay {
                    anchors.fill: glyph
                    source:       glyph
                    color: actionMouse.containsMouse ? Theme.accent : Theme.textMuted

                    Behavior on color {
                        ColorAnimation {
                            duration: Tokens.animFast
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                MouseArea {
                    id: actionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.runAction(modelData.key)
                }
            }
        }
    }

    function runAction(key) {
        switch (key) {
        case "poweroff":
            Quickshell.execDetached(["systemctl", "poweroff"])
            break
        case "reboot":
            Quickshell.execDetached(["systemctl", "reboot"])
            break
        case "logout":
            // Hyprland 0.56+ (Lua): classic "exit" dispatcher is gone.
            // Prefer hl.dsp.exit(), fall back to loginctl so logout never no-ops.
            Quickshell.execDetached([
                "bash", "-lc",
                "hyprctl dispatch 'hl.dsp.exit()' 2>/dev/null" +
                " || hyprctl dispatch exit 2>/dev/null" +
                " || loginctl terminate-session \"${XDG_SESSION_ID:-self}\""
            ])
            break
        case "lock":
            Quickshell.execDetached(["bash", "-lc", "pidof hyprlock >/dev/null || hyprlock"])
            break
        case "sleep":
            Quickshell.execDetached(["systemctl", "suspend"])
            break
        }
    }
}
