// BluetoothFrontend.qml --- device list + power/scan (T.S.S content)
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Bluetooth
import "../../.."
import "../../../utils"
import "."

Item {
    id: root
    clip: true

    property int selectedIndex: 0

    BluetoothBackend { id: backend }

    function selectIndex(i) {
        if (i < 0 || i >= list.count)
            return
        selectedIndex = i
        if (list.currentIndex !== i)
            list.currentIndex = i
        list.positionViewAtIndex(i, ListView.Contain)
    }

    function selectedDevice() {
        const row = list.currentItem
        if (row && row.modelData)
            return row.modelData
        return null
    }

    function activateSelected() {
        const dev = selectedDevice()
        if (!dev)
            return
        if (dev.connected)
            backend.disconnectDevice(dev)
        else
            backend.connectDevice(dev)
    }

    function forgetSelected() {
        const dev = selectedDevice()
        if (!dev)
            return
        backend.forgetDevice(dev)
    }

    function grabListFocus() {
        list.forceActiveFocus()
    }

    Component.onCompleted: {
        if (backend.powered)
            backend.setDiscovering(true)
        if (Globals.activeEdgePanel === "bluetooth")
            grabListFocus()
    }

    Connections {
        target: Globals
        function onActiveEdgePanelChanged() {
            if (Globals.activeEdgePanel === "bluetooth")
                Qt.callLater(root.grabListFocus)
        }
    }

    focus: true
    Keys.forwardTo: [list]
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.activateSelected()
            event.accepted = true
        } else if (event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace) {
            root.forgetSelected()
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            root.selectIndex(root.selectedIndex - 1)
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            root.selectIndex(root.selectedIndex + 1)
            event.accepted = true
        } else if (event.key === Qt.Key_S) {
            backend.toggleDiscover()
            event.accepted = true
        } else if (event.key === Qt.Key_P) {
            backend.setPowered(!backend.powered)
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
                text: "BLUETOOTH"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.accent
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.preferredHeight: Tokens.listRowHeight
                Layout.preferredWidth: pwrLabel.implicitWidth + 2 * Tokens.paddingH
                radius: Tokens.radiusSm
                color: backend.powered ? Theme.bgElevated : Theme.bgSurface
                border.color: backend.powered ? Theme.borderActive : Theme.borderIdle
                border.width: Tokens.strokeWidth
                Text {
                    id: pwrLabel
                    anchors.centerIn: parent
                    text: backend.powered ? "ON" : "OFF"
                    font.family: Theme.fontDisplay
                    font.pixelSize: Tokens.fontSizeLabel
                    color: backend.powered ? Theme.accent : Theme.textDim
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: backend.setPowered(!backend.powered)
                }
            }

            Rectangle {
                Layout.preferredHeight: Tokens.listRowHeight
                Layout.preferredWidth: Tokens.listRowHeight + Tokens.paddingH
                radius: Tokens.radiusSm
                color: backend.discovering ? Theme.bgElevated : Theme.bgSurface
                border.color: backend.discovering ? Theme.borderActive : Theme.borderIdle
                border.width: Tokens.strokeWidth
                Image {
                    id: scanGlyph
                    anchors.centerIn: parent
                    width: Tokens.iconSizeMedium
                    height: Tokens.iconSizeMedium
                    source: Theme.iconRefresh
                    sourceSize: Qt.size(width, height)
                    visible: false
                }
                ColorOverlay {
                    anchors.fill: scanGlyph
                    source: scanGlyph
                    color: backend.discovering ? Theme.accent : Theme.textMuted
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: backend.toggleDiscover()
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: backend.statusMsg.length ? backend.statusMsg
                : (backend.powered ? "ADAPTER READY" : "ADAPTER OFFLINE")
            font.family: Theme.fontMono
            font.pixelSize: Tokens.fontSizeTiny
            color: Theme.textSecondary
            elide: Text.ElideRight
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Tokens.spacingXss
            model: Bluetooth.devices
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
                } else if (event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace) {
                    root.forgetSelected()
                    event.accepted = true
                } else if (event.key === Qt.Key_Up) {
                    root.selectIndex(root.selectedIndex - 1)
                    event.accepted = true
                } else if (event.key === Qt.Key_Down) {
                    root.selectIndex(root.selectedIndex + 1)
                    event.accepted = true
                } else if (event.key === Qt.Key_S) {
                    backend.toggleDiscover()
                    event.accepted = true
                } else if (event.key === Qt.Key_P) {
                    backend.setPowered(!backend.powered)
                    event.accepted = true
                }
            }

            onCountChanged: {
                if (count === 0) {
                    root.selectedIndex = 0
                    return
                }
                if (root.selectedIndex >= count)
                    root.selectIndex(count - 1)
            }

            delegate: Rectangle {
                required property var modelData
                required property int index
                width: Math.max(0, list.width
                    - (list.contentHeight > list.height
                        ? Tokens.borderXs + Tokens.spacingXss + 2
                        : 0))
                height: Tokens.statBoxHeight
                radius: Tokens.radiusSm
                property bool isSelected: index === root.selectedIndex
                color: isSelected || rowMouse.containsMouse ? Theme.bgElevated : Theme.bgSurface
                border.color: modelData.connected ? Theme.borderActive
                             : isSelected ? Theme.accent
                             : Theme.borderIdle
                border.width: Tokens.strokeWidth

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Tokens.paddingH
                    spacing: Tokens.spacingXs

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            Layout.fillWidth: true
                            text: modelData.name || modelData.deviceName || modelData.address
                            font.family: Theme.fontDisplay
                            font.pixelSize: Tokens.fontSizeLabel
                            color: modelData.connected || isSelected ? Theme.accent : Theme.textPrimary
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: {
                                let bits = []
                                if (modelData.connected) bits.push("LINKED")
                                else if (modelData.pairing) bits.push("PAIRING")
                                else if (modelData.paired || modelData.bonded) bits.push("PAIRED")
                                else bits.push("NEW")
                                if (modelData.batteryAvailable)
                                    bits.push(Math.round(modelData.battery * 100) + "%")
                                bits.push(modelData.address)
                                return bits.join("  *  ")
                            }
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
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                        root.selectIndex(index)
                        list.forceActiveFocus()
                        if (mouse.button === Qt.RightButton) {
                            backend.forgetDevice(modelData)
                            return
                        }
                        if (modelData.connected)
                            backend.disconnectDevice(modelData)
                        else
                            backend.connectDevice(modelData)
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: list.count === 0
                text: backend.powered ? "NO DEVICES" : "POWER ON ADAPTER"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.textDim
            }
        }

        Text {
            id: instructionText
            Layout.fillWidth: true
            text: "ENTER link * DEL forget * S scan * P power"
            font.family: Theme.fontMono
            font.pixelSize: Tokens.fontSizeTiny
            color: Theme.textDim
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
