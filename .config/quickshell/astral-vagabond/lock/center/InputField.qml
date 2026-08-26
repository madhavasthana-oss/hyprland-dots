pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../.."

Item {
    id: root

    required property real centerScale
    required property var pam

    clip: true

    Text {
        id: placeholder
        anchors.centerIn: parent
        text: {
            if (root.pam.passwd.active)
                return "authenticating…"
            if (root.pam.howdy.active)
                return "scanning face…"
            if (root.pam.fprint.active)
                return "waiting for fingerprint…"
            if (root.pam.state === root.pam.stateMaxTries)
                return "max tries reached"
            return "enter passphrase…"
        }
        font.family: Theme.fontMono
        font.pixelSize: Math.round(Tokens.fontSizeSmall * root.centerScale)
        color: root.pam.passwd.active ? Theme.accent : Theme.textMuted
        opacity: root.pam.buffer.length ? 0 : 1

        Behavior on opacity {
            NumberAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
        }
    }

    Row {
        id: dots
        anchors.centerIn: parent
        spacing: Math.round(Tokens.lockDotSize * 0.55)
        visible: root.pam.buffer.length > 0

        Repeater {
            model: root.pam.buffer.length

            Rectangle {
                width: Tokens.lockDotSize
                height: Tokens.lockDotSize
                radius: width / 2
                color: Theme.textPrimary

                scale: 0
                Component.onCompleted: scale = 1

                Behavior on scale {
                    NumberAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
                }
            }
        }
    }
}
