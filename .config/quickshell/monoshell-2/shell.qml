import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "bars"
import "utils"
import "widgets/rightBarWidgets"
import "widgets/centerBarWidgets"
import "widgets/leftBarWidgets"
import "bottom"

ShellRoot {
    id: shellRoot

    // Live mako count for center-bar notification badge
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

    // =====================================================================
    //  UNIFIED TOP SURFACE
    //  Bar strip + dropdowns share ONE PanelWindow so panels anchor flush
    //  under the strip (no exclusive-zone / margin double-offset).
    // =====================================================================
    PanelWindow {
        id: barWindow
        anchors {
            top: true
            left: true
            right: true
        }

        readonly property int hug: Tokens.rounding.screen
        readonly property bool centerOpen: Globals.activeCenterPanel !== ""
        readonly property bool sysOpen: Globals.activePanel !== ""
        readonly property bool anyDrop: centerOpen || sysOpen

        // Opaque bar / corner color (matches solid strip)
        readonly property color hugColor: Theme.bgSurface
        readonly property color panelFill: Theme.bgConsole

        // Measured drop content heights (0 when closed)
        readonly property int centerDropH: centerOpen
            ? centerPanel.implicitHeight
            : 0
        readonly property int sysDropH: sysOpen
            ? sysPanel.implicitHeight + 2 * Tokens.padding.v
            : 0
        readonly property int dropH: Math.max(centerDropH, sysDropH)

        // Always reserve corner band; grow further when panels open
        // (corners stay painted under the strip even while dropdowns are up)
        implicitHeight: Tokens.bar.height
            + Math.max(Tokens.rounding.screen, anyDrop ? dropH : 0)

        Behavior on implicitHeight {
            NumberAnimation {
                duration: Tokens.anim.instant
                easing.type: Easing.OutQuart
            }
        }

        color: "transparent"
        // Only reserve the strip — panels overlay free desktop space
        exclusiveZone: Tokens.bar.exclusiveZone
        focusable: anyDrop
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "monoshell-bar"

        // ---- root fill ----
        Item {
            id: barRoot
            anchors.fill: parent

            // ---- bar strip (fixed height at top) ----
            Bar {
                id: mainBar
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                }
                height: Tokens.bar.height
                z: 10
            }

            // ---- screen hug corners — ALWAYS on (do not vanish when panels open) ----
            Item {
                id: screenCorners
                anchors {
                    left: parent.left
                    right: parent.right
                    top: mainBar.bottom
                }
                height: Tokens.rounding.screen
                z: 2

                RoundCorner {
                    anchors {
                        left: parent.left
                        top: parent.top
                    }
                    implicitSize: Tokens.rounding.screen
                    color: barWindow.hugColor
                    corner: RoundCorner.CornerEnum.TopLeft
                }
                RoundCorner {
                    anchors {
                        right: parent.right
                        top: parent.top
                    }
                    implicitSize: Tokens.rounding.screen
                    color: barWindow.hugColor
                    corner: RoundCorner.CornerEnum.TopRight
                }
            }

            // ---- drop zone: flush under bar strip ----
            Item {
                id: dropZone
                anchors {
                    left: parent.left
                    right: parent.right
                    top: mainBar.bottom
                }
                height: barWindow.dropH
                visible: barWindow.anyDrop
                z: 5

                // ========== CENTER PANEL (dashboard / console / media) ==========
                Item {
                    id: centerDrop
                    anchors {
                        top: parent.top
                        horizontalCenter: parent.horizontalCenter
                    }
                    width: barWindow.hug + centerPanel.implicitWidth + barWindow.hug
                    height: centerPanel.implicitHeight
                    visible: barWindow.centerOpen

                    // Left flank — opaque bar color curves into free space
                    RoundCorner {
                        anchors {
                            left: parent.left
                            top: parent.top
                        }
                        implicitSize: barWindow.hug
                        color: barWindow.hugColor
                        corner: RoundCorner.CornerEnum.TopRight
                    }

                    Rectangle {
                        id: centerPanelBg
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            left: parent.left
                            leftMargin: barWindow.hug
                            right: parent.right
                            rightMargin: barWindow.hug
                        }
                        topLeftRadius: 0
                        topRightRadius: 0
                        bottomLeftRadius: Tokens.radius.xl
                        bottomRightRadius: Tokens.radius.xl
                        color: barWindow.panelFill
                        border.width: 0
                        clip: true

                        CenterPanel {
                            id: centerPanel
                            anchors.fill: parent
                            anchors.margins: Tokens.border.xss
                        }
                    }

                    RoundCorner {
                        anchors {
                            right: parent.right
                            top: parent.top
                        }
                        implicitSize: barWindow.hug
                        color: barWindow.hugColor
                        corner: RoundCorner.CornerEnum.TopLeft
                    }
                }

                // ========== SYSTEM PANEL (CPU / GPU / RAM) — right ==========
                Item {
                    id: sysDrop
                    anchors {
                        top: parent.top
                        right: parent.right
                        rightMargin: Math.max(0, Tokens.bar.padH - barWindow.hug)
                    }
                    width: barWindow.hug
                        + sysPanel.implicitWidth
                        + 2 * Tokens.padding.h
                        + barWindow.hug
                    height: sysPanel.implicitHeight + 2 * Tokens.padding.v
                    visible: barWindow.sysOpen

                    RoundCorner {
                        anchors {
                            left: parent.left
                            top: parent.top
                        }
                        implicitSize: barWindow.hug
                        color: barWindow.hugColor
                        corner: RoundCorner.CornerEnum.TopRight
                    }

                    Rectangle {
                        id: panelBg
                        anchors {
                            top: parent.top
                            bottom: parent.bottom
                            left: parent.left
                            leftMargin: barWindow.hug
                            right: parent.right
                            rightMargin: barWindow.hug
                        }
                        topLeftRadius: 0
                        topRightRadius: 0
                        bottomLeftRadius: Tokens.radius.xl
                        bottomRightRadius: Tokens.radius.xl
                        color: barWindow.panelFill
                        border.width: 0
                        clip: true

                        SystemPanel {
                            id: sysPanel
                            anchors {
                                top: parent.top
                                left: parent.left
                                margins: Tokens.padding.v
                            }
                        }
                    }

                    RoundCorner {
                        anchors {
                            right: parent.right
                            top: parent.top
                        }
                        implicitSize: barWindow.hug
                        color: barWindow.hugColor
                        corner: RoundCorner.CornerEnum.TopLeft
                    }
                }
            }
        }
    }

    // =====================================================================
    //  WORKSPACE BOARD  (fullscreen overlay)
    // =====================================================================
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
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "monoshell-workspace-board"

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

    // =====================================================================
    //  BOTTOM POWER BAR
    // =====================================================================
    PanelWindow {
        id: bottomBarWindow
        anchors {
            left: true
            right: true
            bottom: true
        }
        margins.left:  Tokens.bottomBarOriginX
        margins.right: Tokens.bottomBarOriginX

        implicitWidth: Tokens.bottomBarWidth
        implicitHeight: bottomPanel.revealed
            ? Tokens.bottomBarHeight
            : Tokens.bottomHoverZoneHeight

        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Top
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
                    duration: Tokens.anim.fast
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    Component.onCompleted: Globals.releaseEdgePanel()
}
