// SystemTabs.qml
import QtQuick
import QtQuick.Layouts
import "../.."

Item {
    id: root

    property string active: Globals.activePanel   // "cpu" | "gpu" | "ram"
    signal switched(string panel)

    height: Tokens.listRowHeight
    Layout.fillWidth: true

    // Tab labels
    RowLayout {
        id: tabRow
        anchors.fill: parent
        spacing: Tokens.spacingXss

        Repeater {
            model: [
                {
                    id: "cpu",
                    label: "CPU"
                },
                {
                    id: "gpu",
                    label: "GPU"
                },
                {
                    id: "ram",
                    label: "RAM"
                }
            ]

            Item {
                Layout.fillWidth: true
                height: Tokens.listRowHeight

                property bool isActive: modelData.id === root.active
                property string panelId: modelData.id

                Text {
                    anchors.centerIn: parent
                    text: modelData.label
                    font.family: Theme.fontDisplay
                    font.pixelSize: Tokens.fontSizeLabel
                    color: isActive ? Theme.accent : Theme.textDim
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.switched(modelData.id)
                }
            }
        }
    }

}
