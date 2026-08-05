// ConsoleWidget.qml --- apps list (left) + edge controls (right): wifi/bt/settings/notifs
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../.."
import "../../utils"
import "../../edges/rightEdge"
import "../../edges/rightEdge/network"
import "../../edges/rightEdge/bluetooth"
import "../../edges/rightEdge/settings"
import "../../edges/rightEdge/notifications"
import "console"

Item {
    id: root
    clip: true

    property int selectedIndex: 0

    ConsoleModel { id: codex }

    function selectIndex(i) {
        if (i < 0 || i >= codex.codexModel.count)
            return
        selectedIndex = i
        if (appList.currentIndex !== i)
            appList.currentIndex = i
        appList.positionViewAtIndex(i, ListView.Contain)
    }

    function launchSelected() {
        const row = codex.codexModel.get(selectedIndex)
        if (!row)
            return
        Quickshell.execDetached(["bash", "-lc", row.execCmd])
    }

    function iconSource(name) {
        const p = Quickshell.iconPath(name, true)
        return p && p.length ? p : ""
    }

    function switchEdgePanel(panel) {
        Globals.activeEdgePanel = panel
        Globals.lastEdgePanel = panel
        Qt.callLater(root.grabEdgeFocus)
    }

    function grabListFocus() {
        appList.forceActiveFocus()
    }

    function grabEdgeFocus() {
        const panel = Globals.activeEdgePanel
        if (panel === "wifi")
            wifiPage.grabListFocus()
        else if (panel === "bluetooth")
            btPage.grabListFocus()
        else if (panel === "notifications")
            notifPage.grabListFocus()
        else
            edgeHost.forceActiveFocus()
    }

    function grabConsoleFocus() {
        // Prefer apps list; edge pages steal focus when their tab is used
        grabListFocus()
    }

    Component.onCompleted: {
        selectIndex(0)
        if (Globals.activeCenterPanel === "console")
            grabConsoleFocus()
    }

    Connections {
        target: Globals
        function onActiveCenterPanelChanged() {
            if (Globals.activeCenterPanel === "console")
                Qt.callLater(root.grabConsoleFocus)
        }
        function onActiveEdgePanelChanged() {
            if (Globals.activeCenterPanel === "console")
                Qt.callLater(root.grabEdgeFocus)
        }
    }

    focus: true
    Keys.forwardTo: [appList]
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.launchSelected()
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            root.selectIndex(root.selectedIndex - 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            root.selectIndex(root.selectedIndex + 1)
            event.accepted = true
        } else if (event.key === Qt.Key_1) {
            root.switchEdgePanel("wifi")
            event.accepted = true
        } else if (event.key === Qt.Key_2) {
            root.switchEdgePanel("bluetooth")
            event.accepted = true
        } else if (event.key === Qt.Key_3) {
            root.switchEdgePanel("settings")
            event.accepted = true
        } else if (event.key === Qt.Key_4) {
            root.switchEdgePanel("notifications")
            event.accepted = true
        }
    }

    RowLayout {
        id: mainRow
        anchors.fill: parent
        anchors.margins: Tokens.paddingH
        spacing: Tokens.spacingMd

        // -- LEFT: application list (fixed narrow column; never steal edge space) ---
        ColumnLayout {
            id: appsCol
            // ~1/3 of console; hard caps so ListView cannot expand the row
            Layout.fillWidth: false
            Layout.fillHeight: true
            Layout.preferredWidth: Math.round(Tokens.listPanelWidth * 1.7)
            Layout.minimumWidth: Tokens.listPanelWidth
            Layout.maximumWidth: Math.round(Tokens.centerSmallerWidth * 0.32)
            Layout.alignment: Qt.AlignTop
            spacing: Tokens.spacingXs

            Text {
                text: "APPS"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.accent
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 0
                Layout.minimumHeight: 0
                radius: Tokens.radiusMd
                color: Theme.bgSurface
                border.color: Theme.borderIdle
                border.width: Tokens.strokeWidth
                clip: true

                ListView {
                    id: appList
                    anchors.fill: parent
                    anchors.margins: Tokens.paddingH
                    clip: true
                    // Prevent implicit width from content blowing out the column
                    implicitWidth: 0
                    spacing: Tokens.spacingXss
                    model: codex.codexModel
                    currentIndex: root.selectedIndex
                    focus: true
                    activeFocusOnTab: true
                    keyNavigationEnabled: false
                    highlightFollowsCurrentItem: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick
                    interactive: contentHeight > height
                    ScrollBar.vertical: MonoScrollBar {}

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.launchSelected()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up) {
                            root.selectIndex(root.selectedIndex - 1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Down) {
                            root.selectIndex(root.selectedIndex + 1)
                            event.accepted = true
                        }
                    }

                    delegate: Rectangle {
                        width: Math.max(0, appList.width
                            - (appList.contentHeight > appList.height
                                ? Tokens.borderXs + Tokens.spacingXss + 2
                                : 0))
                        height: Tokens.statBoxHeight
                        radius: Tokens.radiusSm
                        color: index === root.selectedIndex ? Theme.bgElevated : "transparent"
                        border.color: index === root.selectedIndex ? Theme.borderActive : "transparent"
                        border.width: Tokens.strokeWidth

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Tokens.paddingH
                            spacing: Tokens.spacingXs

                            Image {
                                Layout.preferredWidth: Tokens.iconSizeLarge
                                Layout.preferredHeight: Tokens.iconSizeLarge
                                source: root.iconSource(model.icon)
                                sourceSize: Qt.size(Tokens.iconSizeLarge, Tokens.iconSizeLarge)
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                            }

                            Text {
                                Layout.fillWidth: true
                                text: model.title.toUpperCase()
                                font.family: Theme.fontDisplay
                                font.pixelSize: Tokens.fontSizeLabel
                                color: index === root.selectedIndex ? Theme.accent : Theme.textMuted
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectIndex(index)
                                appList.forceActiveFocus()
                            }
                            onDoubleClicked: {
                                root.selectIndex(index)
                                root.launchSelected()
                            }
                        }
                    }
                }
            }
        }

        // -- RIGHT: wifi / bluetooth / settings / notifications (takes remaining width) ---
        Item {
            id: edgeHost
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1   // stretch factor vs fixed apps col
            Layout.minimumWidth: 0
            Layout.minimumHeight: 0
            clip: true
            focus: true

            ColumnLayout {
                anchors.fill: parent
                spacing: Tokens.spacingSm

                EdgeTabs {
                    id: edgeTabs
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    Layout.maximumHeight: edgeTabs.implicitHeight
                    active: Globals.activeEdgePanel
                    onSwitched: (panel) => root.switchEdgePanel(panel)
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Tokens.strokeWidth
                    color: Theme.borderIdle
                    opacity: 0.5
                }

                StackLayout {
                    id: edgeStack
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 0
                    Layout.minimumHeight: 0
                    clip: true

                    currentIndex: {
                        const panels = ["wifi", "bluetooth", "settings", "notifications"]
                        const idx = panels.indexOf(Globals.activeEdgePanel)
                        return idx < 0 ? 0 : idx
                    }

                    NetworkFrontend {
                        id: wifiPage
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumWidth: 0
                        Layout.minimumHeight: 0
                    }

                    BluetoothFrontend {
                        id: btPage
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumWidth: 0
                        Layout.minimumHeight: 0
                    }

                    SettingsFrontend {
                        id: settingsPage
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumWidth: 0
                        Layout.minimumHeight: 0
                        onRequestClose: {
                            Globals.lastCenterPanel = Globals.activeCenterPanel
                            Globals.activeCenterPanel = ""
                        }
                    }

                    NotifFrontend {
                        id: notifPage
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumWidth: 0
                        Layout.minimumHeight: 0
                    }
                }
            }
        }
    }
}
