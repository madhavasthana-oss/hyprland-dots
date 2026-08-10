// BarHugCorners.qml --- concave corners that connect surfaces to the bar
//
//  mode "screen" (default): under a full-width bar
//      TopLeft  @ left edge, TopRight @ right edge
//
//  mode "panel": flanking a dropdown that hangs from the bar
//      TopRight @ left of panel, TopLeft @ right of panel
//      so the bar color curves into the free space beside the panel
//
import QtQuick
import ".."

Item {
    id: root

    property int size: Tokens.rounding.screen
    property color color: Theme.bgSurface
    // "screen" | "panel"
    property string mode: "screen"
    property bool active: true

    // Screen mode occupies a full-width band; panel mode is a zero-size
    // host — callers place the two corners themselves via the aliases below
    // when they need custom layout. For simple use, set mode and fill width.
    implicitWidth:  mode === "panel" ? size * 2 : 0
    implicitHeight: active ? size : 0
    height: implicitHeight
    clip: false
    visible: active

    readonly property int leftCornerType: mode === "panel"
        ? RoundCorner.CornerEnum.TopRight
        : RoundCorner.CornerEnum.TopLeft

    readonly property int rightCornerType: mode === "panel"
        ? RoundCorner.CornerEnum.TopLeft
        : RoundCorner.CornerEnum.TopRight

    RoundCorner {
        id: leftCorner
        anchors {
            left: parent.left
            top: parent.top
        }
        implicitSize: root.size
        color: root.color
        corner: root.leftCornerType
    }

    RoundCorner {
        id: rightCorner
        anchors {
            right: parent.right
            top: parent.top
        }
        implicitSize: root.size
        color: root.color
        corner: root.rightCornerType
    }
}
