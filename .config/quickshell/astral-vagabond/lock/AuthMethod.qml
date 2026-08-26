pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

Scope {
    id: ctx

    required property var rootPam
    required property WlSessionLock lock
    required property bool enabled
    required property int maxTries
    required property string configName
    required property var availCommand
    property bool retryOnFail: false

    property bool available: false
    property int tries: 0
    property int errorTries: 0
    property int state: 0
    readonly property bool canAttempt: available && enabled && lock.secure && tries < maxTries
    readonly property alias active: pam.active
    readonly property alias message: pam.message

    function checkAvailable() {
        availProc.running = true
    }

    function start() {
        pam.start()
    }

    function abort() {
        pam.abort()
    }

    function reset() {
        tries = 0
        errorTries = 0
        state = 0
    }

    PamContext {
        id: pam
        config: ctx.configName
        configDirectory: Quickshell.shellDir + "/assets/pam.d"

        onCompleted: (res) => {
            if (!ctx.available)
                return

            if (res === PamResult.Success) {
                ctx.lock.unlockRequested()
                return
            }

            if (res === PamResult.Error) {
                ctx.state = ctx.rootPam.stateError
                ctx.errorTries++
                if (ctx.errorTries < 5) {
                    abort()
                    errorRetry.restart()
                }
            } else if (res === PamResult.MaxTries || res === PamResult.Failed) {
                ctx.tries++
                if (ctx.tries < ctx.maxTries) {
                    ctx.state = ctx.rootPam.stateFailed
                    if (ctx.retryOnFail)
                        start()
                } else {
                    ctx.state = ctx.rootPam.stateMaxTries
                    abort()
                }
            }

            ctx.rootPam.flashMsg()
            stateReset.restart()
        }
    }

    Timer {
        id: errorRetry
        interval: 800
        onTriggered: pam.start()
    }

    Timer {
        id: stateReset
        interval: 4000
        onTriggered: {
            if (ctx.state !== ctx.rootPam.stateMaxTries)
                ctx.state = ctx.rootPam.stateNone
            ctx.errorTries = 0
        }
    }

    Process {
        id: availProc
        command: ctx.availCommand
        onExited: (code) => {
            ctx.available = code === 0
            if (ctx.canAttempt && ctx.retryOnFail)
                ctx.start()
        }
    }
}
