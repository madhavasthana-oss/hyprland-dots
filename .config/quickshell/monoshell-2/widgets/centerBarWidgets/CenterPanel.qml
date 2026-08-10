// CenterPanel.qml --- fixed-height stack; children must fit (no overflow)
import QtQuick
import QtQuick.Layouts
import "../.."
import "."

Item {
    id: root
    // Drive shell dropdown size from tokens (shell binds window to these)
    implicitWidth:  Tokens.centerSmallerWidth
    implicitHeight: Tokens.listRowHeight + Tokens.strokeWidth + Tokens.centerExpandedHeight
                    + Tokens.paddingV
    clip: true

    readonly property var panelOrder: ["dashboard", "console", "media"]

    function switchCenterPanel(panel) {
        Globals.activeCenterPanel = panel
        Globals.lastCenterPanel = panel
        Qt.callLater(root.grabActiveFocus)
    }

    function cycleCenterPanel(delta) {
        const order = root.panelOrder
        let idx = order.indexOf(Globals.activeCenterPanel)
        if (idx < 0)
            idx = 0
        idx = (idx + delta + order.length) % order.length
        switchCenterPanel(order[idx])
    }

    function grabActiveFocus() {
        const panel = Globals.activeCenterPanel
        if (panel === "console")
            consoleView.grabListFocus()
        else
            root.forceActiveFocus()
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Left) {
            root.cycleCenterPanel(-1)
            event.accepted = true
        } else if (event.key === Qt.Key_Right) {
            root.cycleCenterPanel(1)
            event.accepted = true
        } else if (event.key === Qt.Key_1) {
            root.switchCenterPanel("dashboard")
            event.accepted = true
        } else if (event.key === Qt.Key_2) {
            root.switchCenterPanel("console")
            event.accepted = true
        } else if (event.key === Qt.Key_3) {
            root.switchCenterPanel("media")
            event.accepted = true
        }
    }
    focus: true

    ColumnLayout {
        id: mainCenterPanelLayout
        anchors.fill: parent
        spacing: 0

        CenterTabs {
            id: tabs
            Layout.fillWidth: true
            Layout.leftMargin:  Tokens.paddingH
            Layout.rightMargin: Tokens.paddingH
            Layout.preferredHeight: Tokens.listRowHeight
            Layout.maximumHeight: Tokens.listRowHeight

            active: Globals.activeCenterPanel
            onSwitched: (panel) => root.switchCenterPanel(panel)
        }

        Rectangle {
            id: sep
            Layout.fillWidth: true
            Layout.leftMargin:  Tokens.paddingH
            Layout.rightMargin: Tokens.paddingH
            Layout.preferredHeight: Tokens.strokeWidth
            Layout.maximumHeight: Tokens.strokeWidth
            color: Theme.borderIdle
            opacity: 0.5
        }

        // Fixed footprint — content must layout inside, never grow the window
        Item {
            id: stackHost
            Layout.fillWidth: true
            Layout.preferredHeight: Tokens.centerExpandedHeight
            Layout.minimumHeight: Tokens.centerExpandedHeight
            Layout.maximumHeight: Tokens.centerExpandedHeight
            clip: true

            StackLayout {
                id: stack
                anchors.fill: parent
                clip: true

                currentIndex: {
                    const panels = ["dashboard", "console", "media"]
                    const idx = panels.indexOf(Globals.activeCenterPanel)
                    return idx < 0 ? 0 : idx
                }

                DashboardWidget {
                    id: dashboard
                }
                ConsoleWidget {
                    id: consoleView
                }
                MediaWidget {
                    id: media
                }
            }
        }
    }
}
