// SettingsBackend.qml --- brightness, kbd, audio, capture tools, power inhibit, wallust/wallpaper
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../../../.."

Item {
    id: root

    property int brightness: 50       // percent 0-100
    property int kbdBrightness: 0     // 0-max
    property int kbdMax: 2
    property int volume: 0
    property bool muted: false
    property bool recording: Globals.screenRecording
    property string statusMsg: ""
    property string kbdDevice: "platform::kbd_backlight"
    property string wallpaperHint: ""
    property bool wallScanning: false

    // Power inhibit --- caffeine (no suspend) + hypridle off (no auto-lock)
    property bool caffeineActive: false
    property bool idleLockDisabled: false

    readonly property string wallustScript: Quickshell.shellDir + "/utils/scripts/load-wallust-colors.sh"
    readonly property string legacyScript:  Quickshell.shellDir + "/utils/scripts/load-legacy-colors.sh"
    readonly property string idleToggleScript: Quickshell.shellDir + "/utils/scripts/idle-toggle.sh"

    ListModel { id: wallpaperModel }
    property alias wallpapers: wallpaperModel

    signal requestClose()   // parent should close the center console panel

    // --- PipeWire sink (same resilience as Volume.qml) ---
    readonly property var trackedSink: Pipewire.defaultAudioSink
    PwObjectTracker {
        id: sinkTracker
        objects: root.trackedSink ? [root.trackedSink] : []
    }
    readonly property var sinkNode: {
        if (sinkTracker.objects && sinkTracker.objects.length > 0 && sinkTracker.objects[0])
            return sinkTracker.objects[0]
        return Pipewire.defaultAudioSink
    }
    readonly property var sinkAudio: sinkNode ? (sinkNode.audio ?? null) : null
    property bool audioReady: false

    function syncVolume() {
        const a = sinkAudio
        if (!a) {
            root.audioReady = false
            return false
        }
        root.volume = Math.round((a.volume ?? 0) * 100)
        root.muted = !!a.muted
        root.audioReady = true
        return true
    }

    function setVolume(pct) {
        const a = sinkAudio
        if (!a)
            return
        a.volume = Math.max(0, Math.min(1.5, pct / 100))
        root.volume = Math.round(a.volume * 100)
    }

    function toggleMute() {
        const a = sinkAudio
        if (!a)
            return
        a.muted = !a.muted
        root.muted = a.muted
        Globals.toast(root.muted ? "Muted" : "Unmuted", "", "Settings")
    }

    property int audioAttempts: 0

    function tickAudio() {
        if (syncVolume()) {
            root.audioAttempts = 0
            audioSlowRetry.running = false
            audioFastRetry.running = false
            return
        }
        root.audioAttempts++
        // never give up --- WirePlumber can export the default sink late
        if (root.audioAttempts <= Tokens.audioRetryFastCount) {
            audioSlowRetry.running = false
            if (!audioFastRetry.running)
                audioFastRetry.running = true
        } else {
            audioFastRetry.running = false
            if (!audioSlowRetry.running)
                audioSlowRetry.running = true
        }
    }

    Timer {
        id: audioFastRetry
        interval: Tokens.audioRetryFastMs
        repeat: true
        running: false
        onTriggered: root.tickAudio()
    }
    Timer {
        id: audioSlowRetry
        interval: Tokens.audioRetrySlowMs
        repeat: true
        running: false
        onTriggered: root.tickAudio()
    }

    Connections {
        target: Pipewire
        function onReadyChanged() {
            root.audioAttempts = 0
            root.tickAudio()
        }
        function onDefaultAudioSinkChanged() {
            root.audioAttempts = 0
            root.tickAudio()
        }
    }
    Connections {
        target: root.sinkAudio
        enabled: root.sinkAudio !== null
        ignoreUnknownSignals: true
        function onVolumeChanged() { root.syncVolume() }
        function onMutedChanged()  { root.syncVolume() }
    }
    Connections {
        target: sinkTracker
        function onObjectsChanged() { root.tickAudio() }
    }

    Component.onCompleted: {
        brightQuery.running = true
        kbdQuery.running = true
        audioFastRetry.running = true
        root.tickAudio()
        root.scanWallpapers()
        root.queryWallpaper()
        root.refreshPowerState()
    }

    // --- Power inhibit (hyprcaffeine + hypridle / auto-lock) ---
    // Restart helper: Process ignores running=true if already true; always bounce.
    function _restart(proc) {
        if (!proc)
            return
        if (proc.running)
            proc.running = false
        proc.running = true
    }

    function refreshPowerState() {
        root._restart(caffeineQuery)
        root._restart(idleQuery)
    }

    function toggleCaffeine() {
        root.statusMsg = "TOGGLING CAFFEINE…"
        root._restart(caffeineToggle)
    }

    function toggleIdleLock() {
        root.statusMsg = "TOGGLING AUTO-LOCK…"
        powerPoll.running = false
        idleToggle.exec(["bash", root.idleToggleScript, "--toggle"])
    }

    // hyprcaffeine never emits class "hc-on" — active sleep inhibit is
    // hc-infinite / hc-timer (and combos). Prefer state.json "status":"active".
    function _parseCaffeine(text) {
        const t = (text || "").trim()
        if (!t.length)
            return false
        // state.json or similar
        if (/"status"\s*:\s*"active"/i.test(t))
            return true
        if (/"status"\s*:\s*"inactive"/i.test(t))
            return false
        // waybar JSON classes (real hyprcaffeine output)
        if (/\bhc-(infinite|timer)/i.test(t))
            return true
        if (/\bhc-off\b/i.test(t))
            return false
        // legacy / human status
        if (t.indexOf("hc-on") >= 0 || /caffeine:\s*active/i.test(t))
            return true
        if (/Idle:\s*on/i.test(t) || /Infinite mode/i.test(t) || /Timer:/i.test(t))
            return true
        return false
    }

    function _parseIdleDisabled(text) {
        const t = text || ""
        if (/STATE=disabled/i.test(t))
            return true
        if (/STATE=enabled/i.test(t))
            return false
        return t.toUpperCase().indexOf("DISABLED") >= 0
    }

    function _parseIdleRunning(text) {
        const m = (text || "").match(/RUNNING=([01])/)
        if (!m)
            return null
        return m[1] === "1"
    }

    function _applyCaffeineText(text, toast) {
        root.caffeineActive = root._parseCaffeine(text)
        if (!toast)
            return
        root.statusMsg = root.caffeineActive ? "CAFFEINE ON" : "CAFFEINE OFF"
        Globals.toast(
            "Caffeine",
            root.caffeineActive ? "Sleep inhibited" : "Sleep allowed",
            "Settings"
        )
    }

    function _applyIdleText(text, toast) {
        root.idleLockDisabled = root._parseIdleDisabled(text)
        const running = root._parseIdleRunning(text)
        if (!toast)
            return
        if (root.idleLockDisabled) {
            root.statusMsg = running === true ? "AUTO-LOCK OFF (STILL RUNNING)" : "AUTO-LOCK OFF"
            Globals.toast(
                "Auto-lock off",
                running === true ? "hypridle still running" : "hypridle stopped",
                "Settings"
            )
        } else {
            root.statusMsg = running === false ? "AUTO-LOCK ON (NOT RUNNING)" : "AUTO-LOCK ON"
            Globals.toast(
                "Auto-lock on",
                running === false ? "hypridle did not start" : "hypridle running",
                "Settings"
            )
        }
    }

    Process {
        id: caffeineQuery
        // state.json is authoritative for sleep-inhibit (timer / infinite)
        command: [
            "bash", "-c",
            "f=\"${XDG_CACHE_HOME:-$HOME/.cache}/hyprcaffeine/state.json\"; "
                + "if [[ -f \"$f\" ]]; then cat \"$f\"; "
                + "else hyprcaffeine waybar 2>/dev/null; fi"
        ]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root._applyCaffeineText(text, false)
        }
    }

    Process {
        id: caffeineToggle
        // toggle sleep inhibit, then report state.json (or waybar fallback)
        command: [
            "bash", "-c",
            "export PATH=\"/usr/local/bin:/usr/bin:$HOME/.local/bin:$PATH\"; "
                + "hyprcaffeine toggle >/dev/null 2>&1; "
                + "f=\"${XDG_CACHE_HOME:-$HOME/.cache}/hyprcaffeine/state.json\"; "
                + "if [[ -f \"$f\" ]]; then cat \"$f\"; "
                + "else hyprcaffeine waybar 2>/dev/null; fi"
        ]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root._applyCaffeineText(text, true)
        }
        onExited: (code) => {
            if (code !== 0) {
                root.statusMsg = "CAFFEINE FAILED"
                Globals.toast("Caffeine", "hyprcaffeine failed (is it installed?)", "Settings")
                root._restart(caffeineQuery)
            }
        }
    }

    Process {
        id: idleQuery
        command: ["bash", root.idleToggleScript, "--status"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root._applyIdleText(text, false)
        }
    }

    Process {
        id: idleToggle
        command: ["bash", root.idleToggleScript, "--toggle"]
        stdout: StdioCollector {
            id: idleToggleOut
            waitForEnd: true
            onStreamFinished: root._applyIdleText(text, true)
        }
        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                if (text && text.trim().length)
                    console.warn("idle-toggle:", text.trim())
            }
        }
        onExited: (code) => {
            powerPoll.running = true
            if (code !== 0 && (idleToggleOut.text || "").indexOf("STATE=") < 0) {
                root.statusMsg = "AUTO-LOCK TOGGLE FAILED"
                Globals.toast("Auto-lock", "idle-toggle.sh failed", "Settings")
                root._restart(idleQuery)
            }
        }
    }

    // Keep toggle tiles honest while settings stay open (keybind may change state)
    Timer {
        id: powerPoll
        interval: 4000
        running: true
        repeat: true
        onTriggered: root.refreshPowerState()
    }

    // --- Wallpaper + palette (awww / wallust / legacy) ---
    function scanWallpapers() {
        root.wallScanning = true
        wallScan.running = true
    }

    function queryWallpaper() {
        wallQuery.running = true
    }

    function parseWallpaperList(text) {
        wallpaperModel.clear()
        const lines = (text || "").split("\n")
        let n = 0
        for (let i = 0; i < lines.length; i++) {
            const p = lines[i].trim()
            if (!p.length)
                continue
            const base = p.split("/").pop()
            wallpaperModel.append({ path: p, name: base })
            n++
            if (n >= Tokens.wallpaperScanMax)
                break
        }
        root.wallScanning = false
        if (n === 0)
            root.wallpaperHint = "No images in ~/Pictures · ~/Wallpapers"
        else if (!root.wallpaperHint.length)
            root.wallpaperHint = n + " surfaces found"
    }

    function setWallpaper(path) {
        if (!path || !String(path).length)
            return
        root.statusMsg = "DEPLOYING WALLPAPER"
        root.wallpaperHint = String(path).split("/").pop()
        Globals.toast("Wallpaper", root.wallpaperHint, "Settings")
        wallSet.path = String(path)
        wallSet.running = true
    }

    function syncWallust() {
        root.statusMsg = "WALLUST TEXT + ICONS"
        Globals.toast("Theme", "Tinting text & icons from wallpaper…", "Settings")
        wallustRun.running = true
    }

    function activateLegacy() {
        root.statusMsg = "MONOCHROME PALETTE"
        Globals.toast("Theme", "Activating monochrome palette", "Settings")
        legacyRun.running = true
    }

    Process {
        id: wallQuery
        command: [
            "bash", "-c",
            "if command -v awww >/dev/null 2>&1 && pgrep -u \"$USER\" -x awww-daemon >/dev/null 2>&1; then "
                + "awww query 2>/dev/null | sed -n 's/.*image: //p' | head -1; "
                + "else echo ''; fi"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim()
                if (p.length)
                    root.wallpaperHint = p.split("/").pop()
            }
        }
    }

    Process {
        id: wallScan
        command: [
            "bash", "-c",
            "HOME_D=\"$HOME\"; "
                + "find \"$HOME_D/Pictures\" \"$HOME_D/Wallpapers\" "
                + "\"$HOME_D/.config/hypr/wallpapers\" \"$HOME_D/Pictures/Wallpapers\" "
                + "-type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' "
                + "-o -iname '*.webp' -o -iname '*.jxl' \\) 2>/dev/null "
                + "| sort -u | head -n " + Tokens.wallpaperScanMax
        ]
        stdout: StdioCollector {
            onStreamFinished: root.parseWallpaperList(text)
        }
        onExited: root.wallScanning = false
    }

    Process {
        id: wallSet
        property string path: ""
        // PATH includes cargo so wallust is found even when qs strips env
        command: [
            "bash", "-c",
            "export PATH=\"$HOME/.cargo/bin:/usr/local/bin:$PATH\"; "
                + "IMG=\"$1\"; SCRIPT=\"$2\"; "
                + "if command -v awww >/dev/null 2>&1; then "
                + "  awww img \"$IMG\" --transition-type any --transition-fps 60 2>/dev/null "
                + "    || awww img \"$IMG\"; "
                + "fi; "
                + "exec bash \"$SCRIPT\" \"$IMG\"",
            "wallset",
            path,
            root.wallustScript
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length)
                    console.log("wallSet:", text.trim().split("\n").slice(-3).join(" | "))
            }
        }
        onExited: (code) => {
            root.statusMsg = code === 0 ? "WALLPAPER + WALLUST OK" : "WALLPAPER APPLY FAILED"
            root.queryWallpaper()
        }
    }

    Process {
        id: wallustRun
        // bash + cargo PATH: qs Process often cannot exec shebang scripts with missing wallust
        command: [
            "bash", "-c",
            "export PATH=\"$HOME/.cargo/bin:/usr/local/bin:$PATH\"; "
                + "exec bash \"$1\" --from-awww",
            "wallust-run",
            root.wallustScript
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length)
                    console.log("wallust:", text.trim().split("\n").slice(-4).join(" | "))
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text && text.trim().length)
                    console.warn("wallust err:", text.trim().split("\n").slice(-4).join(" | "))
            }
        }
        onExited: (code) => {
            root.statusMsg = code === 0 ? "WALLUST ACTIVE" : "WALLUST FAILED"
            if (code === 0)
                Globals.toast("Theme", "Text & icons tinted (monochrome surfaces kept)", "Settings")
            else
                Globals.toast("Theme", "Wallust failed — is wallust + awww running?", "Settings")
        }
    }

    Process {
        id: legacyRun
        command: [
            "bash", "-c",
            "export PATH=\"$HOME/.cargo/bin:/usr/local/bin:$PATH\"; "
                + "exec bash \"$1\" --activate",
            "legacy-run",
            root.legacyScript
        ]
        onExited: (code) => {
            root.statusMsg = code === 0 ? "MONOCHROME ACTIVE" : "LEGACY ACTIVATE FAILED"
            if (code === 0)
                Globals.toast("Theme", "Monochrome palette restored", "Settings")
        }
    }

    // --- Screen brightness ---
    function setBrightness(pct) {
        const v = Math.max(1, Math.min(100, Math.round(pct)))
        brightSet.pct = String(v) + "%"
        brightSet.running = true
        root.brightness = v
    }

    Process {
        id: brightQuery
        command: ["brightnessctl", "-m", "g"]
        // machine: device,class,current,percent,max
        stdout: StdioCollector {
            onStreamFinished: {
                // e.g. intel_backlight,backlight,48000,50%,96000
                const parts = text.trim().split(",")
                if (parts.length >= 4) {
                    const p = parseInt(parts[3])
                    if (!isNaN(p))
                        root.brightness = p
                }
            }
        }
    }

    Process {
        id: brightSet
        property string pct: "50%"
        command: ["brightnessctl", "set", pct]
        onExited: brightQuery.running = true
    }

    // --- Keyboard backlight ---
    function setKbd(level) {
        const v = Math.max(0, Math.min(root.kbdMax, Math.round(level)))
        kbdSet.level = String(v)
        kbdSet.running = true
        root.kbdBrightness = v
    }

    function cycleKbd() {
        setKbd((root.kbdBrightness + 1) % (root.kbdMax + 1))
    }

    Process {
        id: kbdQuery
        command: ["brightnessctl", "-m", "-d", "platform::kbd_backlight", "g"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",")
                // device,class,current,percent,max
                if (parts.length >= 5) {
                    root.kbdBrightness = parseInt(parts[2]) || 0
                    root.kbdMax = parseInt(parts[4]) || 2
                }
            }
        }
    }

    Process {
        id: kbdSet
        property string level: "0"
        command: ["brightnessctl", "-d", "platform::kbd_backlight", "set", level]
        onExited: kbdQuery.running = true
    }

    // --- Appearance (GNOME-CONTROL-CENTER) ---
    // GCC refuses to start unless XDG_CURRENT_DESKTOP is GNOME/Unity.
    // Spoof it for Hyprland; the binary is already installed.
    function launchGnome() {
        root.statusMsg = "LAUNCHING GNOME"
        Globals.toast("Settings", "Opening GNOME Control Center", "Settings")
        root.requestClose()
        // slight delay so panel can collapse first
        gnomeTimer.start()
    }

    Timer {
        id: gnomeTimer
        interval: Tokens.animMedium
        onTriggered: Quickshell.execDetached([
            "env", "XDG_CURRENT_DESKTOP=GNOME", "gnome-control-center"
        ])
    }

    // --- Screenshot (grim + slurp) ---
    function screenshot() {
        root.statusMsg = "SELECT REGION"
        root.requestClose()
        shotTimer.start()
    }

    Timer {
        id: shotTimer
        interval: Tokens.animMedium
        onTriggered: {
            Quickshell.execDetached([
                "bash", "-c",
                "mkdir -p \"$HOME/Pictures\" && "
                + "f=\"$HOME/Pictures/slayer-$(date +%Y%m%d-%H%M%S).png\" && "
                + "grim -g \"$(slurp)\" \"$f\" && notify-send -a Settings Screenshot \"$f\""
            ])
        }
    }

    // --- Screen record (wf-recorder + slurp) ---
    function toggleRecord() {
        if (Globals.screenRecording) {
            stopRecord.running = true
            return
        }
        root.statusMsg = "SELECT REGION TO RECORD"
        Globals.toast("Recording", "Select region…", "Settings")
        root.requestClose()
        recTimer.start()
    }

    Timer {
        id: recTimer
        interval: Tokens.animMedium
        onTriggered: {
            Globals.screenRecording = true
            Quickshell.execDetached([
                "bash", "-c",
                "mkdir -p \"$HOME/Videos\" && "
                + "f=\"$HOME/Videos/slayer-$(date +%Y%m%d-%H%M%S).mp4\" && "
                + "wf-recorder -a -g \"$(slurp)\" -f \"$f\"; "
                + "notify-send -a Settings 'Recording saved' \"$f\""
            ])
        }
    }

    Process {
        id: stopRecord
        command: ["pkill", "-INT", "wf-recorder"]
        onExited: {
            Globals.screenRecording = false
            root.statusMsg = "RECORDING STOPPED"
            Globals.toast("Recording stopped", "", "Settings")
        }
    }

}
