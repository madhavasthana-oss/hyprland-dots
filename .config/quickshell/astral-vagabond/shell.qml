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
        readonly property bool wantOpen: Globals.activePanel !== ""
        implicitWidth:  Math.max(1, sysPanel.implicitWidth)
        implicitHeight: Math.max(1, sysPanel.implicitHeight)
        color:         "transparent"
        exclusiveZone: 0
        focusable: wantOpen
        visible: wantOpen || dropWrap.opacity > 0.01
        WlrLayershell.layer:         WlrLayer.Top
        WlrLayershell.namespace:     "astral-vagabond-dropdown"
        WlrLayershell.margins.top:   0
        WlrLayershell.margins.right: Tokens.spacingXs

        Item {
            id: dropWrap
            width: parent.width
            height: parent.height
            opacity: dropdownWindow.wantOpen ? 1 : 0
            y: dropdownWindow.wantOpen ? 0 : -Tokens.spacingLg
            enabled: dropdownWindow.wantOpen
            clip: true

            Behavior on opacity {
                NumberAnimation { duration: Tokens.animMedium; easing.type: Easing.OutCubic }
            }
            Behavior on y {
                NumberAnimation { duration: Tokens.animMedium; easing.type: Easing.OutCubic }
            }

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
        readonly property bool wantOpen: Globals.workspaceBoardOpen
        visible: wantOpen || boardDim.opacity > 0.01
        color: "transparent"
        exclusiveZone: 0
        focusable: wantOpen
        WlrLayershell.layer:     WlrLayer.Overlay
        WlrLayershell.namespace: "astral-vagabond-workspace-board"

        Rectangle {
            id: boardDim
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.45)
            opacity: workspaceBoardWindow.wantOpen ? 1 : 0
            enabled: workspaceBoardWindow.wantOpen

            Behavior on opacity {
                NumberAnimation { duration: Tokens.animMedium; easing.type: Easing.OutCubic }
            }

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
            opacity: workspaceBoardWindow.wantOpen ? 1 : 0
            scale: workspaceBoardWindow.wantOpen ? 1 : 0.96
            transformOrigin: Item.Center
            enabled: workspaceBoardWindow.wantOpen

            Behavior on opacity {
                NumberAnimation { duration: Tokens.animMedium; easing.type: Easing.OutCubic }
            }
            Behavior on scale {
                NumberAnimation { duration: Tokens.animMedium; easing.type: Easing.OutCubic }
            }
        }
    }

    PanelWindow {
        id: centerBarWindow
        anchors { top: true }

        readonly property int destWidth: {
            if (Globals.activeWidget === "")
                return Tokens.centerCollapsedWidth
            return Math.max(
                Tokens.centerCollapsedWidth,
                Tokens.widgetWidthFor(Globals.activeWidget)
            )
        }
        readonly property int destHeight: {
            if (Globals.activeWidget === "")
                return Tokens.centerHeight
            return Tokens.centerHeight
                + Tokens.centerBodyGap
                + Tokens.widgetHeightFor(Globals.activeWidget)
                + Tokens.paddingV
        }

        // NEVER resize this Wayland surface. Hyprland smears/tears layer
        // buffers even with no_anim. Morph is QML chrome only.
        implicitWidth:  Tokens.centerSurfaceWidth
        implicitHeight: Tokens.centerSurfaceHeight
        color: "transparent"
        margins.top: Tokens.topMargin
        exclusiveZone: Tokens.exclusiveZone
        focusable: Globals.activeWidget !== ""
        WlrLayershell.layer:     WlrLayer.Top
        WlrLayershell.namespace: "astral-vagabond-center"

        // Input region only at rest. QWindow mask clips painting if it
        // tracks an animating item (the TV tear). Pad so AA is not sliced.
        readonly property bool morphing: {
            const w = chrome.width
            const h = chrome.height
            if (w < 2 || h < 2)
                return true
            return Math.round(w) !== destWidth || Math.round(h) !== destHeight
        }
        mask: morphing ? null : restMask

        Region {
            id: restMask
            item: hitbox
        }

        Item {
            id: hitbox
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: chrome.width + 2 * Tokens.centerMaskPad
            // Extra mask height hangs below the pill so the HUD stays
            // top-aligned with the left / right bars.
            height: {
                const padded = chrome.height + Tokens.centerMaskPad
                if (Globals.activeWidget === "")
                    return padded
                return Math.max(padded, Tokens.centerMaskHeight)
            }

            Item {
                id: chrome
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                width: centerBarWindow.destWidth
                height: centerBarWindow.destHeight
                focus: true

                Keys.onEscapePressed: Globals.closeWidget()

                Behavior on width {
                    NumberAnimation {
                        duration: Tokens.widgetMorphMs
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on height {
                    NumberAnimation {
                        duration: Tokens.widgetMorphMs
                        easing.type: Easing.OutCubic
                    }
                }

                CenterBar { anchors.fill: parent }
            }
        }
    }

    // Power menu --- bottom action strip only. No dim overlay.
    // Opened from the shutdown icon next to RAM.
    PanelWindow {
        id: powerMenuWindow
        anchors { bottom: true }
        readonly property bool wantOpen: Globals.powerMenuOpen
        implicitWidth:  Tokens.bottomBarWidth
        implicitHeight: Tokens.bottomBarHeight
        margins.bottom: Tokens.sideMargin
        color:          "transparent"
        exclusiveZone:  0
        exclusionMode:  ExclusionMode.Ignore
        visible:        wantOpen || powerWrap.opacity > 0.01
        focusable:      wantOpen
        WlrLayershell.layer:     WlrLayer.Overlay
        WlrLayershell.namespace: "astral-vagabond-power"

        Keys.onEscapePressed: Globals.closePowerMenu()

        Item {
            id: powerWrap
            width: parent.width
            height: parent.height
            opacity: powerMenuWindow.wantOpen ? 1 : 0
            y: powerMenuWindow.wantOpen ? 0 : Tokens.spacingMd
            enabled: powerMenuWindow.wantOpen

            Behavior on opacity {
                NumberAnimation { duration: Tokens.animMedium; easing.type: Easing.OutCubic }
            }
            Behavior on y {
                NumberAnimation { duration: Tokens.animMedium; easing.type: Easing.OutCubic }
            }

            BottomPanel {
                id: bottomPanel
                anchors.fill: parent
            }
        }
    }

    Component.onCompleted: Globals.releaseEdgePanel()
}
