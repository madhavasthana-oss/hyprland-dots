import QtQuick
import ".."

Transition {
    ParallelAnimation {
        NumberAnimation {
            property: "opacity"
            to: 0
            duration: Tokens.animInstant
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            property: "scale"
            to: 0.96
            duration: Tokens.animInstant
            easing.type: Easing.InQuad
        }
    }
}
