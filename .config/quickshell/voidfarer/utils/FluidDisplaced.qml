import QtQuick
import ".."

Transition {
    NumberAnimation {
        properties: "x,y"
        duration: Tokens.animMedium
        easing.type: Easing.OutCubic
    }
}
