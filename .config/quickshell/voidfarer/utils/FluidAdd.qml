import QtQuick
import ".."

Transition {
    ParallelAnimation {
        NumberAnimation {
            property: "opacity"
            from: 0
            to: 1
            duration: Tokens.animMedium
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            property: "scale"
            from: 0.94
            to: 1
            duration: Tokens.animMedium
            easing.type: Easing.OutCubic
        }
    }
}
