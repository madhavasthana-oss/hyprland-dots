// TopBar.qml --- empty full-width cutout bar (shape only)
import QtQuick
import "../utils"
import ".."

Item {
    id: root

    readonly property color barColor: Theme.bgSurface
    readonly property int barHeight: Tokens.topBarHeight
    readonly property int cornerSize: Tokens.topBarCorner

    width: parent ? parent.width : Tokens.topBarWidth
    height: parent ? parent.height : (barHeight + cornerSize)

    Rectangle {
        id: body
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.barHeight
        color: root.barColor
    }

    BarCorner {
        anchors.left: parent.left
        anchors.top: body.bottom
        corner: "topLeft"
        color: root.barColor
        implicitSize: root.cornerSize
    }

    BarCorner {
        anchors.right: parent.right
        anchors.top: body.bottom
        corner: "topRight"
        color: root.barColor
        implicitSize: root.cornerSize
    }
}
