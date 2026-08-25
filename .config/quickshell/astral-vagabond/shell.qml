import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "bars"
import "widgets/rightBarWidgets"
import "widgets/leftBarWidgets"
import "bottom"
import "utils"

ShellRoot {
    id:shellRoot

    IpcHandler {
        target: "launcher"
        function toggle(): void { Globals.toggleWidget("console") }
        function open(): void { Globals.openWidget("console") }
        function close(): void {
            if (Globals.activeWidget === "console")
                Globals.closeWidget()
        }
    }

    IpcHandler {
        target: "notifications"
        function toggle(): void { Globals.toggleWidget("notifications") }
        function dismissAll(): void { NotifServer.dismissAll() }
        function dndToggle(): void { NotifServer.toggleDnd() }
        function silentToggle(): void { NotifServer.toggleSilent() }
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

    // Notification toasts --- fixed overlay surface (never resize: Hypr smears).
    // QML animates the cards. Layer stays no_anim via astral-vagabond-*.
    PanelWindow {
        id: toastWindow
        anchors { top: true; right: true }
        implicitWidth:  Tokens.toastSurfaceWidth
        implicitHeight: Tokens.toastSurfaceHeight
        margins.top:    Tokens.topMargin + Tokens.exclusiveZone + Tokens.spacingSm
        margins.right:  Tokens.sideMargin
        color:          "transparent"
        exclusiveZone:  0
        exclusionMode:  ExclusionMode.Ignore
        visible:        NotifServer.toasts.count > 0 || toastWrap.opacity > 0.01
        WlrLayershell.layer:     WlrLayer.Overlay
        WlrLayershell.namespace: "astral-vagabond-toasts"

        mask: toastWindow.visible && toastStack.height > 1 ? toastMask : null

        Region {
            id: toastMask
            item: toastStack
        }

        Item {
            id: toastWrap
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: Tokens.centerMaskPad
            anchors.rightMargin: Tokens.centerMaskPad
            width: Tokens.toastWidth
            height: Math.max(1, toastStack.height)
            opacity: NotifServer.toasts.count > 0 ? 1 : 0
            enabled: NotifServer.toasts.count > 0

            Behavior on opacity {
                NumberAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
            }

            NotifToasts {
                id: toastStack
                anchors.top: parent.top
                anchors.right: parent.right
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
