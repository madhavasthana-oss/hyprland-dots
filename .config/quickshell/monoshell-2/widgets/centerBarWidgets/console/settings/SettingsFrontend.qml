// SettingsFrontend.qml --- monochrome quick settings (scrollable, clipped)
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import "../../../.."
import "../../../../utils"
import "."

Item {
    id: root
    // StackLayout assigns size; never drive parent height from content
    clip: true

    signal requestClose()

    SettingsBackend {
        id: backend
        onRequestClose: root.requestClose()
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: MonoScrollBar {}

        ColumnLayout {
            id: col
            width: Math.max(0, flick.width
                - (flick.contentHeight > flick.height
                    ? Tokens.borderXs + Tokens.spacingXss + 2
                    : 0))
            spacing: Tokens.spacingSm

            Text {
                text: "SETTINGS"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeLabel
                color: Theme.accent
            }

            Text {
                Layout.fillWidth: true
                visible: backend.statusMsg.length > 0
                text: backend.statusMsg
                font.family: Theme.fontMono
                font.pixelSize: Tokens.fontSizeTiny
                color: Theme.textSecondary
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            // Brightness
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacingXs

                Item {
                    Layout.preferredWidth: Tokens.iconSizeMedium
                    Layout.preferredHeight: Tokens.iconSizeMedium
                    Image {
                        id: brightGlyph
                        anchors.fill: parent
                        source: Theme.iconBrightness
                        sourceSize: Qt.size(width, height)
                        visible: false
                    }
                    ColorOverlay {
                        anchors.fill: brightGlyph
                        source: brightGlyph
                        color: Theme.textMuted
                    }
                }

                Text {
                    text: "SCR"
                    font.family: Theme.fontDisplay
                    font.pixelSize: Tokens.fontSizeLabel
                    color: Theme.textDim
                    Layout.preferredWidth: Tokens.spacingXl
                }

                Rectangle {
                    id: brightTrack
                    Layout.fillWidth: true
                    Layout.preferredHeight: Tokens.usageBarHeight + Tokens.spacingXs
                    radius: Tokens.radiusSm
                    color: Theme.bgElevated

                    Rectangle {
                        width: parent.width * (backend.brightness / 100)
                        height: parent.height
                        radius: parent.radius
                        color: Theme.accent
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (mouse) => backend.setBrightness((mouse.x / width) * 100)
                        onPositionChanged: (mouse) => {
                            if (pressed)
                                backend.setBrightness((mouse.x / width) * 100)
                        }
                    }
                }

                Text {
                    text: backend.brightness + "%"
                    font.family: Theme.fontMono
                    font.pixelSize: Tokens.fontSizeTiny
                    color: Theme.textSecondary
                    Layout.preferredWidth: Tokens.spacingXl + Tokens.spacingSm
                    horizontalAlignment: Text.AlignRight
                }
            }

            // Volume
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacingXs

                Item {
                    Layout.preferredWidth: Tokens.iconSizeMedium
                    Layout.preferredHeight: Tokens.iconSizeMedium
                    Image {
                        id: volGlyph
                        anchors.fill: parent
                        source: Theme.iconAudio
                        sourceSize: Qt.size(width, height)
                        visible: false
                    }
                    ColorOverlay {
                        anchors.fill: volGlyph
                        source: volGlyph
                        color: backend.muted ? Theme.stateCritical : Theme.textMuted
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backend.toggleMute()
                    }
                }

                Text {
                    text: "VOL"
                    font.family: Theme.fontDisplay
                    font.pixelSize: Tokens.fontSizeLabel
                    color: Theme.textDim
                    Layout.preferredWidth: Tokens.spacingXl
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Tokens.usageBarHeight + Tokens.spacingXs
                    radius: Tokens.radiusSm
                    color: Theme.bgElevated

                    Rectangle {
                        width: parent.width * Math.min(backend.volume, 100) / 100
                        height: parent.height
                        radius: parent.radius
                        color: backend.muted ? Theme.textDim : Theme.accent
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (mouse) => backend.setVolume((mouse.x / width) * 100)
                        onPositionChanged: (mouse) => {
                            if (pressed)
                                backend.setVolume((mouse.x / width) * 100)
                        }
                    }
                }

                Text {
                    text: backend.muted ? "M" : (backend.volume + "%")
                    font.family: Theme.fontMono
                    font.pixelSize: Tokens.fontSizeTiny
                    color: Theme.textSecondary
                    Layout.preferredWidth: Tokens.spacingXl + Tokens.spacingSm
                    horizontalAlignment: Text.AlignRight
                }
            }

            // Keyboard backlight
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacingXs

                Item {
                    Layout.preferredWidth: Tokens.iconSizeMedium
                    Layout.preferredHeight: Tokens.iconSizeMedium
                    Image {
                        id: kbdGlyph
                        anchors.fill: parent
                        source: Theme.iconKbd
                        sourceSize: Qt.size(width, height)
                        visible: false
                    }
                    ColorOverlay {
                        anchors.fill: kbdGlyph
                        source: kbdGlyph
                        color: Theme.textMuted
                    }
                }

                Text {
                    text: "KBD"
                    font.family: Theme.fontDisplay
                    font.pixelSize: Tokens.fontSizeLabel
                    color: Theme.textDim
                    Layout.preferredWidth: Tokens.spacingXl
                }

                Repeater {
                    model: backend.kbdMax + 1
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Tokens.actionBtnHeight
                        radius: Tokens.radiusSm
                        color: index <= backend.kbdBrightness ? Theme.bgElevated : Theme.bgSurface
                        border.color: index <= backend.kbdBrightness ? Theme.borderActive : Theme.borderIdle
                        border.width: Tokens.strokeWidth
                        Text {
                            anchors.centerIn: parent
                            text: String(index)
                            font.family: Theme.fontMono
                            font.pixelSize: Tokens.fontSizeTiny
                            color: index <= backend.kbdBrightness ? Theme.accent : Theme.textDim
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: backend.setKbd(index)
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Tokens.strokeWidth
                color: Theme.borderIdle
                opacity: 0.5
            }

            // Action tiles --- short labels to avoid overflow at edge width
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: Tokens.spacingXs
                columnSpacing: Tokens.spacingXs

                Repeater {
                    model: [
                        { key: "gnome",    label: "GNOME",    icon: Theme.iconThemeApp },
                        { key: "shot",     label: "CAPTURE",  icon: Theme.iconScreenshot },
                        { key: "rec",      label: Globals.screenRecording ? "STOP" : "RECORD", icon: Theme.iconRecord },
                        { key: "mute",     label: backend.muted ? "UNMUTE" : "MUTE", icon: Theme.iconAudio },
                        { key: "caffeine", label: backend.caffeineActive ? "CAFFEINE ON" : "CAFFEINE", icon: Theme.iconCaffeine },
                        { key: "nolock",   label: backend.idleLockDisabled ? "NO LOCK" : "AUTOLOCK", icon: Theme.iconIdleLock },
                        { key: "wallust",  label: "WALLUST",  icon: Theme.iconThemeApp },
                        { key: "legacy",   label: "ASH",      icon: Theme.iconThemeApp }
                    ]

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Tokens.edgeToggleHeight
                        Layout.maximumHeight: Tokens.edgeToggleHeight
                        radius: Tokens.radiusMd
                        color: {
                            if (modelData.key === "caffeine" && backend.caffeineActive)
                                return Theme.bgElevated
                            if (modelData.key === "nolock" && backend.idleLockDisabled)
                                return Theme.bgElevated
                            return tileMouse.containsMouse ? Theme.bgElevated : Theme.bgSurface
                        }
                        border.color: {
                            if (modelData.key === "rec" && Globals.screenRecording)
                                return Theme.stateCritical
                            if (modelData.key === "caffeine" && backend.caffeineActive)
                                return Theme.borderActive
                            if (modelData.key === "nolock" && backend.idleLockDisabled)
                                return Theme.borderActive
                            return Theme.borderIdle
                        }
                        border.width: Tokens.strokeWidth
                        clip: true

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Tokens.paddingH
                            spacing: Tokens.spacingXs

                            Item {
                                Layout.preferredWidth: Tokens.iconSizeMedium
                                Layout.preferredHeight: Tokens.iconSizeMedium
                                Layout.maximumWidth: Tokens.iconSizeMedium
                                Image {
                                    id: actGlyph
                                    anchors.fill: parent
                                    source: modelData.icon
                                    sourceSize: Qt.size(width, height)
                                    visible: false
                                }
                                ColorOverlay {
                                    anchors.fill: actGlyph
                                    source: actGlyph
                                    color: {
                                        if (modelData.key === "rec" && Globals.screenRecording)
                                            return Theme.stateCritical
                                        if (modelData.key === "caffeine" && backend.caffeineActive)
                                            return Theme.accent
                                        if (modelData.key === "nolock" && backend.idleLockDisabled)
                                            return Theme.accent
                                        return Theme.textMuted
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.label
                                font.family: Theme.fontDisplay
                                font.pixelSize: Tokens.fontSizeLabel
                                color: {
                                    if (modelData.key === "caffeine" && backend.caffeineActive)
                                        return Theme.accent
                                    if (modelData.key === "nolock" && backend.idleLockDisabled)
                                        return Theme.accent
                                    return Theme.textPrimary
                                }
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                        }

                        MouseArea {
                            id: tileMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                switch (modelData.key) {
                                case "gnome":    backend.launchGnome(); break
                                case "shot":     backend.screenshot(); break
                                case "rec":      backend.toggleRecord(); break
                                case "mute":     backend.toggleMute(); break
                                case "caffeine": backend.toggleCaffeine(); break
                                case "nolock":   backend.toggleIdleLock(); break
                                case "wallust":  backend.syncWallust(); break
                                case "legacy":   backend.activateLegacy(); break
                                }
                            }
                        }
                    }
                }
            }

            // Theme line
            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacingXs
                Text {
                    text: "THEME"
                    font.family: Theme.fontDisplay
                    font.pixelSize: Tokens.fontSizeLabel
                    color: Theme.textDim
                }
                Text {
                    Layout.fillWidth: true
                    text: (Theme.colorsSource || "defaults").toUpperCase()
                        + (backend.wallpaperHint.length ? (" * " + backend.wallpaperHint) : "")
                    font.family: Theme.fontMono
                    font.pixelSize: Tokens.fontSizeTiny
                    color: Theme.textSecondary
                    elide: Text.ElideMiddle
                    maximumLineCount: 1
                }
                Text {
                    text: "↻"
                    font.pixelSize: Tokens.fontSizeSmall
                    color: wallRefMouse.containsMouse ? Theme.accent : Theme.textDim
                    MouseArea {
                        id: wallRefMouse
                        anchors.fill: parent
                        anchors.margins: -Tokens.spacingXs
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backend.scanWallpapers()
                    }
                }
            }

            // Fixed-height wallpaper list with its own scrollbar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Tokens.listRowHeight * Tokens.wallpaperListRows
                    + Tokens.paddingH * 2
                Layout.maximumHeight: Tokens.listRowHeight * Tokens.wallpaperListRows
                    + Tokens.paddingH * 2
                radius: Tokens.radiusMd
                color: Theme.bgSurface
                border.color: Theme.borderIdle
                border.width: Tokens.strokeWidth
                clip: true

                ListView {
                    id: wallList
                    anchors.fill: parent
                    anchors.margins: Tokens.paddingH
                    clip: true
                    spacing: Tokens.spacingXss
                    model: backend.wallpapers
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick
                    interactive: contentHeight > height
                    ScrollBar.vertical: MonoScrollBar {}

                    delegate: Rectangle {
                        width: Math.max(0, wallList.width
                            - (wallList.contentHeight > wallList.height
                                ? Tokens.borderXs + Tokens.spacingXss + 2
                                : 0))
                        height: Tokens.listRowHeight
                        radius: Tokens.radiusSm
                        color: wallRowMouse.containsMouse ? Theme.bgElevated : Theme.bgPrimary
                        border.color: Theme.borderIdle
                        border.width: Tokens.strokeWidth
                        clip: true

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: Tokens.paddingH
                            anchors.rightMargin: Tokens.paddingH
                            text: model.name
                            font.family: Theme.fontMono
                            font.pixelSize: Tokens.fontSizeTiny
                            color: Theme.textPrimary
                            elide: Text.ElideMiddle
                            verticalAlignment: Text.AlignVCenter
                            maximumLineCount: 1
                        }

                        MouseArea {
                            id: wallRowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: backend.setWallpaper(model.path)
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: wallList.count === 0
                        text: backend.wallScanning ? "SCANNING..." : "NO WALLPAPERS"
                        font.family: Theme.fontDisplay
                        font.pixelSize: Tokens.fontSizeLabel
                        color: Theme.textDim
                    }
                }
            }
        }
    }
}
