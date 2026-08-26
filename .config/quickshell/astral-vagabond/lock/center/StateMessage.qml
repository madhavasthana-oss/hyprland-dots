pragma ComponentBehavior: Bound

import QtQuick
import "../.."

Item {
    id: root

    required property var pam

    readonly property string msg: {
        const err = pam.stateError
        const fail = pam.stateFailed
        const max = pam.stateMaxTries

        if (pam.fprint.state === err)
            return "FP ERROR: " + pam.fprint.message
        if (pam.howdy.state === err)
            return "FACE ERROR: " + pam.howdy.message
        if (pam.state === err)
            return "PW ERROR: " + pam.passwd.message

        if (pam.state !== max) {
            if (pam.fprint.state === fail)
                return "Fingerprint not recognized (" + pam.fprint.tries + "/" + pam.maxFprintTries + "). Try again or use password."
            if (pam.howdy.state === fail)
                return "Face not recognized (" + pam.howdy.tries + "/" + pam.maxHowdyTries + "). Try again or use password."
        } else {
            if (pam.fprint.state === fail)
                return "Fingerprint not recognized (" + pam.fprint.tries + "/" + pam.maxFprintTries + ")."
            if (pam.howdy.state === fail)
                return "Face not recognized (" + pam.howdy.tries + "/" + pam.maxHowdyTries + ")."
        }

        if (pam.lockMessage)
            return pam.lockMessage

        if (pam.state === fail) {
            if (pam.fprint.available && pam.fprint.state !== max)
                return "Incorrect password. Try again or use fingerprint."
            if (pam.howdy.available && pam.howdy.state !== max)
                return "Incorrect password. Try again or use face."
            return "Incorrect password. Try again."
        }

        if (pam.state === max) {
            if (pam.fprint.available && pam.fprint.state !== max)
                return "Maximum password attempts reached. Use fingerprint."
            if (pam.howdy.available && pam.howdy.state !== max)
                return "Maximum password attempts reached. Use face."
            if (pam.fprint.available || pam.howdy.available)
                return "Maximum attempts for all authentication methods reached."
            return "Maximum password attempts reached."
        }
        if (pam.fprint.state === max)
            return "Maximum fingerprint attempts reached. Use password."
        if (pam.howdy.state === max)
            return "Maximum face attempts reached. Use password."

        return ""
    }

    readonly property string stateMsg: {
        const bits = []
        if (pam.capsOn)
            bits.push("CAPS LOCK")
        if (pam.numOn)
            bits.push("NUM LOCK")
        return bits.join("  ·  ")
    }

    implicitHeight: Math.max(message.implicitHeight, stateMessage.implicitHeight)

    Text {
        id: stateMessage
        anchors.left: parent.left
        anchors.right: parent.right
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        text: root.stateMsg
        font.family: Theme.fontMono
        font.pixelSize: Tokens.fontSizeTiny
        color: Theme.accentWarm
        opacity: root.stateMsg.length && !root.msg.length ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
        }
    }

    Text {
        id: message
        anchors.left: parent.left
        anchors.right: parent.right
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        text: root.msg
        font.family: Theme.fontMono
        font.pixelSize: Tokens.fontSizeTiny
        color: Theme.stateCritical
        opacity: root.msg.length ? 1 : 0
        scale: root.msg.length ? 1 : 0.92

        Behavior on opacity {
            NumberAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
        }

        Connections {
            target: root.pam
            function onFlashMsg() {
                flashAnim.restart()
            }
        }

        SequentialAnimation {
            id: flashAnim
            loops: 2
            NumberAnimation {
                target: message
                property: "opacity"
                to: 0.3
                duration: 80
            }
            NumberAnimation {
                target: message
                property: "opacity"
                to: 1
                duration: 80
            }
        }
    }
}
