pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import ".."
import "../utils"

ColumnLayout {
    id: root

    required property var lock

    anchors.fill: parent
    anchors.margins: Tokens.paddingH
    spacing: Tokens.spacingSm

    Text {
        Layout.fillWidth: true
        text: NotifServer.inbox.count > 0
            ? (NotifServer.inbox.count + " notification" + (NotifServer.inbox.count === 1 ? "" : "s"))
            : "NOTIFICATIONS"
        font.family: Theme.fontDisplay
        font.pixelSize: Tokens.fontSizeLabel
        color: Theme.accent
        elide: Text.ElideRight
    }

    ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: Tokens.spacingXs
        model: NotifServer.inbox
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: MonoScrollBar {}

        delegate: Rectangle {
            required property string appName
            required property string summary
            required property string body
            required property string urgency

            width: list.width
            implicitHeight: nCol.implicitHeight + Tokens.paddingV * 2
            radius: Tokens.radiusSm
            color: urgency === "critical" ? Theme.bgElevated : Theme.bgPrimary
            border.color: urgency === "critical" ? Theme.stateCritical : Theme.borderIdle
            border.width: Tokens.strokeWidth

            ColumnLayout {
                id: nCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Tokens.paddingH
                spacing: Tokens.spacingXss

                Text {
                    Layout.fillWidth: true
                    text: appName
                    font.family: Theme.fontDisplay
                    font.pixelSize: Tokens.fontSizeTiny
                    color: Theme.textMuted
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: summary
                    font.family: Theme.fontDisplay
                    font.pixelSize: Tokens.fontSizeSmall
                    color: Theme.textPrimary
                    elide: Text.ElideRight
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                }
                Text {
                    Layout.fillWidth: true
                    visible: body.length > 0
                    text: body
                    font.family: Theme.fontMono
                    font.pixelSize: Tokens.fontSizeTiny
                    color: Theme.textSecondary
                    elide: Text.ElideRight
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                }
            }
        }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        visible: NotifServer.inbox.count === 0
        text: "No notifications"
        font.family: Theme.fontMono
        font.pixelSize: Tokens.fontSizeSmall
        color: Theme.textDim
    }
}
