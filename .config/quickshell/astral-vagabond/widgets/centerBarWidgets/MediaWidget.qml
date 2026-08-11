// MediaWidget.qml --- YT Music priority, Spotify/spotatui secondary, cava overlay toggle
// Art + transport driven by MediaBackend (playerctl) for reliable Spotify art URLs.
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../.."
import "media"

Item {
    id: root
    clip: true

    MediaBackend { id: backend }

    readonly property int artSide: {
        const colW = Math.floor((width - 3 * Tokens.paddingH) * Tokens.mediaArtWidthFrac)
        const maxH = Math.floor(height * Tokens.mediaArtHeightFrac)
        return Math.max(Tokens.mediaArtMinSide, Math.min(colW, maxH))
    }

    function launchYtMusic() {
        // ytmdesktop-git installs as pear-desktop
        Quickshell.execDetached([
            "bash", "-c",
            "command -v pear-desktop >/dev/null && exec pear-desktop; "
            + "command -v youtube-music >/dev/null && exec youtube-music; "
            + "command -v flatpak >/dev/null && flatpak run app.ytmdesktop.ytmdesktop 2>/dev/null; "
            + "xdg-open 'https://music.youtube.com'"
        ])
    }

    function launchSpotify() {
        Quickshell.execDetached([
            "bash", "-c",
            "command -v spotify >/dev/null && exec spotify; "
            + "command -v spotify-launcher >/dev/null && exec spotify-launcher; "
            + "command -v spotatui >/dev/null && { "
            + "  command -v kitty >/dev/null && exec kitty -e spotatui; "
            + "  command -v ghostty >/dev/null && exec ghostty -e spotatui; "
            + "  exec spotatui; }; "
            + "xdg-open 'https://open.spotify.com'"
        ])
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Tokens.paddingH
        spacing: Tokens.spacingMd

        // -- LEFT: art + transport ---
        ColumnLayout {
            Layout.preferredWidth: 1
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.maximumWidth: Tokens.centerSmallerWidth * Tokens.mediaArtWidthFrac
                + Tokens.spacingXl
            spacing: Tokens.spacingXs

            Text {
                text: "NOW PLAYING"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.accent
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: root.artSide
                Layout.preferredHeight: root.artSide
                Layout.maximumHeight: root.artSide
                radius: Tokens.radiusMd
                color: Theme.bgSurface
                border.color: Theme.borderIdle
                border.width: Tokens.strokeWidth
                clip: true

                Image {
                    id: art
                    anchors.fill: parent
                    anchors.margins: Tokens.borderXss
                    source: backend.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    // Force reload when URL changes (Spotify reuses hosts)
                    onSourceChanged: {
                        if (source && source.toString().length)
                            art.sourceSize = Qt.size(root.artSide * 2, root.artSide * 2)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: art.status !== Image.Ready
                    text: {
                        if (!backend.hasPlayer)
                            return "NO SIGNAL"
                        if (art.status === Image.Loading)
                            return "…"
                        if (backend.artUrl.length && art.status === Image.Error)
                            return "ART ERR"
                        return "NO ART"
                    }
                    font.family: Theme.fontDisplay
                    font.pixelSize: Tokens.fontSizeLabel
                    color: Theme.textDim
                }
            }

            Text {
                Layout.fillWidth: true
                text: backend.title.length ? backend.title : "Silence on the wire"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeSmall
                color: Theme.textPrimary
                elide: Text.ElideRight
                wrapMode: Text.Wrap
                maximumLineCount: Tokens.weatherCurrentMaxLines
            }

            Text {
                Layout.fillWidth: true
                text: {
                    if (!backend.hasTrack && !backend.hasPlayer)
                        return "Play in YT Music or Spotify * MPRIS feeds this panel"
                    const bits = []
                    if (backend.artist.length)
                        bits.push(backend.artist)
                    if (backend.album.length)
                        bits.push(backend.album)
                    return bits.length ? bits.join(" * ") : backend.playerName
                }
                font.family: Theme.fontMono
                font.pixelSize: Tokens.fontSizeTiny
                color: Theme.textSecondary
                elide: Text.ElideRight
                wrapMode: Text.Wrap
                maximumLineCount: Tokens.weatherCurrentMaxLines
            }

            RowLayout {
                Layout.fillWidth: true
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
                        color: tMouse.containsMouse ? Theme.bgElevated : Theme.bgSurface
                        border.color: Theme.borderIdle
                        border.width: Tokens.strokeWidth
                        enabled: backend.hasPlayer
                        opacity: backend.hasPlayer ? Theme.opacityVisible : Theme.opacityMuted

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

            Item { Layout.fillHeight: true }
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: Tokens.strokeWidth
            color: Theme.borderIdle
            opacity: Theme.opacityMuted
        }

        // -- RIGHT: sources + cava ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            spacing: Tokens.spacingXs

            Text {
                text: "SOURCES"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.accent
            }

            // YT Music primary
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Tokens.edgeToggleHeight
                radius: Tokens.radiusMd
                color: ytMouse.containsMouse ? Theme.bgElevated : Theme.bgSurface
                border.color: Theme.borderActive
                border.width: Tokens.strokeWidth

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Tokens.paddingH
                    spacing: Tokens.spacingSm
                    Text {
                        text: "▶"
                        color: Theme.accent
                        font.pixelSize: Tokens.fontSizeMedium
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            text: "YOUTUBE MUSIC"
                            font.family: Theme.fontDisplay
                            font.pixelSize: Tokens.fontSizeLabel
                            color: Theme.textPrimary
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "PRIMARY * pear-desktop * Super+M"
                            font.family: Theme.fontMono
                            font.pixelSize: Tokens.fontSizeTiny
                            color: Theme.textDim
                            elide: Text.ElideRight
                        }
                    }
                }
                MouseArea {
                    id: ytMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.launchYtMusic()
                }
            }

            // Spotify (installed) / spotatui
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Tokens.edgeToggleHeight
                radius: Tokens.radiusMd
                color: spMouse.containsMouse ? Theme.bgElevated : Theme.bgSurface
                border.color: Theme.borderIdle
                border.width: Tokens.strokeWidth

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Tokens.paddingH
                    spacing: Tokens.spacingSm
                    Text {
                        text: "♪"
                        color: Theme.stateSafe
                        font.pixelSize: Tokens.fontSizeMedium
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            text: "SPOTIFY"
                            font.family: Theme.fontDisplay
                            font.pixelSize: Tokens.fontSizeLabel
                            color: Theme.textPrimary
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "SECONDARY * native client (MPRIS) * spotatui fallback"
                            font.family: Theme.fontMono
                            font.pixelSize: Tokens.fontSizeTiny
                            color: Theme.textDim
                            elide: Text.ElideRight
                        }
                    }
                }
                MouseArea {
                    id: spMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.launchSpotify()
                }
            }

            // CAVA overlay toggle
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Tokens.edgeToggleHeight
                radius: Tokens.radiusMd
                color: backend.cavaOn ? Theme.bgElevated : Theme.bgSurface
                border.color: backend.cavaOn ? Theme.borderActive : Theme.borderIdle
                border.width: Tokens.strokeWidth

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Tokens.paddingH
                    spacing: Tokens.spacingSm
                    Text {
                        text: "▁▂▃"
                        color: backend.cavaOn ? Theme.accent : Theme.textMuted
                        font.pixelSize: Tokens.fontSizeMedium
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            text: "CAVA OVERLAY"
                            font.family: Theme.fontDisplay
                            font.pixelSize: Tokens.fontSizeLabel
                            color: backend.cavaOn ? Theme.accent : Theme.textPrimary
                        }
                        Text {
                            Layout.fillWidth: true
                            text: backend.cavaOn
                                ? "ON * desktop visualizer pinned"
                                : "OFF * toggle audio bars on desktop"
                            font.family: Theme.fontMono
                            font.pixelSize: Tokens.fontSizeTiny
                            color: Theme.textDim
                            elide: Text.ElideRight
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: backend.toggleCava()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Tokens.radiusMd
                color: Theme.bgSurface
                border.color: Theme.borderIdle
                border.width: Tokens.strokeWidth

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Tokens.paddingH
                    spacing: Tokens.spacingXs

                    Text {
                        text: "ACTIVE PLAYER"
                        font.family: Theme.fontDisplay
                        font.pixelSize: Tokens.fontSizeLabel
                        color: Theme.textMuted
                    }
                    Text {
                        Layout.fillWidth: true
                        text: backend.hasPlayer ? backend.playerName : "None --- hit play in Spotify/YTM"
                        font.family: Theme.fontMono
                        font.pixelSize: Tokens.fontSizeSmall
                        color: Theme.textPrimary
                        wrapMode: Text.Wrap
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "STATUS * " + (backend.status || "IDLE").toUpperCase()
                        font.family: Theme.fontMono
                        font.pixelSize: Tokens.fontSizeTiny
                        color: backend.isPlaying ? Theme.stateSafe : Theme.textDim
                    }
                    Item { Layout.fillHeight: true }
                }
            }
        }
    }
}
