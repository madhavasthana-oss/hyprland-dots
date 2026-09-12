import QtQuick
import ".."

Transition {
    SequentialAnimation {
        PropertyAction { property: "opacity"; value: 0 }
        PauseAnimation {
            duration: (ViewTransition.index < 10 ? ViewTransition.index : 10) * Tokens.animStagger
        }
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
}
