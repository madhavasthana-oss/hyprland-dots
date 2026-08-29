import QtQuick
import ".."

Transition {
    ParallelAnimation {
        NumberAnimation {
            property: "opacity"
            to: 0
            duration: Tokens.animFast
            easing.type: Easing.InCubic
        }
        NumberAnimation {
            property: "scale"
            to: 0.94
            duration: Tokens.animFast
            easing.type: Easing.InCubic
        }
    }
}
