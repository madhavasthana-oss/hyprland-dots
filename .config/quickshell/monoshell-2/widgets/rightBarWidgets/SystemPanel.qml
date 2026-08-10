// SystemPanel.qml
import QtQuick
import QtQuick.Layouts
import "../.."
import "system/CPU"
import "system/GPU"
import "system/RAM"
import "."

Item {
    id: root
    implicitHeight: mainTelemetryLayout.implicitHeight
    implicitWidth: mainTelemetryLayout.implicitWidth

    readonly property var panelOrder: ["cpu", "gpu", "ram"]

    function switchPanel(panel) {
        Globals.activePanel = panel
        Globals.lastPanel = panel
    }

    function cyclePanel(delta) {
        const order = root.panelOrder
        let idx = order.indexOf(Globals.activePanel)
        if (idx < 0)
            idx = 0
        idx = (idx + delta + order.length) % order.length
        switchPanel(order[idx])
    }

    // Left/Right cycle CPU/GPU/RAM when focus isn't on a text field
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Left) {
            root.cyclePanel(-1)
            event.accepted = true
        } else if (event.key === Qt.Key_Right) {
            root.cyclePanel(1)
            event.accepted = true
        } else if (event.key === Qt.Key_1) {
            root.switchPanel("cpu")
            event.accepted = true
        } else if (event.key === Qt.Key_2) {
            root.switchPanel("gpu")
            event.accepted = true
        } else if (event.key === Qt.Key_3) {
            root.switchPanel("ram")
            event.accepted = true
        }
    }
    focus: true

    ColumnLayout{
        id: mainTelemetryLayout
        // 1. Shared tab bar (lives above everything)
        SystemTabs {
            id: tabs
            Layout.leftMargin: Tokens.paddingH
            Layout.rightMargin: Tokens.paddingH

            active: Globals.activePanel
            onSwitched: (panel) => { root.switchPanel(panel) }
        }

        // 2. Separator line
        Rectangle {
            id: sep
            Layout.leftMargin: Tokens.paddingH
            Layout.rightMargin: Tokens.paddingH
            Layout.preferredHeight: Tokens.strokeWidth
            Layout.fillWidth: true
            color: Theme.borderIdle
            opacity: 0.5
        }

        // 3. The three content panels (pure content now)
        StackLayout {
            id: stack

            currentIndex: {
                let panels = ["cpu", "gpu", "ram"]
                return panels.indexOf(Globals.activePanel)
            }

            CPUFrontend  { id: cpu }
            GPUFrontend  { id: gpu }
            RAMFrontend  { id: ram }
        }
    }
}
