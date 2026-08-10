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
                "bash", "-c",
                "makoctl list -j 2>/dev/null | python3 -c "
                    + "'import sys,json; d=json.load(sys.stdin); print(len(d) if isinstance(d,list) else 0)' "
                    + "2>/dev/null || echo 0"
            ]
            stdout: StdioCollector {
                onStreamFinished: {
                    const n = parseInt(text.trim())
                    Globals.notifCount = isNaN(n) ? 0 : Math.max(0, n)
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
        WlrLayershell.namespace: "monoshell-right"

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
        WlrLayershell.namespace:     "monoshell-dropdown"
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
        WlrLayershell.namespace: "monoshell-left"

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
        WlrLayershell.namespace: "monoshell-workspace-board"

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
        WlrLayershell.namespace: "monoshell-center"

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
        WlrLayershell.namespace:     "monoshell-center-dropdown"
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

    PanelWindow {
        id: bottomBarWindow
        anchors {
            left:   true
            right:  true
            bottom: true
        }
        margins.left:  Tokens.bottomBarOriginX
        margins.right: Tokens.bottomBarOriginX

        implicitWidth: Tokens.bottomBarWidth
        implicitHeight: bottomPanel.revealed
            ? Tokens.bottomBarHeight
            : Tokens.bottomHoverZoneHeight

        color:         "transparent"
        exclusiveZone: 0
        WlrLayershell.layer:     WlrLayer.Top
        WlrLayershell.namespace: "monoshell-bottom"

        BottomPanel {
            id: bottomPanel
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width:  Tokens.bottomBarWidth
            height: Tokens.bottomBarHeight
            opacity: bottomPanel.revealed
                ? Theme.opacityVisible
                : Theme.opacityHidden

            Behavior on opacity {
                NumberAnimation {
                    duration: Tokens.animFast
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    // Wi‑Fi / Bluetooth / settings / notifications live under
    // widgets/centerBarWidgets/console/ (see ConsoleWidget.qml).

    Component.onCompleted: Globals.releaseEdgePanel()
}
