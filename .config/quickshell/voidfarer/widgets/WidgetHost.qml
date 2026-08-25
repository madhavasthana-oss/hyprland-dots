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

    implicitWidth: Globals.activeWidget === ""
        ? Tokens.widgetWifiWidth
        : Tokens.widgetWidthFor(Globals.activeWidget)
    implicitHeight: Globals.activeWidget === ""
        ? 0
        : Tokens.widgetHeightFor(Globals.activeWidget)

    property string displayedWidget: Globals.activeWidget
    property string pendingWidget: ""

    function grabActiveFocus() {
        const id = root.displayedWidget
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

    function applyDisplayed(id) {
        displayedWidget = id
        if (id !== "")
            Qt.callLater(root.grabActiveFocus)
    }

    Keys.onEscapePressed: Globals.closeWidget()

    Connections {
        target: Globals
        function onActiveWidgetChanged() {
            const next = Globals.activeWidget
            const prev = root.displayedWidget
            swapAnim.stop()
            if (next === prev) {
                stack.opacity = next === "" ? 0 : 1
                return
            }
            if (prev === "" || next === "") {
                stack.opacity = next === "" ? 0 : 1
                root.applyDisplayed(next)
                return
            }
            root.pendingWidget = next
            swapAnim.start()
        }
    }

    SequentialAnimation {
        id: swapAnim
        NumberAnimation {
            target: stack
            property: "opacity"
            to: 0
            duration: Tokens.animFast
            easing.type: Easing.InCubic
        }
        ScriptAction {
            script: root.applyDisplayed(root.pendingWidget)
        }
        NumberAnimation {
            target: stack
            property: "opacity"
            to: 1
            duration: Tokens.animFast
            easing.type: Easing.OutCubic
        }
    }

    Component.onCompleted: {
        stack.opacity = Globals.activeWidget === "" ? 0 : 1
        if (Globals.activeWidget !== "")
            grabActiveFocus()
    }

    StackLayout {
        id: stack
        anchors.fill: parent
        anchors.margins: Tokens.paddingH
        clip: true
        opacity: 1

        currentIndex: {
            const idx = root.widgetOrder.indexOf(root.displayedWidget)
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
