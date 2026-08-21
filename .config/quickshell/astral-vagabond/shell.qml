import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "bars"
import "widgets/rightBarWidgets"
import "widgets/centerBarWidgets"
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
        // Collapsed: HUD width × same height as left/right bars.
        // Expanded: centerSmallerWidth × centerHeight.
        implicitWidth: Globals.activeCenterPanel !== ""
            ? Tokens.centerExpandedWidth
            : Tokens.centerCollapsedWidth
        implicitHeight: Tokens.centerHeight
        color: "transparent"
        margins.top: Tokens.topMargin
        exclusiveZone: Tokens.exclusiveZone
        WlrLayershell.layer:     WlrLayer.Top
        WlrLayershell.namespace: "astral-vagabond-center"

        Behavior on implicitWidth {
            NumberAnimation {
                duration: Tokens.animInstant
                easing.type: Easing.OutQuart
            }
        }
        Behavior on implicitHeight {
            NumberAnimation {
                duration: Tokens.animInstant
                easing.type: Easing.OutQuart
            }
        }

        CenterBar { anchors.fill: parent }
    }

    PanelWindow {
        id: centerDropdownWindow
        anchors { top: true }
        implicitWidth:  centerPanel.implicitWidth
        implicitHeight: Globals.activeCenterPanel !== "" ? centerPanel.implicitHeight : 0

        Behavior on implicitWidth {
            NumberAnimation {
                duration: Tokens.animInstant
                easing.type: Easing.OutQuart
            }
        }
        Behavior on implicitHeight {
            NumberAnimation { duration: Tokens.animInstant; easing.type: Easing.OutQuart }
        }
        
        color:         "transparent"
        exclusiveZone: 0
        // Keyboard for notes / todo fields on dashboard
        focusable: Globals.activeCenterPanel !== ""
        WlrLayershell.layer:         WlrLayer.Top
        WlrLayershell.namespace:     "astral-vagabond-center-dropdown"
        WlrLayershell.margins.top:   Tokens.spacingXs
        visible: Globals.activeCenterPanel !== "" 

        Rectangle {
            id: centerPanelBg
            anchors.fill: parent
            radius:       Tokens.radiusXl
            color:        Theme.bgConsole
            opacity:      Theme.opacityConsole
            border.color: Theme.borderConsole
            border.width: Tokens.strokeWidth
        }

        CenterPanel {
            id: centerPanel
            anchors.fill: parent
            // Keep a hair of inset so border radius doesn't clip card chrome
            anchors.margins: Tokens.borderXss
        }
    }

    // Power menu --- full-screen dim + bottom actions. Opened from the
    // shutdown icon next to RAM. A hole over the right bar lets that
    // icon stay visible and receive the close click.
    PanelWindow {
        id: powerMenuWindow
        anchors {
            top:    true
            left:   true
            right:  true
            bottom: true
        }
        color:         "transparent"
        exclusiveZone: 0
        visible:       Globals.powerMenuOpen
        focusable:     Globals.powerMenuOpen
        WlrLayershell.layer:     WlrLayer.Overlay
        WlrLayershell.namespace: "astral-vagabond-power"

        readonly property int barBandH: Tokens.topMargin + Tokens.rightHeight
        readonly property int rightHoleW: Tokens.sideMargin + Tokens.rightWidth
        readonly property color dimColor: Qt.rgba(0, 0, 0, 0.45)

        // Clickable surface is the dim + the power strip. The right-bar
        // hole is omitted so the shutdown icon underneath still receives
        // the second click that closes this menu.
        mask: Region {
            item: dimBelow
            Region {
                item: dimTopLeft
                intersection: Intersection.Combine
            }
            Region {
                item: bottomPanel
                intersection: Intersection.Combine
            }
        }

        Keys.onEscapePressed: Globals.closePowerMenu()

        Rectangle {
            id: dimBelow
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.bottom: parent.bottom
            height: parent.height - powerMenuWindow.barBandH
            color:  powerMenuWindow.dimColor
            opacity: Globals.powerMenuOpen ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Tokens.animFast
                    easing.type: Easing.OutCubic
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }
        }

        Rectangle {
            id: dimTopLeft
            anchors.left: parent.left
            anchors.top:  parent.top
            width:  parent.width - powerMenuWindow.rightHoleW
            height: powerMenuWindow.barBandH
            color:  powerMenuWindow.dimColor
            opacity: Globals.powerMenuOpen ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Tokens.animFast
                    easing.type: Easing.OutCubic
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }
        }

        BottomPanel {
            id: bottomPanel
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: Globals.powerMenuOpen
                ? Tokens.sideMargin
                : -Tokens.bottomBarHeight
            width:  Tokens.bottomBarWidth
            height: Tokens.bottomBarHeight
            opacity: Globals.powerMenuOpen ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Tokens.animFast
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on anchors.bottomMargin {
                NumberAnimation {
                    duration: Tokens.animMedium
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    // Wi‑Fi / Bluetooth / settings / notifications live under
    // widgets/centerBarWidgets/console/ (see ConsoleWidget.qml).

    Component.onCompleted: Globals.releaseEdgePanel()
}
