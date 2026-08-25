// NotifToasts.qml --- on-screen stack (inner chrome; parent surface stays fixed)
import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

Item {
    id: root
    width: Tokens.toastWidth
    height: col.implicitHeight

    function iconSource(ic) {
        const s = String(ic || "")
        if (!s.length)
            return ""
        if (s.indexOf("/") === 0 || s.indexOf("file:") === 0 || s.indexOf("image:") === 0)
            return s
        return Quickshell.iconPath(s, true) || ""
    }

    Column {
        id: col
        width: parent.width
        spacing: Tokens.spacingXs

        Repeater {
            model: NotifServer.toasts

            delegate: Item {
                id: wrap
                width: Tokens.toastWidth
                height: card.height

                property bool ready: false
                Component.onCompleted: ready = true

                Rectangle {
                    id: card
                    width: parent.width
                    height: Math.max(Tokens.toastCardMinHeight, bodyCol.implicitHeight + 2 * Tokens.paddingV)
                    radius: Tokens.radiusMd
                    color: Qt.rgba(Theme.bgConsole.r, Theme.bgConsole.g, Theme.bgConsole.b, Theme.opacityConsole)
                    border.width: Tokens.strokeWidth
                    border.color: model.urgency === "critical" ? Theme.stateCritical : Theme.borderActive
                    x: wrap.ready ? 0 : Tokens.spacingLg
                    opacity: wrap.ready ? 1 : 0

                    Behavior on x {
                        NumberAnimation { duration: Tokens.animMedium; easing.type: Easing.OutCubic }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: Tokens.animMedium; easing.type: Easing.OutCubic }
                    }

                    Timer {
                        interval: Math.max(1, model.timeoutMs)
                        running: model.timeoutMs > 0
                        repeat: false
                        onTriggered: NotifServer.hideToast(model.notifId)
                    }

                    RowLayout {
                        id: bodyCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Tokens.paddingH
                        spacing: Tokens.spacingXs

                        Image {
                            Layout.preferredWidth: Tokens.iconSizeLarge + Tokens.spacingXs
                            Layout.preferredHeight: Tokens.iconSizeLarge + Tokens.spacingXs
                            Layout.alignment: Qt.AlignTop
                            visible: model.icon && String(model.icon).length
                            source: root.iconSource(model.icon)
                            sourceSize: Qt.size(width * 2, height * 2)
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            smooth: true
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacingXss

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    Layout.fillWidth: true
                                    text: model.appName
                                    font.family: Theme.fontMono
                                    font.pixelSize: Tokens.fontSizeTiny
                                    color: Theme.textDim
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: "✕"
                                    font.pixelSize: Tokens.fontSizeSmall
                                    color: dismissMouse.containsMouse ? Theme.accent : Theme.textDim
                                    MouseArea {
                                        id: dismissMouse
                                        anchors.fill: parent
                                        anchors.margins: -Tokens.spacingXs
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: NotifServer.dismissId(model.notifId)
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: model.summary
                                font.family: Theme.fontDisplay
                                font.pixelSize: Tokens.fontSizeLabel
                                color: Theme.textPrimary
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: model.body && String(model.body).length
                                text: model.body
                                font.family: Theme.fontMono
                                font.pixelSize: Tokens.fontSizeTiny
                                color: Theme.textSecondary
                                wrapMode: Text.Wrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotifServer.invokeId(model.notifId)
                    }
                }
            }
        }
    }
}
