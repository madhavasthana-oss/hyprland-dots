import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.DBusMenu
import QtQuick
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects
import "../utils"
import ".."
import "../widgets/rightBarWidgets/power"
import "../widgets/rightBarWidgets/audio"
import "../widgets/rightBarWidgets/system/CPU"
import "../widgets/rightBarWidgets/system/GPU"
import "../widgets/rightBarWidgets/system/RAM"

Item {
    id: rightBar
    width: Tokens.rightWidth
    height: Tokens.rightHeight

    // ---
    //  GRADIENT HELPER
    // ---
    // Blends from color1 -> color2 as alpha goes 0 -> 1.
    // Callers must pass alpha such that alpha=1 means "critical".

    function __gradient__(color1, color2, alpha) {
        color1 = color1.toString();
        color2 = color2.toString();
        let r1 = parseInt(color1.slice(1, 3), 16);
        let g1 = parseInt(color1.slice(3, 5), 16);
        let b1 = parseInt(color1.slice(5, 7), 16);
        let r2 = parseInt(color2.slice(1, 3), 16);
        let g2 = parseInt(color2.slice(3, 5), 16);
        let b2 = parseInt(color2.slice(5, 7), 16);
        return "#" + Math.round((1 - alpha) * r1 + alpha * r2).toString(16).padStart(2, "0") + Math.round((1 - alpha) * g1 + alpha * g2).toString(16).padStart(2, "0") + Math.round((1 - alpha) * b1 + alpha * b2).toString(16).padStart(2, "0");
    }

    // ---
    //  GiB FORMAT HELPER
    // ---
    // RAMBackend already computes ramInUse / ramTotal in GiB
    // (kB from /proc/meminfo divided by 1024**2), so we just format here.

    function __fmtGiB__(value) {
        return Number(value).toFixed(2);
    }



    // ---
    //  STAT LOADERS
    // ---

    BATStats {
        id: batStat
        visible: false
        anchors.top: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        onReady: {
            batLabel.opacity = 1;
            batPercent.opacity = 1;
            constBatBar.opacity = 1;
            varBatBar.opacity = 1;
        }
    }

    Volume {
        id: audioStat
        visible: false
        anchors.top: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        // Show chrome on first ready *and* on subsequent volume events
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
            // If sink drops (PW reconfigure), dim until back
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
                return -1;
            let sum = 0;
            let counted = 0;
            for (let i = 0; i < cores.count; i++) {
                let u = cores.get(i).usage;
                if (u !== -1 && u !== undefined) {
                    sum += u;
                    counted++;
                }
            }
            return counted > 0 ? Math.round(sum / counted) : -1;
        }

        onReadyChanged: {
            if (ready) {
                cpuLabel.opacity = 1;
                cpuPercent.opacity = 1;
                constCpuBar.opacity = 1;
                varCpuBar.opacity = 1;
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
                gpuLabel.opacity = 1;
                gpuPercent.opacity = 1;
                constGpuBar.opacity = 1;
                varGpuBar.opacity = 1;
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
                return "--/--";
            return rightBar.__fmtGiB__(ramInUse) + "/" + rightBar.__fmtGiB__(ramTotal) + " GiB";
        }

        // isReady is a plain property on RAMBackend, not a signal ---
        // same rule: onIsReadyChanged, not onIsReadyChanged.
        onIsReadyChanged: {
            if (isReady) {
                ramLabel.opacity = 1;
                ramValue.opacity = 1;
            }
        }
    }

    //  SHAPE
    SideRect {
        anchors.fill: parent
        barWidth: Tokens.rightWidth
        barHeight: Tokens.rightHeight
        radius: Tokens.radiusMd
        alertActive: false
    }

    //  CONTENT ROW
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Tokens.paddingH + Tokens.spacingXs
        anchors.rightMargin: Tokens.paddingH + Tokens.spacingXs
        spacing: Tokens.spacingXs

        Item {
            Layout.fillWidth: true
        }
        //  ZONE 1 --- Battery + Volume
        GridLayout {
            columns: 3 
            rows: 2
            rowSpacing: Tokens.spacingXss
            columnSpacing: Tokens.columnSpacing
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: false

            // BAT label
            Text {
                id: batLabel
                text: "BAT"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.textSecondary
                opacity: 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: Tokens.animFadeIn
                        easing.type: Easing.OutCubic
                    }
                }
            }

            // BAT percentage
            Text {
                id: batPercent
                text: batStat.percentage + "%"
                font.family: Theme.fontMono
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.textPrimary
                opacity: 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: Tokens.animFadeIn
                        easing.type: Easing.OutCubic
                    }
                }
            }

            // BAT bar
            Rectangle {
                id: constBatBar
                Layout.preferredWidth: Tokens.usageBarWidth
                Layout.preferredHeight: Tokens.usageBarHeight
                color: Theme.bgElevated
                radius: Tokens.radiusXl
                opacity: 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: Tokens.animFadeIn
                        easing.type: Easing.OutCubic
                    }
                }
                Rectangle {
                    id: varBatBar
                    width: parent.width * batStat.percentage * 0.01
                    height: parent.height
                    // Low battery = critical: invert percentage before feeding gradient.
                    color: rightBar.__gradient__(Theme.stateSafe, Theme.stateCritical, 1.00 - (batStat.percentage / 100))
                    radius: Tokens.radiusXl
                    opacity: 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Tokens.animFadeIn
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // VOL label
            Text {
                id: volLabel
                text: "VOL"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.textSecondary
                opacity: 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: Tokens.animFadeIn
                        easing.type: Easing.OutCubic
                    }
                }
            }

            // VOL percentage
            Text {
                id: volPercent
                text: audioStat.muted ? "M" : audioStat.volume + "%"
                font.family: Theme.fontMono
                font.pixelSize: Tokens.fontSizeLabel
                color: audioStat.muted ? Theme.textSecondary : Theme.textPrimary
                opacity: 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: Tokens.animFadeIn
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: Tokens.animFast
                        easing.type: Easing.OutCubic
                    }
                }
            }

            // VOL bar
            Rectangle {
                id: constVolBar
                implicitWidth: Tokens.usageBarWidth
                implicitHeight: Tokens.usageBarHeight
                color: Theme.bgElevated
                radius: Tokens.radiusXl
                opacity: 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: Tokens.animFadeIn
                        easing.type: Easing.OutCubic
                    }
                }
                Rectangle {
                    id: varVolBar
                    width: parent.width * audioStat.volume / 100
                    height: parent.height
                    color: audioStat.muted ? Theme.bgElevated : Theme.accent
                    radius: Tokens.radiusXl
                    opacity: 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Tokens.animFadeIn
                            easing.type: Easing.OutCubic
                        }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: Tokens.animFast
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }

        //  ZONE 2 --- CPU + GPU (bar style, matches BAT/VOL)
        GridLayout {
            columns: 3
            rows: 2
            rowSpacing: Tokens.spacingXss
            columnSpacing: Tokens.columnSpacing
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: false

            // CPU label
            Text {
                id: cpuLabel
                text: "CPU"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.textSecondary
                opacity: 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: Tokens.animFadeIn
                        easing.type: Easing.OutCubic
                    }
                }
            }

            // CPU percentage
            Text {
                id: cpuPercent
                text: cpuStat.averageUsage >= 0 ? cpuStat.averageUsage + "%" : "--%"
                font.family: Theme.fontMono
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.textPrimary
                opacity: 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: Tokens.animFadeIn
                        easing.type: Easing.OutCubic
                    }
                }
            }

            // CPU bar
            Rectangle {
                id: constCpuBar
                Layout.preferredWidth: Tokens.usageBarWidth
                Layout.preferredHeight: Tokens.usageBarHeight
                color: Theme.bgElevated
                radius: Tokens.radiusXl
                opacity: 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: Tokens.animFadeIn
                        easing.type: Easing.OutCubic
                    }
                }
                Rectangle {
                    id: varCpuBar
                    width: parent.width * Math.max(cpuStat.averageUsage, 0) * 0.01
                    height: parent.height
                    // High usage = critical: feed percentage directly, no inversion.
                    color: rightBar.__gradient__(Theme.stateSafe, Theme.stateCritical, Math.max(cpuStat.averageUsage, 0) / 100)
                    radius: Tokens.radiusXl
                    opacity: 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Tokens.animFadeIn
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // GPU label
            Text {
                id: gpuLabel
                text: "GPU"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.textSecondary
                opacity: 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: Tokens.animFadeIn
                        easing.type: Easing.OutCubic
                    }
                }
            }

            // GPU percentage
            Text {
                id: gpuPercent
                text: gpuStat.gpuUsage >= 0 ? gpuStat.gpuUsage + "%" : "--%"
                font.family: Theme.fontMono
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.textPrimary
                opacity: 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: Tokens.animFadeIn
                        easing.type: Easing.OutCubic
                    }
                }
            }

            // GPU bar
            Rectangle {
                id: constGpuBar
                implicitWidth: Tokens.usageBarWidth
                implicitHeight: Tokens.usageBarHeight
                color: Theme.bgElevated
                radius: Tokens.radiusXl
                opacity: 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: Tokens.animFadeIn
                        easing.type: Easing.OutCubic
                    }
                }
                Rectangle {
                    id: varGpuBar
                    width: parent.width * Math.max(gpuStat.gpuUsage, 0) / 100
                    height: parent.height
                    // High usage = critical: feed percentage directly, no inversion.
                    color: rightBar.__gradient__(Theme.stateSafe, Theme.stateCritical, Math.max(gpuStat.gpuUsage, 0) / 100)
                    radius: Tokens.radiusXl
                    opacity: 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Tokens.animFadeIn
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }

        //  ZONE 3 --- RAM
        ColumnLayout {
            id: sysGrid
            Layout.alignment: Qt.AlignVCenter
            spacing: Tokens.spacingXss
            // Row 1 --- labels
            Text {
                id: ramLabel
                Layout.alignment: Qt.AlignHCenter
                text: "RAM"
                horizontalAlignment: Text.AlignHCenter
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeBase
                color: Theme.textSecondary
                opacity: 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: Tokens.animFadeIn
                        easing.type: Easing.OutCubic
                    }
                }
            }

            // Row 2 --- live values
            Text {
                id: ramValue
                Layout.alignment: Qt.AlignHCenter
                text: ramStat.usageGiB
                horizontalAlignment: Text.AlignHCenter
                font.family: Theme.fontMono
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.textPrimary
                opacity: 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: Tokens.animFadeIn
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        // Spacer matching the sibling power button so RAM sits next to it
        Item {
            Layout.preferredWidth: powerBtn.width
            Layout.preferredHeight: 1
        }
    }

    Item {
        id: powerBtn
        z: 3
        anchors.right: parent.right
        anchors.rightMargin: Tokens.paddingH + Tokens.spacingXs
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Tokens.workspaceBarIconSize + Tokens.spacingSm

        readonly property bool active: Globals.powerMenuOpen
        readonly property bool hovered: powerMouse.containsMouse

        Rectangle {
            anchors.centerIn: parent
            width: Tokens.workspaceBarIconSize + (powerBtn.hovered || powerBtn.active ? Tokens.spacingXs : 0)
            height: width
            radius: Tokens.radiusSm
            color: powerBtn.active
                ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.16)
                : (powerBtn.hovered ? Theme.bgElevated : "transparent")
            border.width: powerBtn.active ? Tokens.strokeWidth : 0
            border.color: powerBtn.active
                ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.45)
                : "transparent"

            Behavior on color {
                ColorAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
            }
            Behavior on width {
                NumberAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
            }
        }

        Image {
            id: powerGlyph
            anchors.centerIn: parent
            width: Tokens.iconSizeLarge + Tokens.spacingXs
            height: Tokens.iconSizeLarge + Tokens.spacingXs
            source: Theme.iconPoweroff
            sourceSize: Qt.size(width * 2, height * 2)
            fillMode: Image.PreserveAspectFit
            smooth: true
            visible: false
            asynchronous: true
        }

        ColorOverlay {
            anchors.fill: powerGlyph
            source: powerGlyph
            color: powerBtn.active
                ? Theme.accent
                : (powerBtn.hovered ? Theme.textPrimary : Theme.textMuted)

            Behavior on color {
                ColorAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
            }
        }

        MouseArea {
            id: powerMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: (mouse) => {
                Globals.togglePowerMenu()
                mouse.accepted = true
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        anchors.rightMargin: powerBtn.width + Tokens.paddingH + Tokens.spacingXs
        z: 1

        onClicked: {
            if (Globals.powerMenuOpen)
                return
            if (Globals.activePanel !== "") {
                Globals.lastPanel = Globals.activePanel;
                Globals.activePanel = "";
            } else
                Globals.activePanel = Globals.lastPanel;
        }
    }
}
