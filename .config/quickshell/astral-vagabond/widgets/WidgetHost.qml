// WidgetHost.qml --- one body per center-bar button (no shared tab chrome)
import QtQuick
import QtQuick.Layouts
import ".."
import "centerBarWidgets"
import "centerBarWidgets/console/network"
import "centerBarWidgets/console/bluetooth"
import "centerBarWidgets/console/settings"
import "centerBarWidgets/console/notifications"

Item {
    id: root
    clip: true
    focus: true

    readonly property var widgetOrder: [
        "dashboard",
        "wifi",
        "bluetooth",
        "settings",
        "notifications",
        "media"
    ]

    function grabActiveFocus() {
        const id = Globals.activeWidget
        if (id === "wifi")
            wifiPage.grabListFocus()
        else if (id === "bluetooth")
            btPage.grabListFocus()
        else if (id === "notifications")
            notifPage.grabListFocus()
        else
            root.forceActiveFocus()
    }

    Keys.onEscapePressed: Globals.closeWidget()

    Connections {
        target: Globals
        function onActiveWidgetChanged() {
            if (Globals.activeWidget !== "")
                Qt.callLater(root.grabActiveFocus)
        }
    }

    Component.onCompleted: {
        if (Globals.activeWidget !== "")
            grabActiveFocus()
    }

    StackLayout {
        id: stack
        anchors.fill: parent
        anchors.margins: Tokens.paddingH
        clip: true

        currentIndex: {
            const idx = root.widgetOrder.indexOf(Globals.activeWidget)
            return idx < 0 ? 0 : idx
        }

        DashboardWidget {
            id: dashboardPage
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 0
            Layout.minimumHeight: 0
        }

        NetworkFrontend {
            id: wifiPage
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 0
            Layout.minimumHeight: 0
        }

        BluetoothFrontend {
            id: btPage
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 0
            Layout.minimumHeight: 0
        }

        SettingsFrontend {
            id: settingsPage
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 0
            Layout.minimumHeight: 0
            onRequestClose: Globals.closeWidget()
        }

        NotifFrontend {
            id: notifPage
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 0
            Layout.minimumHeight: 0
        }

        MediaWidget {
            id: mediaPage
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 0
            Layout.minimumHeight: 0
        }
    }
}
