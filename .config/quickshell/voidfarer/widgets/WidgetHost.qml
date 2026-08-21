// WidgetHost.qml --- one popup body per bar button (no shared tab chrome)
import QtQuick
import QtQuick.Layouts
import ".."
import "centerBarWidgets"
import "centerBarWidgets/console/network"
import "centerBarWidgets/console/bluetooth"
import "centerBarWidgets/console/settings"
import "centerBarWidgets/console/notifications"
import "rightBarWidgets/system/CPU"
import "rightBarWidgets/system/GPU"

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
        "media",
        "cpu",
        "gpu"
    ]

    implicitWidth: currentWidth
    implicitHeight: currentHeight

    readonly property int currentWidth: {
        switch (Globals.activeWidget) {
        case "dashboard":
            return Tokens.centerSmallerWidth
        case "media":
            return Math.round(Tokens.centerSmallerWidth * 0.68)
        case "cpu":
        case "gpu":
            return Tokens.rightWidth
        case "wifi":
        case "bluetooth":
        case "settings":
        case "notifications":
            return Tokens.edgePanelWidth
        default:
            return Tokens.edgePanelWidth
        }
    }

    readonly property int currentHeight: {
        switch (Globals.activeWidget) {
        case "dashboard":
        case "media":
            return Tokens.centerExpandedHeight
        case "cpu":
        case "gpu":
            return Tokens.rightWidth
        default:
            return Tokens.edgeWidgetHeight
        }
    }

    function grabActiveFocus() {
        const id = Globals.activeWidget
        if (id === "wifi")
            wifiPage.grabListFocus()
        else if (id === "bluetooth")
            btPage.grabListFocus()
        else if (id === "notifications")
            notifPage.grabListFocus()
        else if (id === "cpu")
            cpuPage.grabListFocus()
        else if (id === "gpu")
            gpuPage.grabFocus()
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

        CPUFrontend {
            id: cpuPage
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 0
            Layout.minimumHeight: 0
        }

        GPUFrontend {
            id: gpuPage
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 0
            Layout.minimumHeight: 0
        }
    }
}
