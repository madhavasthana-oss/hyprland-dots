import QtQuick
import ".."

Item {
    id: root

    // --- Public API ---

    property string displayedText: ""
    property string targetText: ""
    property int mode: AnimatedText.Mode.Typewriter
    property int duration: Tokens.animFadeDelay
    property string scrambleChars: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*"

    // zoomIn specific: binary search style convergence
    property int zoomStyle: AnimatedText.ZoomStyle.OutsideIn   // How the narrowing behaves

    // fadeIn specific
    property real displayOpacity: 1.0

    readonly property bool isAnimating: d.typingOut || d.typingIn || d.scrambling || d.zooming || d.fadingOut || d.fadingIn
    readonly property bool typingOut: d.typingOut
    readonly property bool typingIn: d.typingIn
    readonly property bool scrambling: d.scrambling
    readonly property bool zooming: d.zooming
    readonly property bool fadingOut: d.fadingOut
    readonly property bool fadingIn: d.fadingIn

    // --- Enums ---

    enum Mode {
        Typewriter,
        Scramble,
        ZoomIn,
        FadeIn,
        Backspace
    }

    enum ZoomStyle {
        OutsideIn,
        InsideOut,
        RandomLock,
        Alternating
    }

    // --- Internal State ---
    QtObject {
        id: d
        property bool typingOut: false
        property bool typingIn: false
        property bool scrambling: false
        property bool zooming: false
        property bool fadingOut: false
        property bool fadingIn: false
        property int scrambleIndex: 0
        property int zoomOutIndex: 0
        property var locked: []       // Which positions are finalized (zoom in)
        property var candidates: []   // Positions still randomizing (zoom in)
        property var unlocked: []     // Positions still real (zoom out)
        property var outCandidates: []// Positions still to scramble away (zoom out)
        property string pendingText: ""  // target queued behind an exit animation
        property bool hasPending: false
    }

    // --- Public Methods ---

    // Entry point: animate displayedText -> text, choosing an exit
    // strategy for whatever is currently on screen based on `mode`.
    function transitionTo(text) {
        // If we're already mid-flight, queue this target and let the
        // current exit/entry finish before we chain into the new one.
        if (isAnimating) {
            d.pendingText = text
            d.hasPending = true
            return
        }

        targetText = text

        if (displayedText === "") {
            // Nothing on screen yet --- no exit needed, just enter.
            enterWithMode()
            return
        }

        if (text === "") {
            // Caller wants a hard clear --- exit only, no re-entry.
            transitionFrom("")
            return
        }

        // Something is currently shown: run the exit animation for the
        // *current* mode, then enter with the new text.
        transitionFrom(text)
    }

    // Exit point: animate displayedText -> "" (or hand off into nextText),
    // using the mode-appropriate exit behavior. Mirrors transitionTo.
    function transitionFrom(nextText) {
        stopTimers()
        d.pendingText = nextText !== undefined ? nextText : ""
        d.hasPending = nextText !== "" && nextText !== undefined

        switch (mode) {
            case AnimatedText.Mode.Backspace:
                startTypeOut()
                break
            case AnimatedText.Mode.Scramble:
                startScrambleOut()
                break
            case AnimatedText.Mode.ZoomIn:
                startZoomOut()
                break
            case AnimatedText.Mode.FadeIn:
                startFadeOut()
                break
            case AnimatedText.Mode.Typewriter:
            default:
                // Typewriter has no natural "exit" of its own; borrow
                // backspace behavior so it doesn't just blurt.
                startTypeOut()
                break
        }
    }

    function stop() {
        stopTimers()
        d.typingOut = false
        d.typingIn = false
        d.scrambling = false
        d.zooming = false
        d.fadingOut = false
        d.fadingIn = false
        d.hasPending = false
        d.pendingText = ""
    }

    function stopTimers() {
        typeOutTimer.stop()
        typeInTimer.stop()
        scrambleTimer.stop()
        scrambleOutTimer.stop()
        zoomTimer.stop()
        zoomOutTimer.stop()
        fadeTimer.stop()
    }

    // --- Internal Helpers ---

    function enterWithMode() {
        switch (mode) {
            case AnimatedText.Mode.Scramble:
                startScramble()
                break
            case AnimatedText.Mode.ZoomIn:
                startZoomIn()
                break
            case AnimatedText.Mode.FadeIn:
                startFadeIn()
                break
            case AnimatedText.Mode.Backspace:
            case AnimatedText.Mode.Typewriter:
            default:
                startTypeIn()
                break
        }
    }

    // Called by every "out" finisher once displayedText is fully cleared.
    function onExitFinished() {
        if (d.hasPending && d.pendingText !== "") {
            targetText = d.pendingText
            d.hasPending = false
            d.pendingText = ""
            enterWithMode()
        } else {
            d.hasPending = false
            d.pendingText = ""
        }
    }

    function startTypeOut() {
        d.typingOut = true
        typeOutTimer.interval = charInterval(displayedText.length)
        typeOutTimer.restart()
    }

    function startTypeIn() {
        displayedText = ""
        displayOpacity = 1.0
        d.typingIn = true
        typeInTimer.interval = charInterval(targetText.length)
        typeInTimer.restart()
    }

    function startScramble() {
        d.scrambling = true
        d.scrambleIndex = 0
        displayOpacity = 1.0
        displayedText = generateRandomString(targetText.length)
        scrambleTimer.interval = charInterval(targetText.length)
        scrambleTimer.restart()
    }

    // Dissolve current displayedText into noise, then to "" character by character.
    function startScrambleOut() {
        var len = displayedText.length
        d.outCandidates = []
        for (var i = 0; i < len; i++) d.outCandidates.push(i)
        // Shuffle so the dissolve order isn't strictly left-to-right
        for (var n = d.outCandidates.length - 1; n > 0; n--) {
            var r = Math.floor(Math.random() * (n + 1))
            var tmp = d.outCandidates[n]
            d.outCandidates[n] = d.outCandidates[r]
            d.outCandidates[r] = tmp
        }
        d.unlocked = new Array(len).fill(true)
        d.scrambling = true   // reuse the "scrambling" flag to mean "scramble busy" (in or out)
        scrambleOutTimer.interval = charInterval(len)
        scrambleOutTimer.restart()
    }

    function startZoomIn() {
        d.zooming = true
        var len = targetText.length
        d.locked = new Array(len).fill(false)
        d.candidates = []

        buildLockOrder(len, d.candidates)

        zoomTimer.interval = charInterval(d.candidates.length)
        zoomTimer.restart()
    }

    // Reverse of zoomIn: start fully resolved, progressively un-lock
    // characters into noise (same order as zoomStyle would lock them),
    // then collapse to "".
    function startZoomOut() {
        d.zooming = true
        var len = displayedText.length
        d.unlocked = new Array(len).fill(false)
        d.outCandidates = []

        buildLockOrder(len, d.outCandidates)

        zoomOutTimer.interval = charInterval(d.outCandidates.length)
        zoomOutTimer.restart()
    }

    // Shared ordering logic used by both zoom-in locking and zoom-out unlocking.
    function buildLockOrder(len, targetArray) {
        switch (zoomStyle) {
            case AnimatedText.ZoomStyle.OutsideIn:
                for (var i = 0; i < Math.ceil(len / 2); i++) {
                    targetArray.push(i)
                    if (len - 1 - i !== i) {
                        targetArray.push(len - 1 - i)
                    }
                }
                break
            case AnimatedText.ZoomStyle.InsideOut:
                var mid = Math.floor(len / 2)
                for (var j = 0; j < Math.ceil(len / 2); j++) {
                    if (mid - j >= 0) targetArray.push(mid - j)
                    if (mid + j < len && mid + j !== mid - j) {
                        targetArray.push(mid + j)
                    }
                }
                break
            case AnimatedText.ZoomStyle.Alternating:
                for (var k = 0; k < len; k++) {
                    targetArray.push(k % 2 === 0 ? Math.floor(k / 2) : len - 1 - Math.floor(k / 2))
                }
                break
            case AnimatedText.ZoomStyle.RandomLock:
                var indices = []
                for (var m = 0; m < len; m++) indices.push(m)
                for (var n = indices.length - 1; n > 0; n--) {
                    var r = Math.floor(Math.random() * (n + 1))
                    var tmp = indices[n]
                    indices[n] = indices[r]
                    indices[r] = tmp
                }
                for (var p = 0; p < indices.length; p++) targetArray.push(indices[p])
                break
        }
    }

    function startFadeIn() {
        displayedText = targetText
        displayOpacity = 0.0
        d.fadingIn = true
        fadeTimer.fadeTarget = 1.0
        fadeTimer.interval = 16
        fadeTimer.restart()
    }

    function startFadeOut() {
        d.fadingOut = true
        fadeTimer.fadeTarget = 0.0
        fadeTimer.interval = 16
        fadeTimer.restart()
    }

    function charInterval(steps) {
        return Math.max(16, Math.floor(duration / Math.max(1, steps)))
    }

    function randomChar() {
        return scrambleChars.charAt(Math.floor(Math.random() * scrambleChars.length))
    }

    function generateRandomString(length) {
        var result = ""
        for (var i = 0; i < length; i++) result += randomChar()
        return result
    }

    function buildZoomString() {
        var result = ""
        for (var i = 0; i < targetText.length; i++) {
            result += d.locked[i] ? targetText.charAt(i) : randomChar()
        }
        return result
    }

    // For zoom-out: characters in `unlocked` show the original text,
    // everything else shows noise.
    function buildZoomOutString(sourceText) {
        var result = ""
        for (var i = 0; i < sourceText.length; i++) {
            result += d.unlocked[i] ? sourceText.charAt(i) : randomChar()
        }
        return result
    }

    // --- Timers ---

    Timer {
        id: typeOutTimer
        repeat: true
        onTriggered: {
            if (root.displayedText.length > 0) {
                root.displayedText = root.displayedText.substring(0, root.displayedText.length - 1)
            } else {
                root.stopTimers()
                d.typingOut = false
                root.onExitFinished()
            }
        }
    }

    Timer {
        id: typeInTimer
        repeat: true
        onTriggered: {
            if (root.displayedText.length < root.targetText.length) {
                root.displayedText = root.targetText.substring(0, root.displayedText.length + 1)
            } else {
                root.stopTimers()
                d.typingIn = false
            }
        }
    }

    Timer {
        id: scrambleTimer
        repeat: true
        onTriggered: {
            if (d.scrambleIndex < root.targetText.length) {
                d.scrambleIndex++
                var result = ""
                for (var i = 0; i < root.targetText.length; i++) {
                    result += (i < d.scrambleIndex) ? root.targetText.charAt(i) : root.randomChar()
                }
                root.displayedText = result
            } else {
                root.stopTimers()
                d.scrambling = false
                root.displayedText = root.targetText
            }
        }
    }

    // Progressively turns resolved characters into noise, then clears.
    Timer {
        id: scrambleOutTimer
        repeat: true
        onTriggered: {
            if (d.outCandidates.length > 0) {
                var idx = d.outCandidates.shift()
                d.unlocked[idx] = false
                root.displayedText = root.buildZoomOutString(root.displayedText)
            } else {
                root.stopTimers()
                d.scrambling = false
                root.displayedText = ""
                root.onExitFinished()
            }
        }
    }

    Timer {
        id: zoomTimer
        repeat: true
        onTriggered: {
            if (d.candidates.length > 0) {
                var idx = d.candidates.shift()
                d.locked[idx] = true
                root.displayedText = root.buildZoomString()
            } else {
                root.stopTimers()
                d.zooming = false
                root.displayedText = root.targetText
            }
        }
    }

    // Progressively unlocks resolved characters into noise, then clears.
    Timer {
        id: zoomOutTimer
        property string sourceText: ""
        repeat: true
        onTriggered: {
            if (sourceText === "") sourceText = root.displayedText
            if (d.outCandidates.length > 0) {
                var idx = d.outCandidates.shift()
                d.unlocked[idx] = false
                root.displayedText = root.buildZoomOutString(sourceText)
            } else {
                root.stopTimers()
                d.zooming = false
                root.displayedText = ""
                sourceText = ""
                root.onExitFinished()
            }
        }
    }

    Timer {
        id: fadeTimer
        property real fadeTarget: 1.0
        repeat: true
        onTriggered: {
            var step = 1.0 / Math.max(1, Math.floor(root.duration / 16))
            if (fadeTarget > root.displayOpacity) {
                root.displayOpacity = Math.min(fadeTarget, root.displayOpacity + step)
            } else {
                root.displayOpacity = Math.max(fadeTarget, root.displayOpacity - step)
            }

            if (root.displayOpacity === fadeTarget) {
                root.stopTimers()
                if (fadeTarget === 0.0) {
                    d.fadingOut = false
                    root.displayedText = ""
                    root.onExitFinished()
                } else {
                    d.fadingIn = false
                }
            }
        }
    }
}