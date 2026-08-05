import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../.."

Item {
    id: root

    property string active: Globals.activeEdgePanel
    signal switched(string panel)

    implicitHeight: grid.implicitHeight
    Layout.fillWidth: true

    GridLayout {
        id: grid
        anchors.left:  parent.left
        anchors.right: parent.right
        columns: 2
        rowSpacing:    Tokens.spacingXs
        columnSpacing: Tokens.spacingXs

        Repeater {
            model: [
                { id: "wifi",          label: "WIFI",  icon: Theme.iconWifi },
                { id: "bluetooth",     label: "BLUETOOTH",    icon: Theme.iconBluetooth },
                { id: "settings",      label: "CONFIGURATION",   icon: Theme.iconSettings },
                { id: "notifications", label: "NOTIFICATIONS", icon: Theme.iconNotif }
            ]

            Rectangle {
                id: tile
                Layout.fillWidth: true
                Layout.preferredHeight: Tokens.edgeToggleHeight
                radius: Tokens.radiusMd
                color: isActive ? Theme.bgElevated : Theme.bgSurface
                border.color: isActive ? Theme.borderActive : Theme.borderIdle
                border.width: Tokens.strokeWidth

                property bool isActive: modelData.id === root.active
                property string panelId: modelData.id

                Behavior on color {
                    ColorAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
                }
                Behavior on border.color {
                    ColorAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Tokens.paddingH
                    spacing: Tokens.spacingXs

                    Item {
                        Layout.preferredWidth:  Tokens.iconSizeLarge
                        Layout.preferredHeight: Tokens.iconSizeLarge
                        Layout.alignment: Qt.AlignVCenter

                        Image {
                            id: glyph
                            anchors.fill: parent
                            source: modelData.icon
                            sourceSize.width:  Tokens.iconSizeLarge
                            sourceSize.height: Tokens.iconSizeLarge
                            fillMode: Image.PreserveAspectFit
                            visible: false
                            smooth: true
                        }
                        ColorOverlay {
                            anchors.fill: glyph
                            source: glyph
                            color: tile.isActive ? Theme.accent : Theme.textMuted
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.label
                        font.family: Theme.fontDisplay
                        font.pixelSize: Tokens.fontSizeLabel
                        color: tile.isActive ? Theme.accent : Theme.textDim
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.switched(modelData.id)
                }
            }
        }
    }
}
