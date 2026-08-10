// QuickLaunch.qml --- bar strip between weather and telemetry
// Dashboard · [settings | wifi | bluetooth] · Media
import QtQuick
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects
import ".."

Item {
    id: root
    clip: true

    readonly property int iconSide: Math.max(
        Tokens.icon.medium,
        Math.round(Tokens.bar.height * 0.55)
    )
    readonly property int hit: Math.max(iconSide + Tokens.spacing.xs, Tokens.bar.height - 4)

    function isCenter(panel) {
        return Globals.activeCenterPanel === panel
    }

    function isConsolePage(page) {
        return Globals.activeCenterPanel === "console" && Globals.activeEdgePanel === page
    }

    // Compact tinted icon button
    component LaunchBtn: Item {
        id: btn
        property string iconSource: ""
        property string tip: ""
        property bool active: false
        property bool hovered: mouse.containsMouse
        signal activated()

        width: root.hit
        height: root.hit

        Rectangle {
            anchors.centerIn: parent
            width: root.iconSide + (btn.hovered || btn.active ? 4 : 0)
            height: width
            radius: Tokens.radius.sm
            color: btn.active
                ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14)
                : (btn.hovered ? Theme.bgElevated : "transparent")
            border.width: 0

            Behavior on color {
                ColorAnimation { duration: Tokens.anim.fast; easing.type: Easing.OutCubic }
            }
            Behavior on width {
                NumberAnimation { duration: Tokens.anim.fast; easing.type: Easing.OutCubic }
            }
        }

        Image {
            id: glyph
            anchors.centerIn: parent
            width: root.iconSide
            height: root.iconSide
            source: btn.iconSource
            sourceSize: Qt.size(width * 2, height * 2)
            fillMode: Image.PreserveAspectFit
            smooth: true
            visible: false
            asynchronous: true
        }

        ColorOverlay {
            anchors.fill: glyph
            source: glyph
            color: btn.active
                ? Theme.accent
                : (btn.hovered ? Theme.textPrimary : Theme.textMuted)

            Behavior on color {
                ColorAnimation { duration: Tokens.anim.fast; easing.type: Easing.OutCubic }
            }
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.activated()
            ToolTip.visible: containsMouse && btn.tip.length > 0
            ToolTip.delay: 280
            ToolTip.text: btn.tip
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: Tokens.spacing.sm

        // 1. Dashboard
        LaunchBtn {
            Layout.alignment: Qt.AlignVCenter
            iconSource: Theme.iconDashboard
            tip: "Dashboard"
            active: root.isCenter("dashboard")
            onActivated: Globals.toggleCenterPanel("dashboard")
        }

        // 2. Console cluster — settings · wifi · bluetooth
        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: Tokens.spacing.xss

            LaunchBtn {
                iconSource: Theme.iconSettings
                tip: "Settings"
                active: root.isConsolePage("settings")
                onActivated: Globals.toggleEdgePanel("settings")
            }
            LaunchBtn {
                iconSource: Theme.iconWifi
                tip: "Wi‑Fi"
                active: root.isConsolePage("wifi")
                onActivated: Globals.toggleEdgePanel("wifi")
            }
            LaunchBtn {
                iconSource: Theme.iconBluetooth
                tip: "Bluetooth"
                active: root.isConsolePage("bluetooth")
                onActivated: Globals.toggleEdgePanel("bluetooth")
            }
        }

        // 3. Media
        LaunchBtn {
            Layout.alignment: Qt.AlignVCenter
            iconSource: Theme.iconMedia
            tip: "Media"
            active: root.isCenter("media")
            onActivated: Globals.toggleCenterPanel("media")
        }
    }
}
