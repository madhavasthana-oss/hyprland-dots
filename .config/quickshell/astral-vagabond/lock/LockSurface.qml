pragma ComponentBehavior: Bound

import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell.Wayland
import ".."

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock
    required property Pam pam

    readonly property alias unlocking: unlockAnim.running
    readonly property int screenH: screen ? screen.height : Tokens.screenHeight
    readonly property int screenW: screen ? screen.width : Tokens.screenWidth
    readonly property int cardH: Math.round(Math.min(screenH, screenW) * Tokens.lockHeightFrac)
    readonly property int cardW: Math.round(Math.min(screenW * Tokens.lockWidthFrac, cardH * Tokens.lockRatio))
    readonly property int badgeSize: lockGlyph.height + Tokens.paddingV * 4

    color: "transparent"

    Connections {
        target: root.lock
        function onUnlockRequested() {
            unlockAnim.start()
        }
    }

    SequentialAnimation {
        id: unlockAnim
        ParallelAnimation {
            NumberAnimation {
                target: lockContent
                properties: "implicitWidth,implicitHeight"
                to: root.badgeSize
                duration: Tokens.animSlow
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: lockBg
                property: "radius"
                to: root.badgeSize / 2
                duration: Tokens.animSlow
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: content
                property: "scale"
                to: 0
                duration: Tokens.animExpand
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: content
                property: "opacity"
                to: 0
                duration: Tokens.animMedium
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: lockIcon
                property: "opacity"
                to: 1
                duration: Tokens.animSlow
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: background
                property: "opacity"
                to: 0
                duration: Tokens.animSlow
                easing.type: Easing.InQuad
            }
        }
        ScriptAction {
            script: root.lock.locked = false
        }
    }

    SequentialAnimation {
        id: initAnim
        running: true

        NumberAnimation {
            target: background
            property: "opacity"
            to: 1
            duration: Tokens.animSlow
            easing.type: Easing.OutCubic
        }

        ParallelAnimation {
            NumberAnimation {
                target: lockContent
                property: "scale"
                to: 1
                duration: Tokens.animExpand
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: lockContent
                property: "rotation"
                to: 0
                duration: Tokens.animSlow
                easing.type: Easing.OutCubic
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: lockIcon
                property: "opacity"
                to: 0
                duration: Tokens.animMedium
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: content
                property: "opacity"
                to: 1
                duration: Tokens.animExpand
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: content
                property: "scale"
                to: 1
                duration: Tokens.animExpand
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: lockBg
                property: "radius"
                to: Tokens.radiusXl
                duration: Tokens.animExpand
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: lockContent
                property: "implicitWidth"
                to: root.cardW
                duration: Tokens.animExpand
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: lockContent
                property: "implicitHeight"
                to: root.cardH
                duration: Tokens.animExpand
                easing.type: Easing.OutCubic
            }
        }
    }

    Item {
        id: background
        anchors.fill: parent
        opacity: 0

        ScreencopyView {
            id: shot
            anchors.fill: parent
            captureSource: root.screen
            live: false
            visible: false
        }

        FastBlur {
            anchors.fill: parent
            source: shot
            radius: 64
            visible: shot.hasContent
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.bgPrimary
            opacity: shot.hasContent ? 0.42 : 0.92
        }
    }

    Item {
        id: lockContent
        anchors.centerIn: parent
        implicitWidth: root.badgeSize
        implicitHeight: root.badgeSize
        rotation: 180
        scale: 0

        Rectangle {
            id: lockBg
            anchors.fill: parent
            color: Theme.bgConsole
            opacity: Theme.opacityConsole
            radius: root.badgeSize / 2
            border.color: Theme.borderConsole
            border.width: Tokens.strokeWidth
        }

        Image {
            id: lockGlyph
            anchors.centerIn: parent
            width: Tokens.iconSizeBottom * 2
            height: Tokens.iconSizeBottom * 2
            source: Theme.iconLock
            sourceSize.width: width
            sourceSize.height: height
            fillMode: Image.PreserveAspectFit
            visible: false
            smooth: true
        }

        ColorOverlay {
            id: lockIcon
            anchors.fill: lockGlyph
            source: lockGlyph
            color: Theme.accent
            opacity: 1
        }

        Content {
            id: content
            anchors.centerIn: parent
            width: Math.max(1, root.cardW - Tokens.lockPad * 2)
            height: Math.max(1, root.cardH - Tokens.lockPad * 2)
            lock: root
            opacity: 0
            scale: 0
        }
    }
}
