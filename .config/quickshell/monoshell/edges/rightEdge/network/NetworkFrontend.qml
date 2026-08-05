// NetworkFrontend.qml --- wifi list + password + rescan (T.S.S content)
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import "../../.."
import "../../../utils"
import "."

Item {
    id: root
    // StackLayout sizes us; clip so lists never paint outside the card
    clip: true

    property int selectedIndex: 0

    NetworkBackend { id: backend }

    function selectIndex(i) {
        if (i < 0 || i >= backend.networks.count)
            return
        selectedIndex = i
        if (list.currentIndex !== i)
            list.currentIndex = i
        list.positionViewAtIndex(i, ListView.Contain)
    }

    function activateSelected() {
        if (backend.needsPassword)
            return
        if (selectedIndex < 0 || selectedIndex >= backend.networks.count)
            return
        const row = backend.networks.get(selectedIndex)
        if (!row)
            return
        if (row.inUse)
            backend.disconnectWifi()
        else
            backend.connectTo(row.rawSsid, row.security, row.inUse)
    }

    function grabListFocus() {
        if (backend.needsPassword)
            pskField.forceActiveFocus()
        else
            list.forceActiveFocus()
    }

    Component.onCompleted: {
        if (Globals.activeEdgePanel === "wifi")
            grabListFocus()
    }

    Connections {
        target: Globals
        function onActiveEdgePanelChanged() {
            if (Globals.activeEdgePanel === "wifi")
                Qt.callLater(root.grabListFocus)
        }
    }

    Connections {
        target: backend
        function onNeedsPasswordChanged() {
            if (backend.needsPassword) {
                pskField.text = ""
                Qt.callLater(() => pskField.forceActiveFocus())
            } else {
                Qt.callLater(root.grabListFocus)
            }
        }
    }

    Connections {
        target: backend.networks
        function onCountChanged() {
            if (backend.networks.count === 0) {
                selectedIndex = 0
                return
            }
            if (selectedIndex >= backend.networks.count)
                selectIndex(backend.networks.count - 1)
        }
    }

    focus: true
    Keys.forwardTo: [list]
    Keys.onPressed: (event) => {
        if (backend.needsPassword)
            return
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.activateSelected()
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            root.selectIndex(root.selectedIndex - 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            root.selectIndex(root.selectedIndex + 1)
            event.accepted = true
        } else if (event.key === Qt.Key_R) {
            backend.rescan()
            event.accepted = true
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Tokens.spacingXs

        // Header row
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacingXs

            Text {
                text: "NETWORK"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.accent
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.preferredHeight: Tokens.listRowHeight
                Layout.preferredWidth: wifiToggleLabel.implicitWidth + 2 * Tokens.paddingH
                radius: Tokens.radiusSm
                color: backend.wifiEnabled ? Theme.bgElevated : Theme.bgSurface
                border.color: backend.wifiEnabled ? Theme.borderActive : Theme.borderIdle
                border.width: Tokens.strokeWidth

                Text {
                    id: wifiToggleLabel
                    anchors.centerIn: parent
                    text: backend.wifiEnabled ? "ON" : "OFF"
                    font.family: Theme.fontDisplay
                    font.pixelSize: Tokens.fontSizeLabel
                    color: backend.wifiEnabled ? Theme.accent : Theme.textDim
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: backend.setWifiEnabled(!backend.wifiEnabled)
                }
            }

            Rectangle {
                Layout.preferredHeight: Tokens.listRowHeight
                Layout.preferredWidth: Tokens.listRowHeight + Tokens.paddingH
                radius: Tokens.radiusSm
                color: rescanMouse.containsMouse ? Theme.bgElevated : Theme.bgSurface
                border.color: Theme.borderIdle
                border.width: Tokens.strokeWidth

                Item {
                    anchors.centerIn: parent
                    width: Tokens.iconSizeMedium
                    height: Tokens.iconSizeMedium

                    Image {
                        id: refreshGlyph
                        anchors.fill: parent
                        source: Theme.iconRefresh
                        sourceSize: Qt.size(width, height)
                        visible: false
                    }
                    ColorOverlay {
                        anchors.fill: refreshGlyph
                        source: refreshGlyph
                        color: backend.scanning ? Theme.accent : Theme.textMuted
                    }

                    RotationAnimator on rotation {
                        running: backend.scanning
                        from: 0; to: 360
                        duration: 800
                        loops: Animation.Infinite
                    }
                }
                MouseArea {
                    id: rescanMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: backend.rescan()
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: backend.statusMsg
            font.family: Theme.fontMono
            font.pixelSize: Tokens.fontSizeTiny
            color: Theme.textSecondary
            elide: Text.ElideRight
        }

        // Password prompt
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacingXs
            visible: backend.needsPassword

            Text {
                text: "KEY FOR " + backend.pendingSsid
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.stateWarning
            }

            TextField {
                id: pskField
                Layout.fillWidth: true
                echoMode: TextInput.Password
                placeholderText: "passphrase"
                color: Theme.textPrimary
                placeholderTextColor: Theme.textDim
                font.family: Theme.fontMono
                font.pixelSize: Tokens.fontSizeSmall
                background: Rectangle {
                    color: Theme.bgSurface
                    radius: Tokens.radiusSm
                    border.color: Theme.borderActive
                    border.width: Tokens.strokeWidth
                }
                onAccepted: backend.connectWithPassword(text)
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacingXs

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Tokens.actionBtnHeight
                    radius: Tokens.radiusSm
                    color: Theme.bgElevated
                    border.color: Theme.borderActive
                    border.width: Tokens.strokeWidth
                    Text {
                        anchors.centerIn: parent
                        text: "CONNECT"
                        font.family: Theme.fontDisplay
                        font.pixelSize: Tokens.fontSizeLabel
                        color: Theme.accent
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backend.connectWithPassword(pskField.text)
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Tokens.actionBtnHeight
                    radius: Tokens.radiusSm
                    color: Theme.bgSurface
                    border.color: Theme.borderIdle
                    border.width: Tokens.strokeWidth
                    Text {
                        anchors.centerIn: parent
                        text: "ABORT"
                        font.family: Theme.fontDisplay
                        font.pixelSize: Tokens.fontSizeLabel
                        color: Theme.textMuted
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            pskField.text = ""
                            backend.cancelPassword()
                        }
                    }
                }
            }
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Tokens.spacingXss
            model: backend.networks
            visible: !backend.needsPassword
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
                    root.activateSelected()
                    event.accepted = true
                } else if (event.key === Qt.Key_Up) {
                    root.selectIndex(root.selectedIndex - 1)
                    event.accepted = true
                } else if (event.key === Qt.Key_Down) {
                    root.selectIndex(root.selectedIndex + 1)
                    event.accepted = true
                } else if (event.key === Qt.Key_R) {
                    backend.rescan()
                    event.accepted = true
                }
            }

            delegate: Rectangle {
                width: Math.max(0, list.width
                    - (list.contentHeight > list.height
                        ? Tokens.borderXs + Tokens.spacingXss + 2
                        : 0))
                height: Tokens.statBoxHeight
                radius: Tokens.radiusSm
                property bool isSelected: index === root.selectedIndex
                color: isSelected || rowMouse.containsMouse ? Theme.bgElevated : Theme.bgSurface
                border.color: model.inUse ? Theme.borderActive
                             : isSelected ? Theme.accent
                             : Theme.borderIdle
                border.width: Tokens.strokeWidth

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Tokens.paddingH
                    spacing: Tokens.spacingXs

                    Text {
                        text: model.signal + "%"
                        font.family: Theme.fontMono
                        font.pixelSize: Tokens.fontSizeTiny
                        color: model.signal > 60 ? Theme.stateSafe
                             : model.signal > 30 ? Theme.stateWarning
                             : Theme.stateCritical
                        Layout.preferredWidth: Tokens.spacingXl
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            Layout.fillWidth: true
                            text: model.ssid
                            font.family: Theme.fontDisplay
                            font.pixelSize: Tokens.fontSizeLabel
                            color: model.inUse || isSelected ? Theme.accent : Theme.textPrimary
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: model.security + (model.inUse ? "  *  LINKED" : "")
                            font.family: Theme.fontMono
                            font.pixelSize: Tokens.fontSizeTiny
                            color: Theme.textDim
                            elide: Text.ElideRight
                        }
                    }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selectIndex(index)
                        list.forceActiveFocus()
                        if (model.inUse)
                            backend.disconnectWifi()
                        else
                            backend.connectTo(model.rawSsid, model.security, model.inUse)
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: list.count === 0 && !backend.scanning
                text: "NO NETWORKS"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.textDim
            }
        }

        Text {
            Layout.fillWidth: true
            visible: !backend.needsPassword
            text: "ARROWS move * ENTER link * R rescan"
            font.family: Theme.fontMono
            font.pixelSize: Tokens.fontSizeTiny
            color: Theme.textDim
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Timer {
        interval: 15000
        running: root.visible
        repeat: true
        onTriggered: {
            if (!backend.scanning && !backend.connecting && !backend.needsPassword)
                backend.rescan()
        }
    }
}
