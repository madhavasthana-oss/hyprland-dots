// Workspaces.qml --- sliding workspace numbers + active-window icon strip + board
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import "../.."

Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: Tokens.topBarHeight

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
    readonly property var activeClients: WorkspaceHub.focusedClients

    function syncWindowStart(id) {
        if (id >= root.windowStart + root.visibleCount)
            root.windowStart = id - root.visibleCount + 1
        else if (id < root.windowStart)
            root.windowStart = id
        if (root.windowStart < 1)
            root.windowStart = 1
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            const id = Hyprland.focusedWorkspace?.id ?? 1
            root.focusedId = id
            root.syncWindowStart(id)
        }
    }

    Component.onCompleted: root.syncWindowStart(root.focusedId)

    RowLayout {
        id: row
        height: parent.height
        spacing: Tokens.spacingXss

        // --- Workspace numbers ---
        RowLayout {
            Layout.alignment:      Qt.AlignVCenter
            Layout.fillWidth:      false
            Layout.fillHeight:     true
            Layout.preferredWidth: root.wsRowWidth
            Layout.minimumWidth:   root.wsRowWidth
            Layout.maximumWidth:   root.wsRowWidth
            spacing:               root.wsRowSpacing

            Repeater {
                model: Array.from(
                    { length: root.visibleCount },
                    (_, i) => root.windowStart + i
                )

                Item {
                    id: wsDelegate
                    property int  wsId:     modelData
                    property bool isActive: root.focusedId === wsId
                    property bool occupied: {
                        const _ = WorkspaceHub.clientsByWorkspace
                        const list = WorkspaceHub.clientsOn(wsId)
                        return list && list.length > 0
                    }

                    Layout.fillWidth:      false
                    Layout.fillHeight:     true
                    Layout.preferredWidth: root.wsCellWidth
                    Layout.minimumWidth:   root.wsCellWidth
                    Layout.maximumWidth:   root.wsCellWidth

                    Text {
                        anchors.centerIn: parent
                        text: wsDelegate.wsId
                        font.family: Theme.fontDisplay
                        font.pixelSize: Tokens.fontSizeSmall
                        color: wsDelegate.isActive
                            ? Theme.textSecondary
                            : (wsDelegate.occupied ? Theme.textMuted : Theme.textDim)

                        Behavior on color {
                            ColorAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
                        }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2
                        width: wsDelegate.isActive
                            ? Math.min(parent.width - 2, Tokens.spacingMd)
                            : (wsDelegate.occupied ? Tokens.spacingXs : 0)
                        height: Math.max(1, Math.round(Tokens.strokeWidth))
                        radius: 1
                        color: wsDelegate.isActive ? Theme.accent : Theme.borderIdle
                        opacity: wsDelegate.isActive ? 0.85 : (wsDelegate.occupied ? 0.55 : 0)

                        Behavior on width {
                            NumberAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
                        }
                        Behavior on opacity {
                            NumberAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WorkspaceHub.switchToWorkspace(wsDelegate.wsId)
                    }
                }
            }
        }

        // --- Active-workspace icon strip ---
        Row {
            id: iconStrip
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: false
            Layout.fillHeight: false
            Layout.maximumWidth: root.stripIcon * root.stripMax
                + Tokens.spacingXss * (root.stripMax - 1)
                + Tokens.spacingMd
            spacing: Tokens.spacingXss
            visible: root.activeClients && root.activeClients.length > 0
            clip: true
            height: root.stripIcon

            Repeater {
                model: {
                    const list = root.activeClients
                    if (!list || !list.length)
                        return []
                    return list.slice(0, root.stripMax)
                }

                Item {
                    width:  root.stripIcon
                    height: root.stripIcon

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
                visible: root.activeClients
                    && root.activeClients.length > root.stripMax
                anchors.verticalCenter: parent.verticalCenter
                text: "+" + (root.activeClients.length - root.stripMax)
                font.family: Theme.fontMono
                font.pixelSize: Tokens.fontSizeTiny
                color: Theme.textDim
            }
        }

        // Board toggle
        Rectangle {
            Layout.fillWidth:       false
            Layout.fillHeight:      false
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
