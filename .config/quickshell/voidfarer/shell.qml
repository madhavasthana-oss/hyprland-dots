import QtQuick
import Quickshell
import Quickshell.Wayland
import "bars"

ShellRoot {
    id: shellRoot

    // Single top bar. Left / center / right bar files stay on disk
    // and are not instantiated here.
    PanelWindow {
        id: topBarWindow
        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: Tokens.topBarHeight + Tokens.topBarCorner
        color: "transparent"
        exclusiveZone: Tokens.topBarHeight
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "voidfarer-top"

        TopBar {
            anchors.fill: parent
        }
    }
}
