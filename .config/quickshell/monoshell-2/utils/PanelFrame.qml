// PanelFrame.qml --- panel body flush under the bar, with side hug-corners
// Layout:
//   [ TopRight corner ][ panel body (square top) ][ TopLeft corner ]
// The corners sit BESIDE the body (not above), so there is zero vertical gap.
import QtQuick
import ".."

Item {
    id: root

    property color fillColor: Theme.bgConsole
    property real fillOpacity: Theme.opacityConsole
    property color borderColor: Theme.borderConsole
    property real borderWidth: Tokens.stroke.base
    property int radius: Tokens.radius.xl
    property int hugSize: Tokens.rounding.screen
    property color hugColor: Qt.rgba(
        Theme.bgSurface.r, Theme.bgSurface.g, Theme.bgSurface.b, Theme.opacityBar
    )
    property bool hugBar: true

    // Content goes into the body rectangle
    default property alias contentData: body.data

    readonly property int side: hugBar ? hugSize : 0

    // Expose body for external size bindings
    readonly property alias bodyItem: body
    readonly property int bodyWidth: body.implicitWidth
    readonly property int bodyHeight: body.implicitHeight

    implicitWidth:  side + body.implicitWidth + side
    implicitHeight: body.implicitHeight

    // Left flank — TopRight curve (bar → free space left of panel)
    RoundCorner {
        visible: root.hugBar
        anchors {
            left: parent.left
            top: parent.top
        }
        implicitSize: root.hugSize
        color: root.hugColor
        corner: RoundCorner.CornerEnum.TopRight
    }

    Rectangle {
        id: body
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            leftMargin: root.side
            right: parent.right
            rightMargin: root.side
        }
        implicitWidth: Math.max(childrenRect.width, 1)
        implicitHeight: Math.max(childrenRect.height, 1)

        // Square top against the bar; only bottom corners round
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: root.radius
        bottomRightRadius: root.radius

        color: Qt.rgba(
            root.fillColor.r,
            root.fillColor.g,
            root.fillColor.b,
            root.fillOpacity
        )
        border.color: root.borderColor
        border.width: root.borderWidth
        clip: true
    }

    // Right flank — TopLeft curve (bar → free space right of panel)
    RoundCorner {
        visible: root.hugBar
        anchors {
            right: parent.right
            top: parent.top
        }
        implicitSize: root.hugSize
        color: root.hugColor
        corner: RoundCorner.CornerEnum.TopLeft
    }
}
