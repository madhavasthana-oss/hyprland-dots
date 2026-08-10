// LeftBar.qml --- workspace numbers + active-workspace icon strip + window title
// Content zone for the unified Bar (no chrome).
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import "../utils"
import ".."

Item {
    id: leftBar
    clip: true

    // Sliding window of 5 workspace numbers — continuous/infinite, no bank jump
    readonly property int visibleCount: Tokens.workspaceBarVisible
    property int focusedId: Hyprland.focusedWorkspace?.id ?? 1
    property int windowStart: 1

    readonly property int wsCellWidth: Tokens.workspaceCellWidth
    readonly property int wsRowSpacing: Tokens.spacing.xss
    readonly property int wsRowWidth:
        visibleCount * wsCellWidth
        + Math.max(0, visibleCount - 1) * wsRowSpacing

    readonly property int stripIcon: Tokens.workspaceStripIcon
    readonly property int stripMax: Tokens.workspaceStripMaxIcons

    readonly property var activeClients: WorkspaceHub.focusedClients

    function syncWindowStart(id) {
        if (id >= leftBar.windowStart + leftBar.visibleCount)
            leftBar.windowStart = id - leftBar.visibleCount + 1
        else if (id < leftBar.windowStart)
            leftBar.windowStart = id
        if (leftBar.windowStart < 1)
            leftBar.windowStart = 1
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            const id = Hyprland.focusedWorkspace?.id ?? 1
            leftBar.focusedId = id
            leftBar.syncWindowStart(id)
        }
    }

    Component.onCompleted: leftBar.syncWindowStart(leftBar.focusedId)

    function switchToWorkspace(id) {
        WorkspaceHub.switchToWorkspace(id)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin:  Tokens.spacing.xs
        anchors.rightMargin: Tokens.spacing.sm
        spacing: Tokens.spacing.xss

        // --- Workspace numbers ---
        RowLayout {
            Layout.alignment:      Qt.AlignVCenter
            Layout.preferredWidth: leftBar.wsRowWidth
            Layout.minimumWidth:   leftBar.wsRowWidth
            Layout.maximumWidth:   leftBar.wsRowWidth
            Layout.fillWidth:      false
            Layout.fillHeight:     true
            spacing:               leftBar.wsRowSpacing

            Repeater {
                model: Array.from(
                    { length: leftBar.visibleCount },
                    (_, i) => leftBar.windowStart + i
                )

                Item {
                    id: wsDelegate
                    property int  wsId:     modelData
                    property bool isActive: leftBar.focusedId === wsId

                    Layout.fillHeight:     true
                    Layout.preferredWidth: leftBar.wsCellWidth
                    Layout.minimumWidth:   leftBar.wsCellWidth
                    Layout.maximumWidth:   leftBar.wsCellWidth

                    Text {
                        anchors.centerIn: parent
                        text: wsDelegate.wsId
                        font.family: Theme.fontDisplay
                        font.pixelSize: Tokens.type.small
                        color: wsDelegate.isActive ? Theme.textSecondary : Theme.textMuted

                        Behavior on color {
                            ColorAnimation { duration: Tokens.anim.fast; easing.type: Easing.OutCubic }
                        }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2
                        width: Math.min(parent.width - 2, Tokens.spacing.md)
                        height: Math.max(1, Math.round(Tokens.stroke.base))
                        radius: 1
                        color: Theme.accent
                        visible: wsDelegate.isActive
                        opacity: 0.85
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: leftBar.switchToWorkspace(wsDelegate.wsId)
                    }
                }
            }
        }

        // --- Icon strip for the ACTIVE workspace ---
        Row {
            id: iconStrip
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: false
            Layout.maximumWidth: leftBar.stripIcon * leftBar.stripMax
                + Tokens.spacing.xss * (leftBar.stripMax - 1)
                + Tokens.spacing.md
            spacing: Tokens.spacing.xss
            visible: leftBar.activeClients && leftBar.activeClients.length > 0
            clip: true
            height: leftBar.stripIcon

            Repeater {
                model: {
                    const list = leftBar.activeClients
                    if (!list || !list.length)
                        return []
                    return list.slice(0, leftBar.stripMax)
                }

                Item {
                    width:  leftBar.stripIcon
                    height: leftBar.stripIcon

                    Image {
                        id: glyph
                        anchors.fill: parent
                        source: modelData.icon || ""
                        sourceSize: Qt.size(width * 2, height * 2)
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        smooth: true
                        visible: status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: glyph.status !== Image.Ready
                        text: {
                            const t = modelData.className || modelData.title || "?"
                            return String(t).charAt(0).toUpperCase()
                        }
                        font.family: Theme.fontDisplay
                        font.pixelSize: Tokens.type.tiny
                        color: Theme.accent
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WorkspaceHub.focusWindow(modelData.address)
                        ToolTip.visible: containsMouse
                        ToolTip.delay: 350
                        ToolTip.text: modelData.title || modelData.className || ""
                    }
                }
            }

            Text {
                visible: leftBar.activeClients
                    && leftBar.activeClients.length > leftBar.stripMax
                anchors.verticalCenter: parent.verticalCenter
                text: "+" + (leftBar.activeClients.length - leftBar.stripMax)
                font.family: Theme.fontMono
                font.pixelSize: Tokens.type.tiny
                color: Theme.textDim
            }
        }

        // Active window title
        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            Layout.minimumWidth: 0
            elide: Text.ElideRight
            maximumLineCount: 1
            clip: true

            text: (
                Hyprland.activeToplevel &&
                Hyprland.activeToplevel.workspace &&
                Hyprland.focusedWorkspace &&
                Hyprland.activeToplevel.workspace.id === Hyprland.focusedWorkspace.id
            ) ? Hyprland.activeToplevel.title : "Desktop"

            font.family: Theme.fontDisplay
            font.pixelSize: Tokens.type.small
            color: Theme.textSecondary
        }

        // Board toggle
        Rectangle {
            Layout.preferredWidth:  Tokens.workspaceBarIconSize + Tokens.spacing.xs
            Layout.preferredHeight: Tokens.workspaceBarIconSize
            Layout.maximumWidth:    Tokens.workspaceBarIconSize + Tokens.spacing.xs
            Layout.alignment: Qt.AlignVCenter
            radius: Tokens.radius.sm
            color: boardBtn.containsMouse || Globals.workspaceBoardOpen
                ? Theme.bgElevated : "transparent"
            border.width: 0

            Text {
                anchors.centerIn: parent
                text: "▦"
                font.pixelSize: Tokens.type.small
                color: Globals.workspaceBoardOpen ? Theme.accent : Theme.textMuted
            }

            MouseArea {
                id: boardBtn
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Globals.toggleWorkspaceBoard()
            }
        }
    }
}
