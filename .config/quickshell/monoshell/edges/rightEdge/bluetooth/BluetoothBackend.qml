// BluetoothBackend.qml --- Quickshell.Bluetooth + bluetoothctl fallbacks
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import "../../.."

Item {
    id: root

    property bool powered: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.enabled : false
    property bool discovering: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.discovering : false
    property string statusMsg: ""
    property var adapter: Bluetooth.defaultAdapter

    readonly property var devices: Bluetooth.devices

    function setPowered(on) {
        if (!Bluetooth.defaultAdapter)
            return
        Bluetooth.defaultAdapter.enabled = on
        root.statusMsg = on ? "ADAPTER ONLINE" : "ADAPTER OFFLINE"
        Globals.toast(on ? "Bluetooth on" : "Bluetooth off", "", "Bluetooth")
    }

    function setDiscovering(on) {
        if (!Bluetooth.defaultAdapter)
            return
        Bluetooth.defaultAdapter.discovering = on
        root.statusMsg = on ? "SCANNING AIRSPACE..." : "SCAN HALTED"
        if (on)
            Globals.toast("Scanning", "Bluetooth discovery started", "Bluetooth")
    }

    function toggleDiscover() {
        setDiscovering(!root.discovering)
    }

    function connectDevice(dev) {
        if (!dev)
            return
        const label = dev.name || dev.deviceName || dev.address
        root.statusMsg = "LINKING " + label
        Globals.toast("Linking", label, "Bluetooth")
        if (dev.paired || dev.bonded) {
            dev.connect()
        } else {
            dev.pair()
            // connect after pair --- device signals will update UI
            pairThenConnect.target = dev
        }
    }

    function disconnectDevice(dev) {
        if (!dev)
            return
        const label = dev.name || dev.address
        dev.disconnect()
        root.statusMsg = "DROPPED " + label
        Globals.toast("Disconnected", label, "Bluetooth")
    }

    function forgetDevice(dev) {
        if (!dev)
            return
        const label = dev.name || dev.address
        dev.forget()
        root.statusMsg = "FORGOT " + label
        Globals.toast("Forgot device", label, "Bluetooth")
    }

    Connections {
        id: pairThenConnect
        target: null
        ignoreUnknownSignals: true
        function onPairedChanged() {
            if (target && target.paired)
                target.connect()
        }
        function onConnectedChanged() {
            if (target && target.connected) {
                root.statusMsg = "LINKED"
                const label = target.name || target.deviceName || target.address || ""
                Globals.toast("Linked", label, "Bluetooth")
            }
        }
    }

    Connections {
        target: Bluetooth
        function onDefaultAdapterChanged() {
            root.statusMsg = Bluetooth.defaultAdapter ? "ADAPTER READY" : "NO ADAPTER"
        }
    }
}
