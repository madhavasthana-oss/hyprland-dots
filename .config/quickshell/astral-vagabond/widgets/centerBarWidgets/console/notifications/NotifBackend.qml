// NotifBackend.qml --- inbox over Quickshell NotificationServer
import QtQuick
import "../../../.."

Item {
    id: root

    property string statusMsg: NotifServer.statusMsg
    property bool silent: Globals.notifSilent
    property bool dnd: Globals.notifDnd
    readonly property var notifications: NotifServer.inbox

    function refresh() {
        NotifServer.syncInbox()
        root.silent = Globals.notifSilent
        root.dnd = Globals.notifDnd
    }

    function dismissAll() {
        NotifServer.dismissAll()
    }

    function dismissId(id) {
        NotifServer.dismissId(id)
    }

    function setSilent(on) {
        NotifServer.setSilent(on)
        root.silent = Globals.notifSilent
    }

    function setDnd(on) {
        NotifServer.setDnd(on)
        root.dnd = Globals.notifDnd
    }

    function toggleSilent() { NotifServer.toggleSilent() }
    function toggleDnd()    { NotifServer.toggleDnd() }

    Connections {
        target: Globals
        function onNotifSilentChanged() { root.silent = Globals.notifSilent }
        function onNotifDndChanged() { root.dnd = Globals.notifDnd }
    }

    Connections {
        target: NotifServer
        function onStatusMsgChanged() { root.statusMsg = NotifServer.statusMsg }
    }

    Component.onCompleted: refresh()
}
