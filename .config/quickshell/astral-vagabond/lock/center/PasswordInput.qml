pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../.."

Rectangle {
    id: root

    required property real centerScale
    required property int centerWidth
    required property var lock

    implicitWidth: centerWidth
    implicitHeight: Math.round(Tokens.lockInputHeight * centerScale)
    radius: height / 2
    color: Theme.bgSurface
    border.color: {
        const s = lock.pam.state
        if (s === lock.pam.stateFailed || s === lock.pam.stateError || s === lock.pam.stateMaxTries)
            return Theme.stateCritical
        if (lock.pam.buffer.length)
            return Theme.borderActive
        return Theme.borderIdle
    }
    border.width: Tokens.strokeWidthActive
    focus: true

    Component.onCompleted: forceActiveFocus()

    onActiveFocusChanged: {
        if (!activeFocus)
            forceActiveFocus()
    }

    Keys.onPressed: (event) => {
        if (root.lock.unlocking)
            return
        root.lock.pam.handleKey(event)
        event.accepted = true
    }

    Behavior on border.color {
        ColorAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        onClicked: root.forceActiveFocus()
    }

    RowLayout {
        id: input
        anchors.fill: parent
        anchors.leftMargin: Tokens.paddingH
        anchors.rightMargin: Tokens.paddingH
        spacing: Tokens.spacingSm

        Text {
            text: {
                if (root.lock.pam.passwd.active || root.lock.pam.howdy.active)
                    return "…"
                if (root.lock.pam.fprint.active)
                    return "⌘"
                return "⊘"
            }
            font.family: Theme.fontDisplay
            font.pixelSize: Tokens.fontSizeMedium
            color: Theme.textMuted
        }

        InputField {
            id: inputField
            Layout.fillWidth: true
            Layout.fillHeight: true
            centerScale: root.centerScale
            pam: root.lock.pam
        }

        Rectangle {
            id: enterButton
            Layout.preferredWidth: implicitHeight
            Layout.preferredHeight: Math.round((root.implicitHeight - Tokens.spacingXs * 2))
            implicitHeight: Layout.preferredHeight
            radius: width / 2
            color: root.lock.pam.buffer.length ? Theme.accent : Theme.bgElevated
            border.color: Theme.borderIdle
            border.width: Tokens.strokeWidth
            opacity: root.lock.pam.buffer.length ? 1 : Theme.opacityMuted

            Behavior on color {
                ColorAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic }
            }

            Text {
                anchors.centerIn: parent
                text: "→"
                font.family: Theme.fontDisplay
                font.pixelSize: Tokens.fontSizeMedium
                color: root.lock.pam.buffer.length ? Theme.bgPrimary : Theme.textMuted
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.lock.pam.buffer.length > 0
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.lock.pam.passwd.start()
            }
        }
    }
}
