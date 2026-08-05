// RightEdgePanel.qml --- T.S.S host: tiles -> separator -> stack
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../.."
import "network"
import "bluetooth"
import "settings"
import "notifications"

Item {
    id: root

    // Size to the WINDOW parent, not a fixed implicit that fights collapsed width
    anchors.fill: parent

    property bool open: false
    // Force-open is sticky only until hover handoff, timeout, or collapse
    readonly property bool revealed: open || Globals.edgeForced

    function collapse() {
        hideTimer.stop()
        forceTimeout.stop()
        root.open = false
        Globals.releaseEdgePanel()
    }

    readonly property var panelOrder: ["wifi", "bluetooth", "settings", "notifications"]

    function switchPanel(panel) {
        Globals.activeEdgePanel = panel
        Globals.lastEdgePanel = panel
        Qt.callLater(root.grabActiveFocus)
    }

    function cyclePanel(delta) {
        const order = root.panelOrder
        let idx = order.indexOf(Globals.activeEdgePanel)
        if (idx < 0)
            idx = 0
        idx = (idx + delta + order.length) % order.length
        switchPanel(order[idx])
    }

    function grabActiveFocus() {
        if (!root.revealed)
            return
        const panel = Globals.activeEdgePanel
        if (panel === "wifi")
            wifiPage.grabListFocus()
        else if (panel === "bluetooth")
            btPage.grabListFocus()
        else if (panel === "notifications")
            notifPage.grabListFocus()
        else
            root.forceActiveFocus()
    }

    onOpenChanged: {
        if (open)
            Qt.callLater(root.grabActiveFocus)
    }

    focus: true
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            root.collapse()
            event.accepted = true
        } else if (event.key === Qt.Key_Left) {
            root.cyclePanel(-1)
            event.accepted = true
        } else if (event.key === Qt.Key_Right) {
            root.cyclePanel(1)
            event.accepted = true
        } else if (event.key === Qt.Key_1) {
            root.switchPanel("wifi")
            event.accepted = true
        } else if (event.key === Qt.Key_2) {
            root.switchPanel("bluetooth")
            event.accepted = true
        } else if (event.key === Qt.Key_3) {
            root.switchPanel("settings")
            event.accepted = true
        } else if (event.key === Qt.Key_4) {
            root.switchPanel("notifications")
            event.accepted = true
        }
    }

    // Hover only while the panel is wide enough to be meaningful.
    // When collapsed the thin strip still opens on enter.
    HoverHandler {
        id: hoverHandler
        onHoveredChanged: {
            if (hovered) {
                hideTimer.stop()
                root.open = true
                // Handoff: badge force-pin ends once the pointer is on the panel
                if (Globals.edgeForced) {
                    forceTimeout.stop()
                    Globals.releaseEdgePanel()
                }
            } else {
                hideTimer.restart()
            }
        }
    }

    Timer {
        id: hideTimer
        interval: Tokens.edgeHideDelay
        repeat: false
        onTriggered: {
            if (!hoverHandler.hovered && !Globals.edgeForced)
                root.open = false
        }
    }

    // Never leave the panel force-pinned forever (badge open without hover)
    Timer {
        id: forceTimeout
        interval: Tokens.edgeForceTimeoutMs
        repeat: false
        onTriggered: {
            if (!hoverHandler.hovered) {
                Globals.releaseEdgePanel()
                root.open = false
            } else {
                Globals.releaseEdgePanel()
            }
        }
    }

    Connections {
        target: Globals
        function onEdgeForcedChanged() {
            if (Globals.edgeForced) {
                hideTimer.stop()
                root.open = true
                forceTimeout.restart()
                Qt.callLater(root.grabActiveFocus)
            } else {
                forceTimeout.stop()
                if (!hoverHandler.hovered)
                    hideTimer.restart()
            }
        }
    }

    // Visual card --- only drawn when revealed to avoid a tall invisible hover slab
    Rectangle {
        id: panelBg
        anchors.fill:    parent
        anchors.margins: root.revealed ? Tokens.edgePanelPad : 0
        radius:          Tokens.radiusXl
        visible:         root.revealed
        color: Qt.rgba(
            Theme.bgConsole.r,
            Theme.bgConsole.g,
            Theme.bgConsole.b,
            Theme.opacityConsole
        )
        border.color: Theme.borderActive
        border.width: Math.max(Tokens.borderXss, Math.round(Tokens.strokeWidthActive))
        antialiasing: true
        clip: true
    }

    // Content clipped to the card so nothing paints outside or steals layout
    Item {
        id: contentHost
        anchors.fill:    panelBg
        anchors.margins: Tokens.paddingH
        visible:         root.revealed
        clip:            true

        ColumnLayout {
            id: mainLayout
            anchors.fill: parent
            spacing:      Tokens.spacingSm

            EdgeTabs {
                id: tabs
                Layout.fillWidth: true
                Layout.maximumHeight: tabs.implicitHeight
                active: Globals.activeEdgePanel
                onSwitched: (panel) => root.switchPanel(panel)
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Tokens.strokeWidth
                color: Theme.borderIdle
                opacity: 0.5
            }

            StackLayout {
                id: stack
                Layout.fillWidth:  true
                Layout.fillHeight: true
                clip: true

                currentIndex: {
                    const panels = ["wifi", "bluetooth", "settings", "notifications"]
                    const idx = panels.indexOf(Globals.activeEdgePanel)
                    return idx < 0 ? 0 : idx
                }

                NetworkFrontend {
                    id: wifiPage
                    Layout.fillWidth:  true
                    Layout.fillHeight: true
                }

                BluetoothFrontend {
                    id: btPage
                    Layout.fillWidth:  true
                    Layout.fillHeight: true
                }

                SettingsFrontend {
                    id: settingsPage
                    Layout.fillWidth:  true
                    Layout.fillHeight: true
                    onRequestClose: root.collapse()
                }

                NotifFrontend {
                    id: notifPage
                    Layout.fillWidth:  true
                    Layout.fillHeight: true
                }
            }
        }
    }
}
