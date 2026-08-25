import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "bars"
import "widgets/rightBarWidgets"
import "widgets/leftBarWidgets"
import "bottom"

ShellRoot {
    id:shellRoot

    // Live mako count for center-bar notification badge (inlined ---
    // directory-import types under ShellRoot are unreliable on this qs build)
    Item {
        id: notifCountPoller

        function refresh() {
            notifCountProc.running = true
        }

        Process {
            id: notifCountProc
            command: [
                "python3", "-c",
                "import json, subprocess as s\n"
                + "def load(cmd):\n"
                + "    try:\n"
                + "        d = json.loads(s.check_output(cmd, stderr=s.DEVNULL) or b'[]')\n"
                + "        return d if isinstance(d, list) else []\n"
                + "    except Exception:\n"
                + "        return []\n"
                + "print(json.dumps({'active': load(['makoctl', 'list', '-j']), 'history': load(['makoctl', 'history', '-j'])}))\n"
            ]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        const data = JSON.parse(text.length ? text : "{}")
                        const active = Array.isArray(data.active) ? data.active : []
                        const history = Array.isArray(data.history) ? data.history : []
                        const seen = ({})
                        let n = 0
                        const all = active.concat(history)
                        for (let i = 0; i < all.length; i++) {
                            const id = all[i] && all[i].id
                            if (id === undefined || id === null)
                                continue
                            const key = String(id)
                            if (seen[key])
                                continue
                            seen[key] = true
                            if (!Globals.notifAcceptIncoming(id))
                                continue
                            n++
                        }
                        Globals.notifCloseIncomingBatch()
                        Globals.notifCount = n
                    } catch (e) {
                        Globals.notifCount = 0
                    }
                }
            }
        }

        Timer {
            interval: Tokens.notifBadgePollMs
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: notifCountPoller.refresh()
        }
    }

    PanelWindow { 
      id: rightBarWindow
        anchors { top: true; right: true }
        implicitWidth:  Tokens.rightWidth
        implicitHeight: Tokens.rightHeight 
        margins.top: Tokens.topMargin
        margins.right: Tokens.sideMargin
        color: "transparent"
        exclusiveZone: Tokens.exclusiveZone
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "astral-vagabond-right"

        RightBar { anchors.fill: parent }
    }
    
    PanelWindow {
        id: dropdownWindow
        anchors { top: true; right: true } 
        implicitWidth:  sysPanel.implicitWidth
        implicitHeight: Globals.activePanel !== "" ? sysPanel.implicitHeight : 0
        
        Behavior on implicitHeight {
            NumberAnimation { duration: Tokens.animInstant; easing.type: Easing.OutQuart }
        }

        color:         "transparent"
        exclusiveZone: 0
        // Keyboard for CPU core list / RAM process list / GPU actions
        focusable: Globals.activePanel !== ""
        WlrLayershell.layer:         WlrLayer.Top
        WlrLayershell.namespace:     "astral-vagabond-dropdown"
        WlrLayershell.margins.top:   0
        WlrLayershell.margins.right: Tokens.spacingXs
        visible: Globals.activePanel !== ""

         Rectangle {
            id: panelBg
            anchors.fill: parent
            radius:       Tokens.radiusXl
            color:        Theme.bgConsole
            opacity:      Theme.opacityConsole
            border.color: Theme.borderConsole
            border.width: Tokens.strokeWidth
        }

        SystemPanel {
            id: sysPanel
        }
    }
        
    PanelWindow {
        id: leftBarWindow
        anchors { top: true; left: true }
        implicitWidth:  Tokens.leftWidth
        implicitHeight: Tokens.leftHeight
        color: "transparent"
        margins.top: Tokens.topMargin
        margins.left: Tokens.sideMargin
        exclusiveZone: Tokens.exclusiveZone
        WlrLayershell.layer:     WlrLayer.Top
        WlrLayershell.namespace: "astral-vagabond-left"

        LeftBar { anchors.fill: parent }
    }

    // Workspace board — drag windows across workspaces (full-screen overlay, card centered)
    PanelWindow {
        id: workspaceBoardWindow
        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }
        visible: Globals.workspaceBoardOpen
        color: "transparent"
        exclusiveZone: 0
        focusable: Globals.workspaceBoardOpen
        WlrLayershell.layer:     WlrLayer.Overlay
        WlrLayershell.namespace: "astral-vagabond-workspace-board"

        // Dim click-catcher — click outside card closes board
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.45)
            MouseArea {
                anchors.fill: parent
                onClicked: Globals.closeWorkspaceBoard()
            }
        }

        WorkspaceBoard {
            id: workspaceBoard
            anchors.centerIn: parent
            // Content-sized card (hugs the 5×2 mini-desktop grid)
            width:  implicitWidth
            height: implicitHeight
        }
    }

    PanelWindow {
        id: centerBarWindow
        anchors { top: true }
        // Collapsed: HUD strip. Expanded: HUD + separator + utility-sized widget.
        implicitWidth: {
            if (Globals.activeWidget === "")
                return Tokens.centerCollapsedWidth
            return Math.max(
                Tokens.centerCollapsedWidth,
                Tokens.widgetWidthFor(Globals.activeWidget)
            )
        }
        implicitHeight: {
            if (Globals.activeWidget === "")
                return Tokens.centerHeight
            return Tokens.centerHeight
                + Math.max(1, Math.round(Tokens.strokeWidth))
                + Tokens.widgetHeightFor(Globals.activeWidget)
        }
        color: "transparent"
        margins.top: Tokens.topMargin
        exclusiveZone: Tokens.exclusiveZone
        focusable: Globals.activeWidget !== ""
        WlrLayershell.layer:     WlrLayer.Top
        WlrLayershell.namespace: "astral-vagabond-center"

        Behavior on implicitWidth {
            NumberAnimation {
                duration: Tokens.widgetMorphMs
                easing.type: Easing.OutCubic
            }
        }
        Behavior on implicitHeight {
            NumberAnimation {
                duration: Tokens.widgetMorphMs
                easing.type: Easing.OutCubic
            }
        }

        Keys.onEscapePressed: Globals.closeWidget()

        CenterBar { anchors.fill: parent }
    }

    // Power menu --- bottom action strip only. No dim overlay.
    // Opened from the shutdown icon next to RAM.
    PanelWindow {
        id: powerMenuWindow
        anchors { bottom: true }
        implicitWidth:  Tokens.bottomBarWidth
        implicitHeight: Tokens.bottomBarHeight
        margins.bottom: Tokens.sideMargin
        color:          "transparent"
        exclusiveZone:  0
        exclusionMode:  ExclusionMode.Ignore
        visible:        Globals.powerMenuOpen
        focusable:      Globals.powerMenuOpen
        WlrLayershell.layer:     WlrLayer.Overlay
        WlrLayershell.namespace: "astral-vagabond-power"

        Keys.onEscapePressed: Globals.closePowerMenu()

        BottomPanel {
            id: bottomPanel
            anchors.fill: parent
        }
    }

    Component.onCompleted: Globals.releaseEdgePanel()
}
