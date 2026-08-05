// WorkspaceBoard.qml --- content-sized mini-desktops + drag-drop
// Layout: board hugs a 5×2 grid of 16:9 tiles (no giant empty panel).
// DnD: DropArea on tiles + flat windowSpace chips (quickshell-overview pattern).
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../.."
import "../../utils"

Item {
    id: root

    // Content-driven size — shell binds width/height to these
    readonly property int wsCount: Globals.workspaceNumber
    readonly property int cols: Tokens.workspaceBoardCols
    readonly property int rows: Math.ceil(wsCount / Math.max(1, cols))
    readonly property int screenW: Math.max(1, WorkspaceHub.screenW)
    readonly property int screenH: Math.max(1, WorkspaceHub.screenH)
    readonly property real screenAspect: screenW / Math.max(1, screenH)
    readonly property int iconSz: Tokens.workspaceBoardIcon
    readonly property int gap: Tokens.workspaceBoardGap
    readonly property int pad: Tokens.workspaceBoardPad

    readonly property int miniW: Tokens.workspaceBoardMiniW
    readonly property int miniH: Math.max(
        Tokens.statBoxHeight,
        Math.round(miniW / Math.max(0.5, screenAspect)))
    readonly property int labelH: Tokens.workspaceBoardLabelH
    readonly property int cellW: miniW
    readonly property int cellH: labelH + miniH + Tokens.spacingXss
    readonly property int gridW: cols * cellW + Math.max(0, cols - 1) * gap
    readonly property int gridH: rows * cellH + Math.max(0, rows - 1) * gap
    readonly property int titleH: Math.max(Tokens.actionBtnHeight, Tokens.fontSizeLabel + Tokens.spacingXs)
    readonly property int chromeH: titleH + Tokens.spacingXs
        + Math.max(1, Math.round(Tokens.strokeWidth)) + Tokens.spacingXs

    implicitWidth:  pad * 2 + gridW
    implicitHeight: pad * 2 + chromeH + gridH
    width:  implicitWidth
    height: implicitHeight
    clip: true

    // Overview-style DnD state
    property int draggingFromWorkspace: -1
    property int draggingTargetWorkspace: -1
    property string draggingAddress: ""
    property bool isDragging: draggingAddress.length > 0

    // Absorb clicks so the dim overlay behind the card doesn't steal them
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: (mouse) => { mouse.accepted = true }
    }

    Rectangle {
        anchors.fill: parent
        radius: Tokens.radiusXl
        color: Qt.rgba(Theme.bgConsole.r, Theme.bgConsole.g, Theme.bgConsole.b, Theme.opacityConsole)
        border.color: Theme.borderActive
        border.width: Math.max(Tokens.borderXss, Math.round(Tokens.strokeWidthActive))
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.pad
        spacing: Tokens.spacingXs

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: root.titleH
            spacing: Tokens.spacingSm

            Text {
                text: "WORKSPACE BOARD"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.accent
            }
            Text {
                Layout.fillWidth: true
                text: root.isDragging
                    ? ("drop · WS "
                       + (root.draggingTargetWorkspace > 0
                          ? String(root.draggingTargetWorkspace) : "—"))
                    : (root.wsCount + " workspaces  ·  drag to move")
                font.family: Theme.fontMono
                font.pixelSize: Tokens.fontSizeTiny
                color: Theme.textDim
                elide: Text.ElideRight
            }
            Text {
                text: "↻"
                font.pixelSize: Tokens.fontSizeSmall
                color: refMouse.containsMouse ? Theme.accent : Theme.textDim
                MouseArea {
                    id: refMouse
                    anchors.fill: parent
                    anchors.margins: -Tokens.spacingXs
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: WorkspaceHub.refresh()
                }
            }
            Rectangle {
                Layout.preferredHeight: Tokens.actionBtnHeight
                Layout.preferredWidth: closeLbl.implicitWidth + 2 * Tokens.paddingH
                radius: Tokens.radiusSm
                color: closeMouse.containsMouse ? Theme.bgElevated : Theme.bgSurface
                border.color: Theme.borderIdle
                border.width: Tokens.strokeWidth
                Text {
                    id: closeLbl
                    anchors.centerIn: parent
                    text: "CLOSE"
                    font.family: Theme.fontDisplay
                    font.pixelSize: Tokens.fontSizeLabel
                    color: Theme.textPrimary
                }
                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Globals.closeWorkspaceBoard()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(1, Math.round(Tokens.strokeWidth))
            color: Theme.borderIdle
            opacity: 0.5
        }

        // Grid host — exact content size, no stretch empty region
        Item {
            id: gridHost
            Layout.preferredWidth:  root.gridW
            Layout.preferredHeight: root.gridH
            Layout.alignment: Qt.AlignHCenter
            width:  root.gridW
            height: root.gridH

            readonly property int cellW: root.cellW
            readonly property int cellH: root.cellH
            readonly property int miniH: root.miniH
            readonly property int headerH: root.labelH
            readonly property int hGap: root.gap
            readonly property int vGap: root.gap

            function cellX(wsId) {
                const i = wsId - 1
                return (i % root.cols) * (cellW + hGap)
            }
            function cellY(wsId) {
                const i = wsId - 1
                return Math.floor(i / root.cols) * (cellH + vGap)
            }
            function miniX(wsId) { return cellX(wsId) }
            function miniY(wsId) {
                return cellY(wsId) + headerH + Tokens.spacingXss
            }
            function miniWidth()  { return root.miniW }
            function miniHeight() { return root.miniH }

            Item {
                id: grid
                anchors.fill: parent

                // --- Layer 1: workspace tiles + DropAreas ---
                Repeater {
                    model: root.wsCount

                    Item {
                        id: desk
                        property int wsId: index + 1
                        property bool isFocused: WorkspaceHub.focusedWorkspaceId === wsId
                        property bool dropHover: root.draggingTargetWorkspace === wsId
                            && root.isDragging
                        property int clientCount: {
                            const _ = WorkspaceHub.clientsByWorkspace
                            return WorkspaceHub.clientsOn(desk.wsId).length
                        }

                        width:  gridHost.cellW
                        height: gridHost.cellH
                        x: gridHost.cellX(wsId)
                        y: gridHost.cellY(wsId)
                        z: 0

                        // Compact label strip
                        Row {
                            id: labelRow
                            width: parent.width
                            height: gridHost.headerH
                            spacing: Tokens.spacingXs

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: String(desk.wsId)
                                font.family: Theme.fontDisplay
                                font.pixelSize: Tokens.fontSizeLabel
                                font.bold: desk.isFocused
                                color: desk.isFocused ? Theme.accent : Theme.textDim
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: desk.isFocused
                                text: "ACTIVE"
                                font.family: Theme.fontMono
                                font.pixelSize: Tokens.fontSizeTiny
                                color: Theme.stateSafe
                            }
                            Item { width: 1; height: 1 } // spacer via Layout not available in Row easily
                            // Right-align count with a spacer Item
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            height: gridHost.headerH
                            verticalAlignment: Text.AlignVCenter
                            text: desk.clientCount > 0 ? String(desk.clientCount) : ""
                            font.family: Theme.fontMono
                            font.pixelSize: Tokens.fontSizeTiny
                            color: Theme.textMuted
                        }

                        // Mini desktop (fills remaining cell height)
                        Rectangle {
                            id: bezel
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: gridHost.miniH
                            radius: Tokens.radiusMd
                            color: Theme.bgPrimary
                            border.color: desk.dropHover ? Theme.accent
                                        : (desk.isFocused ? Theme.borderActive : Theme.borderIdle)
                            border.width: desk.dropHover
                                ? Math.max(2, Tokens.strokeWidthActive)
                                : Tokens.strokeWidth
                            clip: true

                            DropArea {
                                anchors.fill: parent
                                onEntered: (drag) => {
                                    root.draggingTargetWorkspace = desk.wsId
                                    drag.accept(Qt.MoveAction)
                                }
                                onExited: {
                                    if (root.draggingTargetWorkspace === desk.wsId)
                                        root.draggingTargetWorkspace = -1
                                }
                            }

                            // Click empty desktop → focus workspace
                            MouseArea {
                                anchors.fill: parent
                                z: -1
                                acceptedButtons: Qt.LeftButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!root.isDragging)
                                        WorkspaceHub.switchToWorkspace(desk.wsId)
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: Tokens.workspaceMiniPad
                                radius: Tokens.radiusSm
                                color: Theme.bgConsole
                                border.color: Theme.borderIdle
                                border.width: Tokens.strokeWidth

                                // Large faded workspace number watermark
                                Text {
                                    anchors.centerIn: parent
                                    text: String(desk.wsId)
                                    font.family: Theme.fontDisplay
                                    font.pixelSize: Math.max(Tokens.fontSizeLarge,
                                        Math.round(parent.height * 0.42))
                                    font.weight: Font.DemiBold
                                    color: Theme.textDim
                                    opacity: desk.clientCount === 0 ? 0.35 : 0.12
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: desk.clientCount === 0 && !desk.dropHover
                                    text: "empty"
                                    font.family: Theme.fontMono
                                    font.pixelSize: Tokens.fontSizeTiny
                                    color: Theme.textDim
                                    opacity: 0.7
                                }
                            }
                        }
                    }
                }

                // --- Layer 2: flat window chips ---
                Item {
                    id: windowSpace
                    anchors.fill: parent
                    z: 10

                    property var allClients: {
                        const m = WorkspaceHub.clientsByWorkspace
                        const out = []
                        if (!m)
                            return out
                        for (let w = 1; w <= root.wsCount; w++) {
                            const list = m[String(w)]
                            if (!list)
                                continue
                            for (let i = 0; i < list.length; i++)
                                out.push(list[i])
                        }
                        return out
                    }

                    Repeater {
                        model: windowSpace.allClients

                        Item {
                            id: winChip
                            property string address: modelData.address || ""
                            property int homeWorkspace: modelData.workspaceId || 1
                            property string className: modelData.className || ""
                            property string title: modelData.title || ""
                            property string iconSource: modelData.icon || ""
                            property bool dragInProgress: false
                            property real homeX: 0
                            property real homeY: 0

                            readonly property real pad: Tokens.workspaceMiniPad
                            readonly property real innerW: Math.max(1, gridHost.miniWidth() - 2 * pad)
                            readonly property real innerH: Math.max(1, gridHost.miniHeight() - 2 * pad)

                            readonly property real nx: Math.max(0, Math.min(0.88,
                                (modelData.x || 0) / root.screenW))
                            readonly property real ny: Math.max(0, Math.min(0.88,
                                (modelData.y || 0) / root.screenH))
                            readonly property real nw: Math.max(0.16, Math.min(
                                1 - nx, (modelData.w || 200) / root.screenW))
                            readonly property real nh: Math.max(0.16, Math.min(
                                1 - ny, (modelData.h || 200) / root.screenH))

                            x: gridHost.miniX(homeWorkspace) + pad + nx * innerW
                            y: gridHost.miniY(homeWorkspace) + pad + ny * innerH
                            width:  Math.max(root.iconSz + 6, nw * innerW)
                            height: Math.max(root.iconSz + 6, nh * innerH)
                            z: dragInProgress ? 99999 : 1

                            visible: !(root.isDragging
                                && root.draggingAddress === address
                                && !dragInProgress)

                            Drag.source: winChip
                            Drag.hotSpot.x: width / 2
                            Drag.hotSpot.y: height / 2
                            Drag.supportedActions: Qt.MoveAction

                            Rectangle {
                                anchors.fill: parent
                                radius: Tokens.radiusSm
                                color: dragArea.containsMouse || winChip.dragInProgress
                                    ? Theme.bgElevated : Theme.bgSurface
                                border.color: winChip.dragInProgress
                                    ? Theme.accent
                                    : (dragArea.containsMouse
                                       ? Theme.borderActive : Theme.borderIdle)
                                border.width: Tokens.strokeWidth
                            }

                            Image {
                                id: chipIcon
                                anchors.centerIn: parent
                                width:  Math.min(root.iconSz, parent.width - 6)
                                height: Math.min(root.iconSz, parent.height - 6)
                                source: winChip.iconSource
                                sourceSize: Qt.size(Math.max(1, width * 2), Math.max(1, height * 2))
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                smooth: true
                                visible: status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: chipIcon.status !== Image.Ready
                                text: {
                                    const t = winChip.className || winChip.title || "?"
                                    return String(t).charAt(0).toUpperCase()
                                }
                                font.family: Theme.fontDisplay
                                font.pixelSize: Tokens.fontSizeSmall
                                color: Theme.accent
                            }

                            MouseArea {
                                id: dragArea
                                anchors.fill: parent
                                hoverEnabled: true
                                preventStealing: true
                                cursorShape: drag.active
                                    ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                                acceptedButtons: Qt.LeftButton
                                drag.target: winChip
                                drag.axis: Drag.XAndYAxis
                                drag.smoothed: false
                                drag.threshold: 4

                                property bool moved: false

                                onPressed: (mouse) => {
                                    moved = false
                                    winChip.homeX = winChip.x
                                    winChip.homeY = winChip.y
                                    winChip.dragInProgress = true
                                    root.draggingFromWorkspace = winChip.homeWorkspace
                                    root.draggingTargetWorkspace = winChip.homeWorkspace
                                    root.draggingAddress = winChip.address
                                    WorkspaceHub.dragActive = true
                                    winChip.Drag.source = winChip
                                    winChip.Drag.hotSpot.x = mouse.x
                                    winChip.Drag.hotSpot.y = mouse.y
                                    winChip.Drag.active = true
                                }

                                onPositionChanged: {
                                    if (drag.active)
                                        moved = true
                                }

                                onReleased: {
                                    const target = root.draggingTargetWorkspace
                                    const addr = root.draggingAddress
                                    const from = root.draggingFromWorkspace
                                    const wasMoved = moved

                                    winChip.Drag.active = false
                                    winChip.dragInProgress = false
                                    WorkspaceHub.dragActive = false
                                    root.draggingAddress = ""
                                    root.draggingFromWorkspace = -1
                                    root.draggingTargetWorkspace = -1

                                    if (wasMoved && addr.length && target > 0 && target !== from) {
                                        WorkspaceHub.moveToWorkspace(addr, target, true)
                                    } else if (!wasMoved && addr.length) {
                                        winChip.x = winChip.homeX
                                        winChip.y = winChip.homeY
                                        WorkspaceHub.focusWindow(addr)
                                    } else {
                                        winChip.x = winChip.homeX
                                        winChip.y = winChip.homeY
                                    }

                                    Qt.callLater(function () {
                                        WorkspaceHub.refresh()
                                    })
                                }

                                onCanceled: {
                                    winChip.Drag.active = false
                                    winChip.dragInProgress = false
                                    WorkspaceHub.dragActive = false
                                    root.draggingAddress = ""
                                    root.draggingFromWorkspace = -1
                                    root.draggingTargetWorkspace = -1
                                    winChip.x = winChip.homeX
                                    winChip.y = winChip.homeY
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            Globals.closeWorkspaceBoard()
            event.accepted = true
        }
    }
    focus: true

    Component.onCompleted: WorkspaceHub.refresh()
    Connections {
        target: Globals
        function onWorkspaceBoardOpenChanged() {
            if (Globals.workspaceBoardOpen) {
                root.draggingAddress = ""
                root.draggingTargetWorkspace = -1
                root.draggingFromWorkspace = -1
                WorkspaceHub.dragActive = false
                WorkspaceHub.refresh()
                root.forceActiveFocus()
            }
        }
    }
}
