pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import ".."

Scope {
    id: root

    property alias lock: sessionLock
    property alias pam: pam

    function lockNow() {
        sessionLock.locked = true
    }

    WlSessionLock {
        id: sessionLock

        signal unlockRequested

        LockSurface {
            lock: sessionLock
            pam: pam
        }
    }

    Pam {
        id: pam
        lock: sessionLock
    }

    // Force a screencopy before the first lock so the ICC backend is warm.
    // First capture during lock often fails (async + compositor refuses it).
    Loader {
        asynchronous: true
        active: true
        onLoaded: active = false
        sourceComponent: ScreencopyView {
            captureSource: Quickshell.screens[0]
            live: false
        }
    }

    Connections {
        target: Globals
        function onLockRequested() {
            root.lockNow()
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            root.lockNow()
        }

        function unlock(): void {
            sessionLock.unlockRequested()
        }

        function isLocked(): bool {
            return sessionLock.locked
        }
    }
}
