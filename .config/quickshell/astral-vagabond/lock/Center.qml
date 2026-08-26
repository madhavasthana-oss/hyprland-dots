import "center"
import QtQuick
import QtQuick.Layouts
import ".."

ColumnLayout {
    id: root

    required property var lock
    readonly property real centerScale: Math.min(1, (lock.screen ? lock.screen.height : 1440) / 1440)
    readonly property int centerWidth: Math.round(Tokens.lockCenterWidth * centerScale)

    Layout.preferredWidth: centerWidth
    Layout.fillWidth: false
    Layout.fillHeight: true
    spacing: Tokens.spacingLg

    Clock {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Tokens.paddingV
        centerScale: root.centerScale
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDate(new Date(), "dddd  ·  d MMM yyyy").toUpperCase()
        font.family: Theme.fontDisplay
        font.pixelSize: Tokens.fontSizeSmall
        color: Theme.textSecondary

        Timer {
            interval: 30000
            running: true
            repeat: true
            onTriggered: parent.text = Qt.formatDate(new Date(), "dddd  ·  d MMM yyyy").toUpperCase()
        }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: "LOCKED"
        font.family: Theme.fontDisplay
        font.pixelSize: Tokens.fontSizeLabel
        color: Theme.textMuted
    }

    ProfilePic {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: Tokens.spacingMd
        Layout.bottomMargin: Tokens.spacingSm
        centerWidth: root.centerWidth
    }

    PasswordInput {
        Layout.alignment: Qt.AlignHCenter
        centerScale: Math.max(0.8, root.centerScale)
        centerWidth: root.centerWidth
        lock: root.lock
    }

    StateMessage {
        Layout.fillWidth: true
        pam: root.lock.pam
    }

    Item { Layout.fillHeight: true }
}
