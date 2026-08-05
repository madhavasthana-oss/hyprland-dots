// NetworkBackend.qml --- nmcli scan / connect / radio
import QtQuick
import Quickshell
import Quickshell.Io
import "../../.."

Item {
    id: root

    property bool wifiEnabled: true
    property bool scanning: false
    property bool connecting: false
    property string statusMsg: ""
    property string pendingSsid: ""
    property bool needsPassword: false

    ListModel { id: netModel }
    property alias networks: netModel

    Component.onCompleted: {
        radioQuery.running = true
        rescan()
    }

    function rescan() {
        root.scanning = true
        root.statusMsg = "SCANNING..."
        rescanProc.running = true
    }

    function setWifiEnabled(on) {
        radioSet.command = ["nmcli", "radio", "wifi", on ? "on" : "off"]
        radioSet.wantOn = on
        radioSet.running = true
    }

    function connectTo(ssid, security, inUse) {
        if (inUse) {
            root.statusMsg = "ALREADY LINKED"
            return
        }
        root.pendingSsid = ssid
        root.connecting = true
        root.needsPassword = false
        root.statusMsg = "LINKING " + ssid + "..."
        // Try without password first (known / open)
        connectKnown.ssid = ssid
        connectKnown.running = true
    }

    function connectWithPassword(pass) {
        if (!root.pendingSsid || pass.length === 0)
            return
        root.connecting = true
        root.needsPassword = false
        root.statusMsg = "AUTH " + root.pendingSsid + "..."
        connectPass.ssid = root.pendingSsid
        connectPass.psk = pass
        connectPass.running = true
    }

    function cancelPassword() {
        root.needsPassword = false
        root.pendingSsid = ""
        root.connecting = false
        root.statusMsg = ""
    }

    function disconnectActive() {
        disconnectProc.running = true
    }

    function parseList(text) {
        netModel.clear()
        const seen = ({})
        const lines = text.split("\n")
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim()
            if (!line.length)
                continue
            // fields: SSID:SIGNAL:SECURITY:IN-USE:BSSID  (BSSID has escaped colons)
            // Use split with limit --- BSSID is last and contains \:
            const parts = line.split(":")
            if (parts.length < 4)
                continue
            const ssid = parts[0]
            const signal = parseInt(parts[1]) || 0
            const security = parts[2] || ""
            const inUse = parts[3] === "*"
            // empty SSID = hidden AP
            const key = ssid.length ? ssid : ("hidden:" + parts.slice(4).join(":"))
            if (seen[key] && !inUse)
                continue
            seen[key] = true
            netModel.append({
                ssid: ssid.length ? ssid : "(hidden)",
                signal: signal,
                security: security.length ? security : "OPEN",
                inUse: inUse,
                rawSsid: ssid
            })
        }
        // connected first, then by signal
        // ListModel has no sort --- rebuild sorted
        let rows = []
        for (let j = 0; j < netModel.count; j++)
            rows.push(JSON.parse(JSON.stringify(netModel.get(j))))
        rows.sort((a, b) => {
            if (a.inUse !== b.inUse)
                return a.inUse ? -1 : 1
            return b.signal - a.signal
        })
        netModel.clear()
        for (let k = 0; k < rows.length; k++)
            netModel.append(rows[k])
    }

    Process {
        id: radioQuery
        command: ["nmcli", "-t", "-f", "WIFI", "radio"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = text.trim().toLowerCase() === "enabled"
            }
        }
    }

    Process {
        id: radioSet
        property bool wantOn: true
        command: ["nmcli", "radio", "wifi", "on"]
        stdout: StdioCollector { onStreamFinished: radioQuery.running = true }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length)
                    root.statusMsg = text.trim()
                radioQuery.running = true
            }
        }
        onExited: (code) => {
            radioQuery.running = true
            if (code === 0) {
                Globals.toast(wantOn ? "Wi‑Fi on" : "Wi‑Fi off", "", "Network")
                root.rescan()
            } else {
                Globals.toast("Wi‑Fi toggle failed", root.statusMsg, "Network")
            }
        }
    }

    Process {
        id: rescanProc
        command: ["nmcli", "device", "wifi", "rescan"]
        onExited: listProc.running = true
    }

    Process {
        id: listProc
        command: ["nmcli", "-t", "-f", "SSID,SIGNAL,SECURITY,IN-USE", "device", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.parseList(text)
                root.scanning = false
                root.statusMsg = netModel.count + " NETWORKS"
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                root.scanning = false
                if (text.trim().length)
                    root.statusMsg = text.trim()
            }
        }
    }

    Process {
        id: connectKnown
        property string ssid: ""
        command: ["nmcli", "device", "wifi", "connect", ssid]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.toLowerCase().indexOf("error") >= 0 || text.toLowerCase().indexOf("secrets") >= 0) {
                    root.needsPassword = true
                    root.connecting = false
                    root.statusMsg = "PASSWORD REQUIRED"
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const t = text.toLowerCase()
                if (t.indexOf("secret") >= 0 || t.indexOf("password") >= 0 || t.indexOf("802-11") >= 0) {
                    root.needsPassword = true
                    root.connecting = false
                    root.statusMsg = "PASSWORD REQUIRED"
                } else if (text.trim().length) {
                    // still might need password
                    root.needsPassword = true
                    root.connecting = false
                    root.statusMsg = "PASSWORD REQUIRED"
                }
            }
        }
        onExited: (code) => {
            if (code === 0) {
                root.connecting = false
                root.needsPassword = false
                root.statusMsg = "LINKED: " + connectKnown.ssid
                Globals.toast("Connected", connectKnown.ssid, "Network")
                root.rescan()
            } else if (!root.needsPassword) {
                root.needsPassword = true
                root.connecting = false
                root.statusMsg = "PASSWORD REQUIRED"
            }
        }
    }

    Process {
        id: connectPass
        property string ssid: ""
        property string psk: ""
        command: ["nmcli", "device", "wifi", "connect", ssid, "password", psk]
        onExited: (code) => {
            root.connecting = false
            if (code === 0) {
                root.needsPassword = false
                root.pendingSsid = ""
                root.statusMsg = "LINKED: " + connectPass.ssid
                Globals.toast("Connected", connectPass.ssid, "Network")
                root.rescan()
            } else {
                root.needsPassword = true
                root.statusMsg = "AUTH FAILED"
                Globals.toast("Auth failed", connectPass.ssid, "Network")
            }
        }
    }

    // Resolve wifi iface then disconnect
    Process {
        id: ifaceQuery
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n")
                for (let i = 0; i < lines.length; i++) {
                    const p = lines[i].split(":")
                    if (p.length >= 3 && p[1] === "wifi" && p[2].indexOf("connect") >= 0) {
                        disconnectNamed.iface = p[0]
                        disconnectNamed.running = true
                        return
                    }
                }
                root.statusMsg = "NO ACTIVE LINK"
            }
        }
    }

    Process {
        id: disconnectNamed
        property string iface: ""
        command: ["nmcli", "device", "disconnect", iface]
        onExited: (code) => {
            root.statusMsg = code === 0 ? "DISCONNECTED" : "DISCONNECT FAILED"
            Globals.toast(
                code === 0 ? "Disconnected" : "Disconnect failed",
                "",
                "Network"
            )
            root.rescan()
        }
    }

    function disconnectWifi() {
        ifaceQuery.running = true
    }
}
