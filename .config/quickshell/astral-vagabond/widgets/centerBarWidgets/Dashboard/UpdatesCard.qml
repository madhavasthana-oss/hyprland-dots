// UpdatesCard.qml --- scrollable live package list (checkupdates)
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../.."
import "../../../utils"

Rectangle {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.minimumHeight: 0
    radius: Tokens.radiusMd
    color: Theme.bgSurface
    border.color: pendingCount > 0 ? Theme.borderActive : Theme.borderIdle
    border.width: Tokens.strokeWidth
    clip: true

    property int pendingCount: 0
    property string statusLine: "…"
    property bool checking: false
    property bool dashboardOpen: Globals.activeWidget === "dashboard"

    ListModel { id: pkgModel }

    function refresh() {
        if (checking)
            return
        checking = true
        checkProc.running = true
    }

    function parseUpdates(text) {
        pkgModel.clear()
        const raw = (text || "").trim()
        if (!raw.length) {
            pendingCount = 0
            statusLine = "CLEAR"
            checking = false
            return
        }
        const lines = raw.split("\n").filter(function (l) {
            return l.trim().length > 0
        })
        pendingCount = lines.length
        statusLine = pendingCount + " PKG"
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim()
            // checkupdates: name old -> new
            const parts = line.split(/\s+/)
            const name = parts[0] || line
            let detail = ""
            if (parts.length >= 4 && parts[2] === "->")
                detail = parts[1] + " → " + parts[3]
            else if (parts.length > 1)
                detail = parts.slice(1).join(" ")
            pkgModel.append({ name: name, detail: detail, raw: line })
        }
        checking = false
    }

    Process {
        id: checkProc
        command: [
            "bash", "-c",
            "if command -v checkupdates >/dev/null 2>&1; then "
                + "checkupdates 2>/dev/null; "
                + "elif command -v pacman >/dev/null 2>&1; then "
                + "pacman -Qu 2>/dev/null; "
                + "fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: root.parseUpdates(text)
        }
        onExited: function () {
            root.checking = false
            if (root.statusLine === "…" && pkgModel.count === 0)
                root.statusLine = "ERR"
        }
    }

    // Background poll; faster while dashboard is open
    Timer {
        id: pollTimer
        interval: root.dashboardOpen
            ? Tokens.updatesRefreshActiveMs
            : Tokens.updatesRefreshMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // Refresh immediately when user opens the dashboard
    Connections {
        target: Globals
        function onActiveWidgetChanged() {
            if (Globals.activeWidget === "dashboard")
                root.refresh()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.paddingH
        spacing: Tokens.spacingXss

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacingXs

            Text {
                text: "PATCHES"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.accent
            }

            Text {
                Layout.fillWidth: true
                text: root.checking ? "SCANNING…" : root.statusLine
                font.family: Theme.fontMono
                font.pixelSize: Tokens.fontSizeTiny
                color: root.pendingCount > 0 ? Theme.stateWarning : Theme.stateSafe
                elide: Text.ElideRight
                maximumLineCount: 1
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
                    onClicked: root.refresh()
                }
            }
        }

        ListView {
            id: pkgList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Tokens.spacingXss
            model: pkgModel
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            interactive: contentHeight > height
            ScrollBar.vertical: MonoScrollBar {}

            delegate: Rectangle {
                width: Math.max(0, pkgList.width
                    - (pkgList.contentHeight > pkgList.height
                        ? Tokens.borderXs + Tokens.spacingXss + 2
                        : 0))
                height: Tokens.listRowHeight
                radius: Tokens.radiusSm
                color: Theme.bgPrimary
                border.color: Theme.borderIdle
                border.width: Tokens.strokeWidth
                clip: true

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Tokens.paddingH
                    anchors.rightMargin: Tokens.paddingH
                    spacing: Tokens.spacingXs

                    Text {
                        Layout.fillWidth: true
                        text: model.name
                        font.family: Theme.fontMono
                        font.pixelSize: Tokens.fontSizeTiny
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                    Text {
                        visible: model.detail.length > 0
                        text: model.detail
                        font.family: Theme.fontMono
                        font.pixelSize: Tokens.fontSizeTiny
                        color: Theme.textDim
                        elide: Text.ElideLeft
                        Layout.maximumWidth: parent.width * 0.45
                        maximumLineCount: 1
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: pkgList.count === 0 && !root.checking
                text: root.statusLine === "CLEAR" ? "ALL CLEAR" : "NO DATA"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.textDim
            }

            Text {
                anchors.centerIn: parent
                visible: root.checking && pkgList.count === 0
                text: "SCANNING…"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.textDim
            }
        }
    }
}
