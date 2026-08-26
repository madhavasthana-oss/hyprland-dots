pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../.."

Item {
    id: root

    required property int centerWidth

    property string faceUrl: ""
    property string userName: Quickshell.env("USER") || ""

    implicitWidth: Tokens.lockFaceSize
    implicitHeight: Tokens.lockFaceSize + nameLabel.implicitHeight + Tokens.spacingXs

    Process {
        running: true
        command: [
            "bash", "-c",
            "u=\"$USER\"; h=\"$HOME\";"
            + " if [ -f \"$h/.face\" ]; then printf 'file://%s/.face' \"$h\";"
            + " elif [ -f \"/var/lib/AccountsService/icons/$u\" ]; then printf 'file:///var/lib/AccountsService/icons/%s' \"$u\";"
            + " fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: root.faceUrl = text.trim()
        }
    }

    Rectangle {
        id: ring
        width: Tokens.lockFaceSize
        height: Tokens.lockFaceSize
        anchors.horizontalCenter: parent.horizontalCenter
        radius: width / 2
        color: Theme.bgElevated
        border.color: Theme.borderActive
        border.width: Tokens.strokeWidth
        clip: true

        Image {
            id: pfp
            anchors.fill: parent
            anchors.margins: Tokens.borderXss
            source: root.faceUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: status === Image.Ready
        }

        Text {
            anchors.centerIn: parent
            visible: pfp.status !== Image.Ready
            text: root.userName.length ? root.userName.charAt(0).toUpperCase() : "?"
            font.family: Theme.fontDisplay
            font.pixelSize: Tokens.fontSizeHuge
            color: Theme.accent
        }
    }

    Text {
        id: nameLabel
        anchors.top: ring.bottom
        anchors.topMargin: Tokens.spacingXs
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.centerWidth
        horizontalAlignment: Text.AlignHCenter
        text: root.userName
        font.family: Theme.fontMono
        font.pixelSize: Tokens.fontSizeSmall
        color: Theme.textSecondary
        elide: Text.ElideRight
    }
}
