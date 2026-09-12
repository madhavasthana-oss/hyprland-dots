import QtQuick
import ".."

Transition {
    NumberAnimation {
        properties: "x,y"
        duration: Tokens.animFast
        easing.type: Easing.OutQuad
    }
}
