pragma ComponentBehavior: Bound

import QtQuick
import "../.."

Item {
    id: root

    required property real centerScale

    readonly property int clockSize: Math.round(Tokens.lockClockSize * centerScale)

    property string hourStr: Qt.formatTime(new Date(), "hh")
    property string minuteStr: Qt.formatTime(new Date(), "mm")
    property string secondStr: Qt.formatTime(new Date(), "ss")

    implicitWidth: hours.implicitWidth + sep.implicitWidth + minutes.implicitWidth
    implicitHeight: clockSize

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const now = new Date()
            root.hourStr = Qt.formatTime(now, "hh")
            root.minuteStr = Qt.formatTime(now, "mm")
            root.secondStr = Qt.formatTime(now, "ss")
        }
    }

    Text {
        id: hours
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.hourStr
        font.family: Theme.fontDisplay
        font.pixelSize: root.clockSize
        color: Theme.textPrimary
    }

    Text {
        id: sep
        anchors.left: hours.right
        anchors.verticalCenter: hours.verticalCenter
        anchors.verticalCenterOffset: -Math.round(root.clockSize * 0.08)
        text: "·"
        font.family: Theme.fontDisplay
        font.pixelSize: Math.round(root.clockSize * 0.72)
        color: Theme.accent
    }

    Text {
        id: minutes
        anchors.left: sep.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.minuteStr
        font.family: Theme.fontDisplay
        font.pixelSize: root.clockSize
        color: Theme.textPrimary
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: secLabel.implicitWidth + Tokens.paddingH * 2
        height: secLabel.implicitHeight + Tokens.spacingXss * 2
        radius: height / 2
        color: Theme.bgElevated
        border.color: Theme.borderIdle
        border.width: Tokens.strokeWidth

        Text {
            id: secLabel
            anchors.centerIn: parent
            text: root.secondStr
            font.family: Theme.fontMono
            font.pixelSize: Tokens.fontSizeSmall
            color: Theme.textSecondary
        }
    }
}
