import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../../.."
import "../../../../utils"
import "."
Item { 
    id: ramFrontend

    implicitHeight:  Tokens.rightWidth
    implicitWidth:   Tokens.rightWidth 
    
    property int selectedProc: 0
    property var selectedProcData: (selectedProc >= 0 && selectedProc < ram.processes.count)
                                   ? ram.processes.get(selectedProc)
                                   : null

    RAMBackend {
        id: ram
    }

    function selectProc(i) {
        if (i < 0 || i >= ram.processes.count)
            return
        selectedProc = i
        if (procList.currentIndex !== i)
            procList.currentIndex = i
        procList.positionViewAtIndex(i, ListView.Contain)
    }

    function killSelected() {
        if (!selectedProcData)
            return
        ram.killProcess(selectedProcData.pid)
    }

    function haltSelected() {
        if (!selectedProcData)
            return
        ram.toggleHaltProcess(selectedProcData.pid)
    }

    function optimizeSelected() {
        if (!selectedProcData)
            return
        ram.optimizeProcess(selectedProcData.pid)
    }

    function launchRamTui() {
        if (!ram.ramTuiAvailable)
            return
        ram.launchRamTui()
    }

    function grabListFocus() {
        procList.forceActiveFocus()
    }

    Component.onCompleted: {
        if (Globals.activePanel === "ram")
            grabListFocus()
    }

    Connections {
        target: Globals
        function onActivePanelChanged() {
            if (Globals.activePanel === "ram")
                Qt.callLater(ramFrontend.grabListFocus)
        }
    }

    // Keep selection in range when process list refreshes
    Connections {
        target: ram.processes
        function onCountChanged() {
            if (ram.processes.count === 0) {
                selectedProc = 0
                return
            }
            if (selectedProc >= ram.processes.count)
                selectProc(ram.processes.count - 1)
        }
    }

    focus: true
    Keys.forwardTo: [procList]
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            ramFrontend.launchRamTui()
            event.accepted = true
        } else if (event.key === Qt.Key_K) {
            ramFrontend.killSelected()
            event.accepted = true
        } else if (event.key === Qt.Key_H) {
            ramFrontend.haltSelected()
            event.accepted = true
        } else if (event.key === Qt.Key_O) {
            ramFrontend.optimizeSelected()
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            ramFrontend.selectProc(ramFrontend.selectedProc - 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            ramFrontend.selectProc(ramFrontend.selectedProc + 1)
            event.accepted = true
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.paddingH
        spacing: Tokens.barMarginTop

        RowLayout {
            Text {
                id: ramLabel
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                text: "RAM Usage: "
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLarge
                color: Theme.accent
            }

            Text {
                id: ramTotalUsage
                Layout.fillWidth:      true
                Layout.alignment:      Qt.AlignHCenter
                horizontalAlignment:   Text.AlignHCenter
                text: (ram.ramInUse < 0 || ram.ramTotal < 0)
                    ? "-- / -- GB"
                    : ram.ramInUse + " / " + ram.ramTotal + " GB"
                font.family:    Theme.fontMono
                font.pixelSize: Tokens.fontSizeBase
                color:          Theme.accentWarm
            }
        }

        RowLayout {
            Layout.fillWidth:  true
            Layout.fillHeight: true
            spacing:           Tokens.spacingSm
            Rectangle {
                id: procListPanel
                Layout.preferredWidth: Tokens.listPanelWidth
                Layout.fillHeight: true
                color: Theme.bgSurface
                radius: Tokens.radiusLg                
                border.color: Theme.borderIdle
                border.width: Tokens.strokeWidth

                Text {
                    id: procListHeader
                    anchors.top:              parent.top
                    anchors.topMargin:        Tokens.spacingSm
                    anchors.horizontalCenter: parent.horizontalCenter
                    text:                     "PROCESSES"
                    font.family:              Theme.fontDisplay
                    font.pixelSize:           Tokens.fontSizeLabel
                    color:                    Theme.textMuted
                    font.letterSpacing:       Tokens.spacingXss
                }

                ListView {
                    id: procList
                    anchors.top:          procListHeader.bottom
                    anchors.topMargin:    Tokens.spacingXs 
                    anchors.right:        parent.right
                    anchors.rightMargin:  Tokens.spacingXs 
                    anchors.left:         parent.left
                    anchors.leftMargin:   Tokens.spacingXs 
                    anchors.bottom:       parent.bottom
                    anchors.bottomMargin: Tokens.spacingXs 
                    spacing:              Tokens.spacingXss
                    clip:                 true
                    boundsBehavior:       Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }
                    currentIndex:         ramFrontend.selectedProc
                    model:                ram.processes
                    focus:                true
                    activeFocusOnTab:     true
                    keyNavigationEnabled: false
                    highlightFollowsCurrentItem: true

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            ramFrontend.launchRamTui()
                            event.accepted = true
                        } else if (event.key === Qt.Key_K) {
                            ramFrontend.killSelected()
                            event.accepted = true
                        } else if (event.key === Qt.Key_H) {
                            ramFrontend.haltSelected()
                            event.accepted = true
                        } else if (event.key === Qt.Key_O) {
                            ramFrontend.optimizeSelected()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up) {
                            ramFrontend.selectProc(ramFrontend.selectedProc - 1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Down) {
                            ramFrontend.selectProc(ramFrontend.selectedProc + 1)
                            event.accepted = true
                        }
                    }

                    delegate: Item {
                        width:  procList.width
                        height: Tokens.actionBtnHeight

                        property int   pid:        model.pid
                        property bool  isSelected: index === ramFrontend.selectedProc
                        property color usageColor: model.ramMb > 1000 ? Theme.stateCritical
                                                 : model.ramMb > 500 ? Theme.stateWarning
                                                 : Theme.stateSafe

                        Rectangle {
                            anchors.fill: parent
                            color:        isSelected ? Qt.rgba(1, 0.27, 0, 0.18) : "transparent"
                            radius:       Tokens.radiusSm
                            border.color: isSelected ? Theme.accent : "transparent"
                            border.width: isSelected ? Tokens.borderXss : 0
                        }

                        Text {
                            id: procLabel
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left:           parent.left
                            anchors.leftMargin:     Tokens.spacingSm
                            text:                   "P" + model.idx
                            font.family:            Theme.fontDisplay
                            font.pixelSize:         Tokens.fontSizeSmall
                            color:                  isSelected ? Theme.accent : Theme.textMuted
                        }

                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left:           procLabel.right
                            anchors.leftMargin:     Tokens.spacingSm
                            anchors.right:          ramUsage.left
                            anchors.rightMargin:    Tokens.spacingXss
                            height:                 Tokens.usageBarHeight

                            Rectangle {
                                anchors.fill: parent
                                radius:       Tokens.radiusSm
                                color:        Theme.bgElevated
                                opacity:      Theme.opacityBar
                            }

                            Rectangle {
                                width:  Math.max(Tokens.borderXss, parent.width * (model.ramMb / (ram.ramTotal  * 1024)))
                                height: parent.height
                                radius: Tokens.radiusSm
                                color:  usageColor
                                Behavior on width { NumberAnimation { duration: Tokens.animFast } }
                            }
                        }

                        Text {
                            id: ramUsage
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right:          parent.right
                            anchors.rightMargin:    Tokens.spacingXs
                            text:                   model.ramMb === -1 ? "--" : model.ramMb
                            font.family:            Theme.fontMono
                            font.pixelSize:         Tokens.fontSizeTiny
                            color:                  usageColor
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                ramFrontend.selectProc(index)
                                procList.forceActiveFocus()
                            }
                        }
                    }
                }
            }
            ColumnLayout {
                id: procDataAndControls
                Layout.fillHeight: true
                Layout.fillWidth:  true
                Layout.margins: Tokens.paddingH
                spacing:         Tokens.spacingXs 
                Rectangle {
                    id: procDataBox
                    Layout.fillWidth:       true
                    Layout.fillHeight:      true
                    color:             Theme.bgSurface
                    radius:            Tokens.radiusLg
                    border.color:      Theme.borderIdle
                    border.width:      Tokens.strokeWidth

                    ColumnLayout {
                        anchors.fill:    parent
                        anchors.margins:    Tokens.spacingSm
                        spacing:            Tokens.spacingXss
                        visible: ramFrontend.selectedProcData !== null
                        RowLayout{
                            spacing: Tokens.spacingXss
                            Layout.alignment: Qt.AlignLeft
                            Text {
                                Layout.alignment: Qt.AlignLeft
                                text:           "Process Name: " 
                                font.family:    Theme.fontDisplay
                                font.pixelSize: Tokens.fontSizeTiny
                                color:          Theme.textMuted
                            }
                            
                            Text {
                                Layout.alignment: Qt.AlignLeft
                                text:   ramFrontend.selectedProcData?.name   ?? "---"
                                font.family:    Theme.fontMono
                                font.pixelSize: Tokens.fontSizeTiny
                                color:          Theme.textSecondary
                            }
                        }
                        RowLayout{
                            spacing: Tokens.spacingXss
                            Layout.alignment: Qt.AlignLeft
                            Text {
                                Layout.alignment: Qt.AlignLeft
                                text:           "Process ID: " 
                                font.family:    Theme.fontDisplay
                                font.pixelSize: Tokens.fontSizeTiny
                                color:          Theme.textMuted
                            }
                            
                            Text {
                                Layout.alignment: Qt.AlignLeft
                                text:           ramFrontend.selectedProcData?.pid    ?? "---"
                                font.family:    Theme.fontMono
                                font.pixelSize: Tokens.fontSizeTiny
                                color:          Theme.textSecondary
                            }
                        }

                        RowLayout{
                            spacing: Tokens.spacingXss
                            Layout.alignment: Qt.AlignLeft
                            Text {
                                Layout.alignment: Qt.AlignLeft
                                text:           "RAM Usage: "
                                font.family:    Theme.fontDisplay
                                font.pixelSize: Tokens.fontSizeTiny
                                color:          Theme.textMuted
                            }
                            
                            Text {
                                text:           (ramFrontend.selectedProcData?.ramMb ?? "---") + " MB"
                                font.family:    Theme.fontMono
                                font.pixelSize: Tokens.fontSizeTiny
                                color:          Theme.textSecondary
                            }
                        }

                        RowLayout{
                            spacing: Tokens.spacingXss
                            Layout.alignment: Qt.AlignLeft
                            Text {
                                Layout.alignment: Qt.AlignLeft
                                text:           "CPU Usage: "
                                font.family:    Theme.fontDisplay
                                font.pixelSize: Tokens.fontSizeTiny
                                color:          Theme.textMuted
                            }
                            
                            Text {
                                text:           (ramFrontend.selectedProcData?.cpu ?? "---") + " %"
                                font.family:    Theme.fontMono
                                font.pixelSize: Tokens.fontSizeTiny
                                color:          Theme.textSecondary
                            }
                        }

                        RowLayout{
                            spacing: Tokens.spacingXss
                            Layout.alignment: Qt.AlignLeft
                            Text {
                                Layout.alignment: Qt.AlignLeft
                                text:           "Uptime: "
                                font.family:    Theme.fontDisplay
                                font.pixelSize: Tokens.fontSizeTiny
                                color:          Theme.textMuted
                            }
                            
                            Text {
                                text:           (ramFrontend.selectedProcData?.uptime ?? "---") + " s"
                                font.family:    Theme.fontMono
                                font.pixelSize: Tokens.fontSizeTiny
                                color:          Theme.textSecondary
                            }
                        }

                        RowLayout{
                            spacing: Tokens.spacingXss
                            Layout.alignment: Qt.AlignLeft
                            Text {
                                Layout.alignment: Qt.AlignLeft
                                text:           "Threads: "
                                font.family:    Theme.fontDisplay
                                font.pixelSize: Tokens.fontSizeTiny
                                color:          Theme.textMuted
                            }

                            Text {
                                text:           ramFrontend.selectedProcData?.threads ?? "---"
                                font.family:    Theme.fontMono
                                font.pixelSize: Tokens.fontSizeTiny
                                color:          Theme.textSecondary
                            }
                        }

                        RowLayout{
                            spacing: Tokens.spacingXss
                            Layout.alignment: Qt.AlignLeft
                                
                            Text {
                                Layout.alignment: Qt.AlignLeft
                                text:           "State: "
                                font.family:    Theme.fontDisplay
                                font.pixelSize: Tokens.fontSizeTiny
                                color:          Theme.textMuted
                            }

                            Text {
                                text: ramFrontend.selectedProcData?.stateDesc ?? "---"
                                font.family:    Theme.fontMono
                                font.pixelSize: Tokens.fontSizeTiny
                                color:          Theme.textSecondary
                            }
                        }

                        RowLayout{
                            spacing: Tokens.spacingXss
                            Layout.alignment: Qt.AlignLeft
                            Text {
                                Layout.alignment: Qt.AlignLeft
                                text:           "User: "
                                font.family:    Theme.fontDisplay
                                font.pixelSize: Tokens.fontSizeTiny
                                color:          Theme.textMuted
                            }

                            Text {
                                text:           ramFrontend.selectedProcData?.user ?? "---"
                                font.family:    Theme.fontMono
                                font.pixelSize: Tokens.fontSizeTiny
                                color:          Theme.textSecondary
                            }
                        }
                    }   
                }

                Item {
                    id: killProcBtn
                    Layout.fillWidth:       true
                    Layout.preferredHeight: Tokens.actionBtnHeight

                    property color glowColor: Theme.stateCritical
                    property bool  isHovered: killProcMouse.containsMouse
                    property bool  isPressed: killProcMouse.pressed

                    // Soft glow --- three stacked, widening, fading rectangles behind the button.
                    Rectangle {
                        anchors.fill:    parent
                        anchors.margins: -Tokens.spacingMd 
                        radius:          Tokens.radiusLg
                        color:           "transparent"
                        border.width:    Tokens.borderXss
                        border.color:    Qt.rgba(killProcBtn.glowColor.r, killProcBtn.glowColor.g, killProcBtn.glowColor.b, killProcBtn.isHovered ? 0.10 : 0)
                        Behavior on border.color { ColorAnimation { duration: Tokens.animMedium } }
                    }
                    Rectangle {
                        anchors.fill:    parent
                        anchors.margins: -Tokens.spacingSm
                        radius:          Tokens.radiusXl
                        color:           "transparent"
                        border.width:    Tokens.borderXss
                        border.color:    Qt.rgba(killProcBtn.glowColor.r, killProcBtn.glowColor.g, killProcBtn.glowColor.b, killProcBtn.isHovered ? 0.22 : 0)
                        Behavior on border.color { ColorAnimation { duration: Tokens.animMedium } }
                    }
                    Rectangle {
                        anchors.fill:    parent
                        anchors.margins: -Tokens.spacingXss 
                        radius:          Tokens.radiusMd
                        color:           "transparent"
                        border.width:    Tokens.borderXss
                        border.color:    Qt.rgba(killProcBtn.glowColor.r, killProcBtn.glowColor.g, killProcBtn.glowColor.b, killProcBtn.isHovered ? 0.4 : 0)
                        Behavior on border.color { ColorAnimation { duration: Tokens.animMedium } }
                    }

                    Rectangle {
                        id: killProcRect
                        anchors.fill: parent
                        color:        Theme.bgSurface
                        radius:       Tokens.radiusLg
                        border.color: killProcBtn.isHovered ? killProcBtn.glowColor : Theme.borderIdle
                        border.width: killProcBtn.isHovered ? Tokens.strokeWidthActive : Tokens.strokeWidth
                        opacity:      ramFrontend.selectedProcData !== null ? 1.0 : Theme.opacityMuted
                        scale:        killProcBtn.isPressed ? Theme.opacityPanel : 1.0

                        Behavior on scale       { NumberAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic } }
                        Behavior on border.color { ColorAnimation { duration: Tokens.animMedium } }

                        Text {
                            anchors.centerIn:   parent
                            text:               "Kill Process"
                            font.family:        Theme.fontDisplay
                            font.pixelSize:     Tokens.fontSizeSmall
                            color:              killProcBtn.isHovered ? killProcBtn.glowColor : Theme.textMuted
                            Behavior on color { ColorAnimation { duration: Tokens.animMedium } }
                        }
                    }

                    MouseArea {
                        id: killProcMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled:      ramFrontend.selectedProcData !== null
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    ramFrontend.killSelected()
                    }
                }

                Item {
                    id: haltProcBtn
                    Layout.fillWidth:       true
                    Layout.preferredHeight: Tokens.actionBtnHeight

                    property color glowColor: Theme.stateWarning
                    property bool  isHovered: haltProcMouse.containsMouse
                    property bool  isPressed: haltProcMouse.pressed
                    property bool  isHalted:  ramFrontend.selectedProcData !== null
                                               && ram.haltedPids[ramFrontend.selectedProcData.pid] === true

                    Rectangle {
                        anchors.fill:    parent
                        anchors.margins: -Tokens.spacingMd
                        radius:          Tokens.radiusLg
                        color:           "transparent"
                        border.width:    Tokens.borderXss
                        border.color:    Qt.rgba(haltProcBtn.glowColor.r, haltProcBtn.glowColor.g, haltProcBtn.glowColor.b, haltProcBtn.isHovered ? 0.10 : 0)
                        Behavior on border.color { ColorAnimation { duration: Tokens.animMedium } }
                    }
                    Rectangle {
                        anchors.fill:    parent
                        anchors.margins: -Tokens.spacingSm
                        radius:          Tokens.radiusXl
                        color:           "transparent"
                        border.width:    Tokens.borderXs
                        border.color:    Qt.rgba(haltProcBtn.glowColor.r, haltProcBtn.glowColor.g, haltProcBtn.glowColor.b, haltProcBtn.isHovered ? 0.22 : 0)
                        Behavior on border.color { ColorAnimation { duration: Tokens.animMedium } }
                    }
                    Rectangle {
                        anchors.fill:    parent
                        anchors.margins: -Tokens.spacingXss
                        radius:          Tokens.radiusXl
                        color:           "transparent"
                        border.width:    Tokens.borderXss
                        border.color:    Qt.rgba(haltProcBtn.glowColor.r, haltProcBtn.glowColor.g, haltProcBtn.glowColor.b, haltProcBtn.isHovered ? 0.4 : 0)
                        Behavior on border.color { ColorAnimation { duration: Tokens.animMedium } }
                    }

                    Rectangle {
                        id: haltProcRect
                        anchors.fill: parent
                        color:        Theme.bgSurface
                        radius:       Tokens.radiusLg
                        border.color: haltProcBtn.isHovered ? haltProcBtn.glowColor : Theme.borderIdle
                        border.width: haltProcBtn.isHovered ? Tokens.strokeWidthActive : Tokens.strokeWidth
                        opacity:      ramFrontend.selectedProcData !== null ? 1.0 : 0.4
                        scale:        haltProcBtn.isPressed ? 0.94 : 1.0

                        Behavior on scale        { NumberAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic } }
                        Behavior on border.color { ColorAnimation { duration: Tokens.animMedium } }

                        AnimatedText {
                            id: haltProcAnimText
                            anchors.fill: parent
                            mode:         AnimatedText.Mode.Scramble
                            duration:     Tokens.animMedium

                            Text {
                                anchors.fill:       parent
                                text:               haltProcAnimText.displayedText
                                font.family:        Theme.fontDisplay
                                font.pixelSize:      Tokens.fontSizeSmall
                                color:              haltProcBtn.isHovered ? haltProcBtn.glowColor : Theme.textMuted
                                opacity:            haltProcAnimText.displayOpacity
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment:   Text.AlignVCenter
                                Behavior on color { ColorAnimation { duration: Tokens.animMedium } }
                            }

                            Component.onCompleted: {
                                displayedText = haltProcBtn.isHalted ? "Resume Process" : "Halt Process"
                                targetText    = displayedText
                            }
                        }

                        Connections {
                            target: haltProcBtn
                            function onIsHaltedChanged() {
                                haltProcAnimText.transitionTo(haltProcBtn.isHalted ? "Resume Process" : "Halt Process")
                            }
                        }
                    }

                    MouseArea {
                        id: haltProcMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled:      ramFrontend.selectedProcData !== null
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    ramFrontend.haltSelected()
                    }
                }

                Item {
                    id: optimizeProcBtn
                    Layout.fillWidth:       true
                    Layout.preferredHeight: Tokens.actionBtnHeight

                    property color glowColor: Theme.accent
                    property bool  isHovered: optimizeProcMouse.containsMouse
                    property bool  isPressed: optimizeProcMouse.pressed

                    Rectangle {
                        anchors.fill:    parent
                        anchors.margins: -Tokens.spacingMd
                        radius:          Tokens.radiusLg
                        color:           "transparent"
                        border.width:    Tokens.borderXss
                        border.color:    Qt.rgba(optimizeProcBtn.glowColor.r, optimizeProcBtn.glowColor.g, optimizeProcBtn.glowColor.b, optimizeProcBtn.isHovered ? 0.10 : 0)
                        Behavior on border.color { ColorAnimation { duration: Tokens.animMedium } }
                    }
                    Rectangle {
                        anchors.fill:    parent
                        anchors.margins: -Tokens.spacingSm
                        radius:          Tokens.radiusXl
                        color:           "transparent"
                        border.width:    Tokens.borderXss
                        border.color:    Qt.rgba(optimizeProcBtn.glowColor.r, optimizeProcBtn.glowColor.g, optimizeProcBtn.glowColor.b, optimizeProcBtn.isHovered ? 0.22 : 0)
                        Behavior on border.color { ColorAnimation { duration: Tokens.animMedium } }
                    }
                    Rectangle {
                        anchors.fill:    parent
                        anchors.margins: -Tokens.spacingXss
                        radius:          Tokens.radiusMd
                        color:           "transparent"
                        border.width:    Tokens.borderXss
                        border.color:    Qt.rgba(optimizeProcBtn.glowColor.r, optimizeProcBtn.glowColor.g, optimizeProcBtn.glowColor.b, optimizeProcBtn.isHovered ? 0.4 : 0)
                        Behavior on border.color { ColorAnimation { duration: Tokens.animMedium } }
                    }

                    Rectangle {
                        id: optimizeProcRect
                        anchors.fill: parent
                        color:        Theme.bgSurface
                        radius:       Tokens.radiusLg
                        border.color: optimizeProcBtn.isHovered ? optimizeProcBtn.glowColor : Theme.borderIdle
                        border.width: optimizeProcBtn.isHovered ? Tokens.strokeWidthActive : Tokens.strokeWidth
                        opacity:      ramFrontend.selectedProcData !== null ? 1.0 : 0.4
                        scale:        optimizeProcBtn.isPressed ? 0.94 : 1.0

                        Behavior on scale        { NumberAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic } }
                        Behavior on border.color { ColorAnimation { duration: Tokens.animMedium } }

                        Text {
                            anchors.centerIn:   parent
                            text:               "Optimize Process"
                            font.family:        Theme.fontDisplay
                            font.pixelSize:     Tokens.fontSizeSmall
                            color:              optimizeProcBtn.isHovered ? optimizeProcBtn.glowColor : Theme.textMuted
                            Behavior on color { ColorAnimation { duration: Tokens.animMedium } }
                        }
                    }

                    MouseArea {
                        id: optimizeProcMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled:      ramFrontend.selectedProcData !== null
                        cursorShape:  Qt.PointingHandCursor
                        onClicked:    ramFrontend.optimizeSelected()
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "ARROWS move * ENTER ram-man * K kill * H halt * O optimize"
            font.family: Theme.fontMono
            font.pixelSize: Tokens.fontSizeTiny
            color: Theme.textDim
            horizontalAlignment: Text.AlignHCenter
        }

        Item {
            id: ramTuiBtn
            Layout.fillWidth:       true
            Layout.preferredHeight: Tokens.centerCollapsedHeight

            property color glowColor: Theme.accentSoft
            property bool  isHovered: ramTuiMouse.containsMouse
            property bool  isPressed: ramTuiMouse.pressed
            property bool  isAvailable: ram.ramTuiAvailable

            Rectangle {
                anchors.fill:    parent
                anchors.margins: -Tokens.spacingMd
                radius:          Tokens.radiusXl
                color:           "transparent"
                border.width:    Tokens.borderMd
                border.color:    Qt.rgba(ramTuiBtn.glowColor.r, ramTuiBtn.glowColor.g, ramTuiBtn.glowColor.b, ramTuiBtn.isHovered ? 0.10 : 0)
                Behavior on border.color { ColorAnimation { duration: Tokens.animMedium } }
            }
            Rectangle {
                anchors.fill:    parent
                anchors.margins: -Tokens.spacingSm
                radius:          Tokens.radiusXl
                color:           "transparent"
                border.width:    Tokens.borderXss
                border.color:    Qt.rgba(ramTuiBtn.glowColor.r, ramTuiBtn.glowColor.g, ramTuiBtn.glowColor.b, ramTuiBtn.isHovered ? 0.22 : 0)
                Behavior on border.color { ColorAnimation { duration: Tokens.animMedium } }
            }
            Rectangle {
                anchors.fill:    parent
                anchors.margins: -Tokens.spacingXss
                radius:          Tokens.radiusLg
                color:           "transparent"
                border.width:    Tokens.borderXss
                border.color:    Qt.rgba(ramTuiBtn.glowColor.r, ramTuiBtn.glowColor.g, ramTuiBtn.glowColor.b, ramTuiBtn.isHovered ? 0.4 : 0)
                Behavior on border.color { ColorAnimation { duration: Tokens.animMedium } }
            }

            Rectangle {
                id: ramTuiRect
                anchors.fill: parent
                color:        Theme.bgSurface
                radius:       Tokens.radiusLg
                border.color: ramTuiBtn.isHovered ? ramTuiBtn.glowColor : Theme.borderIdle
                border.width: ramTuiBtn.isHovered ? Tokens.strokeWidthActive : Tokens.strokeWidth
                opacity:      ramTuiBtn.isAvailable ? 1.0 : Theme.opacityMuted
                scale:        ramTuiBtn.isPressed ? Theme.opacityPanel : 1.0

                Behavior on scale        { NumberAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic } }
                Behavior on border.color { ColorAnimation { duration: Tokens.animMedium } }

                Text {
                    anchors.centerIn:   parent
                    text:               ramTuiBtn.isAvailable ? "Launch RAM Manager" : "RAM Manager TUI Not Found"
                    font.family:        Theme.fontDisplay
                    font.pixelSize:     Tokens.fontSizeSmall
                    color:              ramTuiBtn.isHovered ? ramTuiBtn.glowColor : Theme.textMuted
                    Behavior on color { ColorAnimation { duration: Tokens.animMedium } }
                }
            }

            MouseArea {
                id: ramTuiMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled:      ramTuiBtn.isAvailable
                cursorShape:  Qt.PointingHandCursor
                onClicked:    ramFrontend.launchRamTui()
            }
        }
    }
}