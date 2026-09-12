import QtQuick
import ".."

Transition {
    ParallelAnimation {
        NumberAnimation {
            property: "opacity"
            from: 0
            to: 1
            duration: Tokens.animFast
            easing.type: Easing.OutQuad
        }
        NumberAnimation {
            property: "scale"
            from: 0.96
            to: 1
            duration: Tokens.animFast
            easing.type: Easing.OutQuad
        }
    }
}
