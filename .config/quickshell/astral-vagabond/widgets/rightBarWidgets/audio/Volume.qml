// Volume.qml --- resilient PipeWire default-sink binding
//
// Why this used to die on boot:
//   Pipewire.defaultAudioSink is often null (or briefly null) until WirePlumber
//   finishes exporting devices. The old code stopped retrying after ~20s, so if
//   the sink appeared without a "changed" signal later (or audio was still
//   unbound), the bar stayed dead until a full qs reload.
//
// Approach (same idea as end-4 / caelestia audio services):
//   1. Wait for Pipewire.ready (initial server sync).
//   2. Track defaultAudioSink with PwObjectTracker so node metadata is live.
//   3. Never permanently give up --- fast retries, then slow forever.
//   4. Re-arm on ready / default-sink / node-ready / audio changes.
import Quickshell.Services.Pipewire
import QtQuick
import "../../.."

Item {
    id: audioStat

    property int volume: 0
    property bool muted: false
    property bool ready: false
    property string display: muted ? "M" : (volume + "%")
    property string sinkName: ""

    property int barVolume: Math.min(volume, 100)
    property real barFraction: barVolume / 100

    property int attemptCount: 0

    signal volumeModified(int volume, bool muted)
    signal becameReady()

    // Keep the tracked object list reactive --- null when no sink so the tracker
    // fully drops the old node, then rebinds when WP picks a default.
    readonly property var trackedSink: Pipewire.defaultAudioSink

    PwObjectTracker {
        id: sinkTracker
        objects: audioStat.trackedSink ? [audioStat.trackedSink] : []
    }

    // Prefer the live tracked object; fall back to the singleton pointer.
    readonly property var sinkNode: {
        if (sinkTracker.objects && sinkTracker.objects.length > 0 && sinkTracker.objects[0])
            return sinkTracker.objects[0]
        return Pipewire.defaultAudioSink
    }

    readonly property var currentAudio: sinkNode ? (sinkNode.audio ?? null) : null

    function syncFromAudio() {
        const audio = currentAudio
        if (!audio)
            return false

        // Node may exist before audio is populated --- treat as not ready yet.
        const vol = Math.round((audio.volume ?? 0) * 100)
        const isMuted = !!audio.muted

        const changed = (vol !== audioStat.volume) || (isMuted !== audioStat.muted)
        audioStat.volume = vol
        audioStat.muted = isMuted
        audioStat.sinkName = sinkNode
            ? (sinkNode.nickname || sinkNode.description || sinkNode.name || "")
            : ""

        if (changed)
            audioStat.volumeModified(vol, isMuted)

        return true
    }

    function markReady() {
        if (!audioStat.ready) {
            audioStat.ready = true
            audioStat.becameReady()
            // Ensure UI fades in even if volume value didn't change from 0
            audioStat.volumeModified(audioStat.volume, audioStat.muted)
        }
        audioStat.attemptCount = 0
        slowRetry.running = false
        fastRetry.running = false
    }

    function markUnready() {
        if (audioStat.ready)
            audioStat.ready = false
    }

    function tick() {
        // Still syncing the graph --- stay in fast mode
        if (!Pipewire.ready) {
            markUnready()
            scheduleRetry()
            return
        }

        if (syncFromAudio()) {
            markReady()
            return
        }

        // Sink pointer present but audio not bound yet, or sink is null
        // (docs: defaultAudioSink may briefly be null when switching).
        markUnready()
        scheduleRetry()
    }

    function scheduleRetry() {
        audioStat.attemptCount++
        if (audioStat.attemptCount <= Tokens.audioRetryFastCount) {
            slowRetry.running = false
            if (!fastRetry.running)
                fastRetry.running = true
        } else {
            fastRetry.running = false
            if (!slowRetry.running)
                slowRetry.running = true
        }
    }

    // Initial delay so we don't hammer PW on the first frame of a cold boot
    Timer {
        id: startupTimer
        interval: Tokens.audioInitDelayMs
        repeat: false
        running: true
        onTriggered: audioStat.tick()
    }

    Timer {
        id: fastRetry
        interval: Tokens.audioRetryFastMs
        repeat: true
        running: false
        onTriggered: audioStat.tick()
    }

    // After the fast window, keep a slow forever-poll so a late WP export
    // still recovers without a manual qs reload.
    Timer {
        id: slowRetry
        interval: Tokens.audioRetrySlowMs
        repeat: true
        running: false
        onTriggered: audioStat.tick()
    }

    Connections {
        target: Pipewire
        function onReadyChanged() {
            audioStat.attemptCount = 0
            audioStat.tick()
        }
        function onDefaultAudioSinkChanged() {
            audioStat.attemptCount = 0
            audioStat.tick()
        }
        function onDefaultConfiguredAudioSinkChanged() {
            audioStat.attemptCount = 0
            audioStat.tick()
        }
    }

    // When the node itself finishes binding
    Connections {
        target: audioStat.sinkNode
        enabled: audioStat.sinkNode !== null
        ignoreUnknownSignals: true
        function onReadyChanged() { audioStat.tick() }
        function onAudioChanged() { audioStat.tick() }
    }

    Connections {
        target: audioStat.currentAudio
        enabled: audioStat.currentAudio !== null
        ignoreUnknownSignals: true
        function onVolumeChanged() { audioStat.syncFromAudio() }
        function onMutedChanged()  { audioStat.syncFromAudio() }
    }

    // Re-tick when tracker object list mutates
    Connections {
        target: sinkTracker
        function onObjectsChanged() { audioStat.tick() }
    }
}
