// RightBar.qml --- BAT / VOL / CPU / GPU / RAM strip
// Content zone for the unified Bar (no chrome).
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.DBusMenu
import QtQuick
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import "../utils"
import ".."
import "../widgets/rightBarWidgets/power"
import "../widgets/rightBarWidgets/audio"
import "../widgets/rightBarWidgets/system/CPU"
import "../widgets/rightBarWidgets/system/GPU"
import "../widgets/rightBarWidgets/system/RAM"

Item {
    id: rightBar
    clip: true

    function __gradient__(color1, color2, alpha) {
        color1 = color1.toString()
        color2 = color2.toString()
        let r1 = parseInt(color1.slice(1, 3), 16)
        let g1 = parseInt(color1.slice(3, 5), 16)
        let b1 = parseInt(color1.slice(5, 7), 16)
        let r2 = parseInt(color2.slice(1, 3), 16)
        let g2 = parseInt(color2.slice(3, 5), 16)
        let b2 = parseInt(color2.slice(5, 7), 16)
        return "#"
            + Math.round((1 - alpha) * r1 + alpha * r2).toString(16).padStart(2, "0")
            + Math.round((1 - alpha) * g1 + alpha * g2).toString(16).padStart(2, "0")
            + Math.round((1 - alpha) * b1 + alpha * b2).toString(16).padStart(2, "0")
    }

    function __fmtGiB__(value) {
        return Number(value).toFixed(2)
    }

    // --- STAT LOADERS ---

    BATStats {
        id: batStat
        visible: false
        anchors.top: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        onReady: {
            batLabel.opacity = 1
            batPercent.opacity = 1
            constBatBar.opacity = 1
            varBatBar.opacity = 1
        }
    }

    Volume {
        id: audioStat
        visible: false
        anchors.top: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        onBecameReady: {
            volLabel.opacity = 1
            volPercent.opacity = 1
            constVolBar.opacity = 1
            varVolBar.opacity = 1
        }
        onVolumeModified: {
            volLabel.opacity = 1
            volPercent.opacity = 1
            constVolBar.opacity = 1
            varVolBar.opacity = 1
        }
        onReadyChanged: {
            if (!ready) {
                volLabel.opacity = 0.35
                volPercent.opacity = 0.35
                constVolBar.opacity = 0.35
                varVolBar.opacity = 0.35
            }
        }
    }

    CPUBackend {
        id: cpuStat
        visible: false
        anchors.top: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        readonly property int averageUsage: {
            if (!ready || cores.count === 0)
                return -1
            let sum = 0
            let counted = 0
            for (let i = 0; i < cores.count; i++) {
                let u = cores.get(i).usage
                if (u !== -1 && u !== undefined) {
                    sum += u
                    counted++
                }
            }
            return counted > 0 ? Math.round(sum / counted) : -1
        }

        onReadyChanged: {
            if (ready) {
                cpuLabel.opacity = 1
                cpuPercent.opacity = 1
                constCpuBar.opacity = 1
                varCpuBar.opacity = 1
            }
        }
    }

    GPUBackend {
        id: gpuStat
        visible: false
        anchors.top: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        onIsReadyChanged: {
            if (isReady) {
                gpuLabel.opacity = 1
                gpuPercent.opacity = 1
                constGpuBar.opacity = 1
                varGpuBar.opacity = 1
            }
        }
    }

    RAMBackend {
        id: ramStat
        visible: false
        anchors.top: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        readonly property string usageGiB: {
            if (ramTotal < 0 || ramInUse < 0)
                return "--/--"
            return rightBar.__fmtGiB__(ramInUse) + "/" + rightBar.__fmtGiB__(ramTotal) + " GiB"
        }

        onIsReadyChanged: {
            if (isReady) {
                ramLabel.opacity = 1
                ramValue.opacity = 1
            }
        }
    }

    // --- CONTENT ROW ---
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Tokens.spacing.sm
        anchors.rightMargin: Tokens.spacing.xs
        spacing: Tokens.spacing.xs

        Item { Layout.fillWidth: true }

        // ZONE 1 --- Battery + Volume
        GridLayout {
            columns: 3
            rows: 2
            rowSpacing: Tokens.spacing.xss
            columnSpacing: Tokens.columnSpacing
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: false

            Text {
                id: batLabel
                text: "BAT"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.type.label
                color: Theme.textSecondary
                opacity: 0
                Behavior on opacity {
                    NumberAnimation { duration: Tokens.anim.fadeIn; easing.type: Easing.OutCubic }
                }
            }

            Text {
                id: batPercent
                text: batStat.percentage + "%"
                font.family: Theme.fontMono
                font.pixelSize: Tokens.type.label
                color: Theme.textPrimary
                opacity: 0
                Behavior on opacity {
                    NumberAnimation { duration: Tokens.anim.fadeIn; easing.type: Easing.OutCubic }
                }
            }

            Rectangle {
                id: constBatBar
                Layout.preferredWidth: Tokens.usageBarWidth
                Layout.preferredHeight: Tokens.usageBarHeight
                color: Theme.bgElevated
                radius: Tokens.radius.xl
                opacity: 0
                Behavior on opacity {
                    NumberAnimation { duration: Tokens.anim.fadeIn; easing.type: Easing.OutCubic }
                }
                Rectangle {
                    id: varBatBar
                    width: parent.width * batStat.percentage * 0.01
                    height: parent.height
                    color: rightBar.__gradient__(Theme.stateSafe, Theme.stateCritical, 1.00 - (batStat.percentage / 100))
                    radius: Tokens.radius.xl
                    opacity: 0
                    Behavior on opacity {
                        NumberAnimation { duration: Tokens.anim.fadeIn; easing.type: Easing.OutCubic }
                    }
                }
            }

            Text {
                id: volLabel
                text: "VOL"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.type.label
                color: Theme.textSecondary
                opacity: 0
                Behavior on opacity {
                    NumberAnimation { duration: Tokens.anim.fadeIn; easing.type: Easing.OutCubic }
                }
            }

            Text {
                id: volPercent
                text: audioStat.muted ? "M" : audioStat.volume + "%"
                font.family: Theme.fontMono
                font.pixelSize: Tokens.type.label
                color: audioStat.muted ? Theme.textSecondary : Theme.textPrimary
                opacity: 0
                Behavior on opacity {
                    NumberAnimation { duration: Tokens.anim.fadeIn; easing.type: Easing.OutCubic }
                }
                Behavior on color {
                    ColorAnimation { duration: Tokens.anim.fast; easing.type: Easing.OutCubic }
                }
            }

            Rectangle {
                id: constVolBar
                implicitWidth: Tokens.usageBarWidth
                implicitHeight: Tokens.usageBarHeight
                color: Theme.bgElevated
                radius: Tokens.radius.xl
                opacity: 0
                Behavior on opacity {
                    NumberAnimation { duration: Tokens.anim.fadeIn; easing.type: Easing.OutCubic }
                }
                Rectangle {
                    id: varVolBar
                    width: parent.width * audioStat.volume / 100
                    height: parent.height
                    color: audioStat.muted ? Theme.bgElevated : Theme.accent
                    radius: Tokens.radius.xl
                    opacity: 0
                    Behavior on opacity {
                        NumberAnimation { duration: Tokens.anim.fadeIn; easing.type: Easing.OutCubic }
                    }
                    Behavior on color {
                        ColorAnimation { duration: Tokens.anim.fast; easing.type: Easing.OutCubic }
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }

        // ZONE 2 --- CPU + GPU
        GridLayout {
            columns: 3
            rows: 2
            rowSpacing: Tokens.spacing.xss
            columnSpacing: Tokens.columnSpacing
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: false

            Text {
                id: cpuLabel
                text: "CPU"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.type.label
                color: Theme.textSecondary
                opacity: 0
                Behavior on opacity {
                    NumberAnimation { duration: Tokens.anim.fadeIn; easing.type: Easing.OutCubic }
                }
            }

            Text {
                id: cpuPercent
                text: cpuStat.averageUsage >= 0 ? cpuStat.averageUsage + "%" : "--%"
                font.family: Theme.fontMono
                font.pixelSize: Tokens.type.label
                color: Theme.textPrimary
                opacity: 0
                Behavior on opacity {
                    NumberAnimation { duration: Tokens.anim.fadeIn; easing.type: Easing.OutCubic }
                }
            }

            Rectangle {
                id: constCpuBar
                Layout.preferredWidth: Tokens.usageBarWidth
                Layout.preferredHeight: Tokens.usageBarHeight
                color: Theme.bgElevated
                radius: Tokens.radius.xl
                opacity: 0
                Behavior on opacity {
                    NumberAnimation { duration: Tokens.anim.fadeIn; easing.type: Easing.OutCubic }
                }
                Rectangle {
                    id: varCpuBar
                    width: parent.width * Math.max(cpuStat.averageUsage, 0) * 0.01
                    height: parent.height
                    color: rightBar.__gradient__(Theme.stateSafe, Theme.stateCritical, Math.max(cpuStat.averageUsage, 0) / 100)
                    radius: Tokens.radius.xl
                    opacity: 0
                    Behavior on opacity {
                        NumberAnimation { duration: Tokens.anim.fadeIn; easing.type: Easing.OutCubic }
                    }
                }
            }

            Text {
                id: gpuLabel
                text: "GPU"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.type.label
                color: Theme.textSecondary
                opacity: 0
                Behavior on opacity {
                    NumberAnimation { duration: Tokens.anim.fadeIn; easing.type: Easing.OutCubic }
                }
            }

            Text {
                id: gpuPercent
                text: gpuStat.gpuUsage >= 0 ? gpuStat.gpuUsage + "%" : "--%"
                font.family: Theme.fontMono
                font.pixelSize: Tokens.type.label
                color: Theme.textPrimary
                opacity: 0
                Behavior on opacity {
                    NumberAnimation { duration: Tokens.anim.fadeIn; easing.type: Easing.OutCubic }
                }
            }

            Rectangle {
                id: constGpuBar
                implicitWidth: Tokens.usageBarWidth
                implicitHeight: Tokens.usageBarHeight
                color: Theme.bgElevated
                radius: Tokens.radius.xl
                opacity: 0
                Behavior on opacity {
                    NumberAnimation { duration: Tokens.anim.fadeIn; easing.type: Easing.OutCubic }
                }
                Rectangle {
                    id: varGpuBar
                    width: parent.width * Math.max(gpuStat.gpuUsage, 0) / 100
                    height: parent.height
                    color: rightBar.__gradient__(Theme.stateSafe, Theme.stateCritical, Math.max(gpuStat.gpuUsage, 0) / 100)
                    radius: Tokens.radius.xl
                    opacity: 0
                    Behavior on opacity {
                        NumberAnimation { duration: Tokens.anim.fadeIn; easing.type: Easing.OutCubic }
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }

        // ZONE 3 --- RAM
        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: Tokens.spacing.xss

            Text {
                id: ramLabel
                Layout.alignment: Qt.AlignHCenter
                text: "RAM"
                horizontalAlignment: Text.AlignHCenter
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.type.base
                color: Theme.textSecondary
                opacity: 0
                Behavior on opacity {
                    NumberAnimation { duration: Tokens.anim.fadeIn; easing.type: Easing.OutCubic }
                }
            }

            Text {
                id: ramValue
                Layout.alignment: Qt.AlignHCenter
                text: ramStat.usageGiB
                horizontalAlignment: Text.AlignHCenter
                font.family: Theme.fontMono
                font.pixelSize: Tokens.type.label
                color: Theme.textPrimary
                opacity: 0
                Behavior on opacity {
                    NumberAnimation { duration: Tokens.anim.fadeIn; easing.type: Easing.OutCubic }
                }
            }
        }

        Item { Layout.fillWidth: true }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (Globals.activePanel !== "") {
                Globals.lastPanel = Globals.activePanel
                Globals.activePanel = ""
            } else {
                Globals.activePanel = Globals.lastPanel
            }
        }
    }
}
