// LeftBar.qml --- workspace numbers + active-workspace icon strip + window title
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
    width:  Tokens.leftWidth
    height: Tokens.leftHeight
    clip: true

    // Sliding window of 5 workspace numbers — continuous/infinite, no bank jump
    // (board still pages 1–10 / 11–20; left bar just slides past boundaries)
    readonly property int visibleCount: Tokens.workspaceBarVisible
    property int focusedId: Hyprland.focusedWorkspace?.id ?? 1
    property int windowStart: 1

    readonly property int wsCellWidth: Tokens.workspaceCellWidth
    readonly property int wsRowSpacing: Tokens.spacingXss
    readonly property int wsRowWidth:
        visibleCount * wsCellWidth
        + Math.max(0, visibleCount - 1) * wsRowSpacing

    readonly property int stripIcon: Tokens.workspaceStripIcon
    readonly property int stripMax: Tokens.workspaceStripMaxIcons

    // Windows on the focused workspace only (layout order from hub)
    readonly property var activeClients: WorkspaceHub.focusedClients

    function syncWindowStart(id) {
        // Keep focused visible; slide by 1 step at edges (no snap to bank start)
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

    SideRect {
        anchors.fill: parent
        barWidth:     Tokens.leftWidth
        barHeight:    Tokens.leftHeight
        radius:       Tokens.leftHeight / 2
        alertActive:  false
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin:  Tokens.workspaceToggleMargin
        anchors.rightMargin: Tokens.workspaceToggleMargin
        spacing: Tokens.spacingXss

        // --- Workspace numbers (clean, no in-cell badges) ---
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
                        font.pixelSize: Tokens.fontSizeSmall
                        color: wsDelegate.isActive ? Theme.textSecondary : Theme.textMuted

                        Behavior on color {
                            ColorAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
                        }
                    }

                    // Thin active indicator under the number (not icons)
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2
                        width: Math.min(parent.width - 2, Tokens.spacingMd)
                        height: Math.max(1, Math.round(Tokens.strokeWidth))
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

        // --- Icon strip for the ACTIVE workspace only (beside numbers, not under them) ---
        Row {
            id: iconStrip
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: false
            Layout.maximumWidth: leftBar.stripIcon * leftBar.stripMax
                + Tokens.spacingXss * (leftBar.stripMax - 1)
                + Tokens.spacingMd
            spacing: Tokens.spacingXss
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
                        font.pixelSize: Tokens.fontSizeTiny
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
                font.pixelSize: Tokens.fontSizeTiny
                color: Theme.textDim
            }
        }

        // Separator
        Rectangle {
            Layout.preferredWidth:  Math.max(1, Math.round(Tokens.strokeWidth))
            Layout.preferredHeight: parent.height * 0.45
            Layout.alignment:       Qt.AlignVCenter
            Layout.leftMargin:      Tokens.spacingXs
            Layout.rightMargin:     Tokens.spacingXs
            color:                  Theme.borderIdle
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
            font.pixelSize: Tokens.fontSizeSmall
            color: Theme.textSecondary
        }

        // Board toggle
        Rectangle {
            Layout.preferredWidth:  Tokens.workspaceBarIconSize + Tokens.spacingXs
            Layout.preferredHeight: Tokens.workspaceBarIconSize
            Layout.maximumWidth:    Tokens.workspaceBarIconSize + Tokens.spacingXs
            Layout.alignment: Qt.AlignVCenter
            radius: Tokens.radiusSm
            color: boardBtn.containsMouse || Globals.workspaceBoardOpen
                ? Theme.bgElevated : "transparent"
            border.color: Globals.workspaceBoardOpen ? Theme.borderActive : Theme.borderIdle
            border.width: Tokens.strokeWidth

            Text {
                anchors.centerIn: parent
                text: "▦"
                font.pixelSize: Tokens.fontSizeSmall
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
