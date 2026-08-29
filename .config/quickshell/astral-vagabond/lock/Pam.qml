pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

Scope {
    id: root

    enum PamState {
        None,
        Error,
        MaxTries,
        Failed
    }

    required property WlSessionLock lock

    readonly property alias passwd: passwd
    readonly property alias fprint: fprint
    readonly property alias howdy: howdy

    property string lockMessage
    property int state: Pam.None
    property string buffer: ""
    property bool capsOn: false
    property bool numOn: false

    readonly property int stateNone: Pam.None
    readonly property int stateError: Pam.Error
    readonly property int stateMaxTries: Pam.MaxTries
    readonly property int stateFailed: Pam.Failed

    readonly property bool enableFprint: true
    readonly property int maxFprintTries: 3
    readonly property bool enableHowdy: true
    readonly property int maxHowdyTries: 3

    signal flashMsg

    function handleKey(event) {
        if (passwd.active)
            return

        if (howdy.canAttempt && !howdy.active
                && (event.key === Qt.Key_Enter || event.key === Qt.Key_Return)
                && buffer.length === 0) {
            howdy.start()
            return
        }

        if (state === Pam.MaxTries)
            return

        if (howdy.active)
            howdy.abort()

        if (event.key === Qt.Key_Escape) {
            buffer = ""
            return
        }

        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            passwd.start()
        } else if (event.key === Qt.Key_Backspace) {
            if (event.modifiers & Qt.ControlModifier)
                buffer = ""
            else
                buffer = buffer.slice(0, -1)
        } else if (event.text && /^[^\x00-\x1F\x7F-\x9F]+$/.test(event.text)) {
            buffer += event.text
        }
    }

    PamContext {
        id: passwd
        // Same stack hyprlock uses (/etc/pam.d/hyprlock → login).
        config: "hyprlock"
        configDirectory: "/etc/pam.d"

        onMessageChanged: {
            if (message.startsWith("The account is locked"))
                root.lockMessage = message
            else if (root.lockMessage && message.endsWith(" left to unlock)"))
                root.lockMessage += "\n" + message
        }

        onResponseRequiredChanged: {
            if (!responseRequired)
                return
            respond(root.buffer)
            root.buffer = ""
        }

        onCompleted: (res) => {
            if (res === PamResult.Success) {
                root.lock.unlockRequested()
                return
            }

            if (res === PamResult.Error)
                root.state = Pam.Error
            else if (res === PamResult.MaxTries)
                root.state = Pam.MaxTries
            else if (res === PamResult.Failed)
                root.state = Pam.Failed

            root.flashMsg()
            pwdStateReset.restart()
        }
    }

    Timer {
        id: pwdStateReset
        interval: 4000
        onTriggered: {
            if (root.state !== Pam.MaxTries)
                root.state = Pam.None
        }
    }

    Connections {
        target: root.lock

        function onSecureChanged() {
            if (root.lock.secure) {
                fprint.checkAvailable()
                howdy.checkAvailable()
                fprint.reset()
                howdy.reset()
                root.buffer = ""
                root.state = Pam.None
                root.lockMessage = ""
            }
        }

        function onUnlockRequested() {
            fprint.abort()
            howdy.abort()
            passwd.abort()
        }
    }

    AuthMethod {
        id: fprint
        rootPam: root
        lock: root.lock
        configName: "fprint"
        availCommand: ["sh", "-c", "fprintd-list $USER"]
        retryOnFail: true
        enabled: root.enableFprint
        maxTries: root.maxFprintTries
    }

    AuthMethod {
        id: howdy
        rootPam: root
        lock: root.lock
        configName: "howdy"
        availCommand: ["sh", "-c", "command -v howdy"]
        enabled: root.enableHowdy
        maxTries: root.maxHowdyTries
    }

    Timer {
        interval: 400
        running: root.lock.locked
        repeat: true
        triggeredOnStart: true
        onTriggered: capsProc.running = true
    }

    Process {
        id: capsProc
        command: [
            "bash", "-c",
            "hyprctl devices 2>/dev/null"
            + " | grep -B 6 'main: yes'"
            + " | grep -E 'capsLock|numLock'"
            + " | awk '{print $1,$2}'"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                let caps = false
                let num = false
                for (let i = 0; i < lines.length; i++) {
                    const parts = lines[i].trim().split(/\s+/)
                    if (parts.length < 2)
                        continue
                    if (parts[0].indexOf("caps") !== -1)
                        caps = parts[1] === "yes"
                    if (parts[0].indexOf("num") !== -1)
                        num = parts[1] === "yes"
                }
                root.capsOn = caps
                root.numOn = num
            }
        }
    }
}
