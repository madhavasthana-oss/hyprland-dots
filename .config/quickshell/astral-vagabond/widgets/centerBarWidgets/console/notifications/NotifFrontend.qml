// NotifFrontend.qml --- notification inbox + silent/dnd (console)
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../../.."
import "../../../../utils"
import "."

Item {
    id: root
    clip: true

    property int selectedIndex: 0

    NotifBackend { id: backend }

    function selectIndex(i) {
        if (i < 0 || i >= backend.notifications.count)
            return
        selectedIndex = i
        if (list.currentIndex !== i)
            list.currentIndex = i
        list.positionViewAtIndex(i, ListView.Contain)
    }

    function dismissSelected() {
        if (selectedIndex < 0 || selectedIndex >= backend.notifications.count)
            return
        const row = backend.notifications.get(selectedIndex)
        if (!row)
            return
        backend.dismissId(row.notifId)
    }

    function grabListFocus() {
        list.forceActiveFocus()
    }

    Component.onCompleted: {
        if (Globals.activeEdgePanel === "notifications")
            grabListFocus()
    }

    Connections {
        target: Globals
        function onActiveEdgePanelChanged() {
            if (Globals.activeEdgePanel === "notifications")
                Qt.callLater(root.grabListFocus)
        }
    }

    Connections {
        target: backend.notifications
        function onCountChanged() {
            if (backend.notifications.count === 0) {
                selectedIndex = 0
                return
            }
            if (selectedIndex >= backend.notifications.count)
                selectIndex(backend.notifications.count - 1)
        }
    }

    focus: true
    Keys.forwardTo: [list]
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                || event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace) {
            root.dismissSelected()
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            root.selectIndex(root.selectedIndex - 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            root.selectIndex(root.selectedIndex + 1)
            event.accepted = true
        } else if (event.key === Qt.Key_C) {
            backend.dismissAll()
            event.accepted = true
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Tokens.spacingXs

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacingXs

            Text {
                text: "NOTIFICATIONS"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.accent
            }

            Item { Layout.fillWidth: true }

            // SILENT
            Rectangle {
                Layout.preferredHeight: Tokens.listRowHeight
                Layout.preferredWidth: silentLbl.implicitWidth + 2 * Tokens.paddingH
                radius: Tokens.radiusSm
                color: backend.silent ? Theme.bgElevated : Theme.bgSurface
                border.color: backend.silent ? Theme.borderActive : Theme.borderIdle
                border.width: Tokens.strokeWidth
                Text {
                    id: silentLbl
                    anchors.centerIn: parent
                    text: "SILENT"
                    font.family: Theme.fontDisplay
                    font.pixelSize: Tokens.fontSizeLabel
                    color: backend.silent ? Theme.accent : Theme.textDim
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: backend.toggleSilent()
                }
            }

            // DND
            Rectangle {
                Layout.preferredHeight: Tokens.listRowHeight
                Layout.preferredWidth: dndLbl.implicitWidth + 2 * Tokens.paddingH
                radius: Tokens.radiusSm
                color: backend.dnd ? Theme.bgElevated : Theme.bgSurface
                border.color: backend.dnd ? Theme.stateCritical : Theme.borderIdle
                border.width: Tokens.strokeWidth
                Text {
                    id: dndLbl
                    anchors.centerIn: parent
                    text: "DND"
                    font.family: Theme.fontDisplay
                    font.pixelSize: Tokens.fontSizeLabel
                    color: backend.dnd ? Theme.stateCritical : Theme.textDim
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: backend.toggleDnd()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: backend.statusMsg
                font.family: Theme.fontMono
                font.pixelSize: Tokens.fontSizeTiny
                color: Theme.textSecondary
                elide: Text.ElideRight
            }
            Rectangle {
                Layout.preferredHeight: Tokens.listRowHeight
                Layout.preferredWidth: clearLbl.implicitWidth + 2 * Tokens.paddingH
                radius: Tokens.radiusSm
                color: Theme.bgSurface
                border.color: Theme.borderIdle
                border.width: Tokens.strokeWidth
                Text {
                    id: clearLbl
                    anchors.centerIn: parent
                    text: "CLEAR"
                    font.family: Theme.fontDisplay
                    font.pixelSize: Tokens.fontSizeLabel
                    color: Theme.textMuted
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: backend.dismissAll()
                }
            }
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Tokens.spacingXss
            model: backend.notifications
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
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                        || event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace) {
                    root.dismissSelected()
                    event.accepted = true
                } else if (event.key === Qt.Key_Up) {
                    root.selectIndex(root.selectedIndex - 1)
                    event.accepted = true
                } else if (event.key === Qt.Key_Down) {
                    root.selectIndex(root.selectedIndex + 1)
                    event.accepted = true
                } else if (event.key === Qt.Key_C) {
                    backend.dismissAll()
                    event.accepted = true
                }
            }

            delegate: Rectangle {
                width: Math.max(0, list.width
                    - (list.contentHeight > list.height
                        ? Tokens.borderXs + Tokens.spacingXss + 2
                        : 0))
                height: Math.max(Tokens.statBoxHeight, bodyCol.implicitHeight + 2 * Tokens.paddingV)
                radius: Tokens.radiusSm
                property bool isSelected: index === root.selectedIndex
                color: isSelected ? Theme.bgElevated : Theme.bgSurface
                border.color: model.urgency === "critical" ? Theme.stateCritical
                            : isSelected ? Theme.accent
                            : Theme.borderIdle
                border.width: Tokens.strokeWidth

                ColumnLayout {
                    id: bodyCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Tokens.paddingH
                    spacing: Tokens.spacingXss

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            Layout.fillWidth: true
                            text: model.appName
                            font.family: Theme.fontMono
                            font.pixelSize: Tokens.fontSizeTiny
                            color: Theme.textDim
                            elide: Text.ElideRight
                        }
                        Text {
                            text: "✕"
                            font.pixelSize: Tokens.fontSizeSmall
                            color: dismissMouse.containsMouse ? Theme.accent : Theme.textDim
                            MouseArea {
                                id: dismissMouse
                                anchors.fill: parent
                                anchors.margins: -Tokens.spacingXs
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: backend.dismissId(model.notifId)
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: model.summary
                        font.family: Theme.fontDisplay
                        font.pixelSize: Tokens.fontSizeLabel
                        color: isSelected ? Theme.accent : Theme.textPrimary
                        wrapMode: Text.Wrap
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: model.body.length > 0
                        text: model.body
                        font.family: Theme.fontMono
                        font.pixelSize: Tokens.fontSizeTiny
                        color: Theme.textSecondary
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selectIndex(index)
                        list.forceActiveFocus()
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: list.count === 0
                text: backend.dnd ? "DND ACTIVE" : "NO TRANSMISSIONS"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.textDim
            }
        }

        Text {
            Layout.fillWidth: true
            text: "ARROWS move * ENTER dismiss * C clear all"
            font.family: Theme.fontMono
            font.pixelSize: Tokens.fontSizeTiny
            color: Theme.textDim
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
