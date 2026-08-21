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
    id: shellRoot

    // Inbox count for the top-bar badge: live mako toasts + history,
    // minus ids the user cleared in the console this session.
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
        id: topBarWindow
        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: Tokens.topBarHeight + Tokens.topBarCorner
        color: "transparent"
        // Normal: honor exclusiveZone. Auto would reserve the hanging corners too
        // and shove every dropdown down by another radiusXl.
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: Tokens.topBarHeight
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "voidfarer-top"

        TopBar {
            anchors.fill: parent
        }
    }

    // CPU / GPU / RAM dropdown --- hangs off the right of the top bar
    PanelWindow {
        id: dropdownWindow
        anchors { top: true; right: true }
        implicitWidth:  sysPanel.implicitWidth
        implicitHeight: Globals.activePanel !== "" ? sysPanel.implicitHeight : 0

        Behavior on implicitHeight {
            NumberAnimation { duration: Tokens.animInstant; easing.type: Easing.OutQuart }
        }

        color:         "transparent"
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        focusable: Globals.activePanel !== ""
        WlrLayershell.layer:         WlrLayer.Top
        WlrLayershell.namespace:     "voidfarer-dropdown"
        // From the bar exclusive zone — not the screen edge.
        margins.top:   Tokens.spacingXs
        margins.right: Tokens.spacingXs
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

    // Dashboard / console / media --- centered under the bar
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
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        focusable: Globals.activeCenterPanel !== ""
        WlrLayershell.layer:         WlrLayer.Top
        WlrLayershell.namespace:     "voidfarer-center-dropdown"
        // From the bar exclusive zone — not the screen edge.
        margins.top:   Tokens.spacingXs
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
            anchors.margins: Tokens.borderXss
        }
    }

    // Workspace board — drag windows across workspaces
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
        WlrLayershell.namespace: "voidfarer-workspace-board"

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
            width:  implicitWidth
            height: implicitHeight
        }
    }

    // Power menu --- dim below the bar + bottom action strip
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
        WlrLayershell.namespace: "voidfarer-power"

        readonly property color dimColor: Qt.rgba(0, 0, 0, 0.45)

        Rectangle {
            id: dimBelow
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.bottom: parent.bottom
            anchors.top:    parent.top
            anchors.topMargin: Tokens.topBarHeight
            color:  powerMenuWindow.dimColor
            opacity: Globals.powerMenuOpen ? 1 : 0
            focus: Globals.powerMenuOpen
            Keys.onEscapePressed: Globals.closePowerMenu()

            Behavior on opacity {
                NumberAnimation {
                    duration: Tokens.animFast
                    easing.type: Easing.OutCubic
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Globals.closePowerMenu()
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

    Component.onCompleted: Globals.releaseEdgePanel()
}
