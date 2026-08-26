import QtQuick
import QtQuick.Layouts
import ".."
import "../widgets/centerBarWidgets/media"

Rectangle {
    id: root

    required property var lock

    radius: Tokens.radiusMd
    color: Theme.bgSurface
    border.color: Theme.borderIdle
    border.width: Tokens.strokeWidth
    clip: true

    MediaBackend { id: backend }

    Image {
        id: artBg
        anchors.fill: parent
        source: backend.artUrl
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: status === Image.Ready ? 0.22 : 0
        Behavior on opacity {
            NumberAnimation { duration: Tokens.animMedium; easing.type: Easing.OutCubic }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bgSurface
        opacity: artBg.status === Image.Ready ? 0.55 : 0
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Tokens.paddingH
        spacing: Tokens.spacingXs

        Text {
            text: "NOW PLAYING"
            font.family: Theme.fontDisplay
            font.pixelSize: Tokens.fontSizeLabel
            color: Theme.accent
        }

        Text {
            Layout.fillWidth: true
            text: backend.title.length ? backend.title : "Nothing playing"
            font.family: Theme.fontDisplay
            font.pixelSize: Tokens.fontSizeSmall
            color: Theme.textPrimary
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            Layout.fillWidth: true
            text: backend.artist.length ? backend.artist : (backend.hasPlayer ? backend.playerName : "Try playing some music")
            font.family: Theme.fontMono
            font.pixelSize: Tokens.fontSizeTiny
            color: Theme.textSecondary
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacingXs
            spacing: Tokens.spacingXs

            Repeater {
                model: [
                    { key: "prev", label: "⏮" },
                    { key: "toggle", label: backend.isPlaying ? "⏸" : "▶" },
                    { key: "next", label: "⏭" }
                ]

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Tokens.actionBtnHeight
                    radius: Tokens.radiusSm
                    color: tMouse.containsMouse ? Theme.bgElevated : Theme.bgPrimary
                    border.color: Theme.borderIdle
                    border.width: Tokens.strokeWidth
                    enabled: backend.hasPlayer
                    opacity: backend.hasPlayer ? 1 : Theme.opacityMuted

                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        font.pixelSize: Tokens.fontSizeBase
                        color: Theme.accent
                    }
                    MouseArea {
                        id: tMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.key === "prev")
                                backend.previous()
                            else if (modelData.key === "next")
                                backend.next()
                            else
                                backend.playPause()
                        }
                    }
                }
            }
        }
    }
}
