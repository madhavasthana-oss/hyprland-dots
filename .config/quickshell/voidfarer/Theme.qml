pragma Singleton
import QtQuick 2.15
import Quickshell
import Quickshell.Io

// Singleton (not QtObject): FileView must be a child object; QtObject has no
// default property and fails with "Cannot assign to non-existent default property".
Singleton {
    id: root

    // ---
    //  Live palette file (written by load-legacy-colors.sh / load-wallust-colors.sh)
    //  Switch sources without regenerating this QML file.
    // ---
    readonly property string colorsPath: Quickshell.shellDir + "/colors/active-colors.json"

    // Ash monochrome fallbacks — soft charcoal, not pure black; soft off-white text.
    // Comforting for long sessions: Material-style #121212 base, desaturated hierarchy.
    readonly property var _defaults: ({
        "bgPrimary":     "#121212",
        "bgSurface":     "#1A1A1A",
        "bgElevated":    "#242424",
        "accent":        "#C8C8C8",
        "accentWarm":    "#A3A3A3",
        "accentSoft":    "#737373",
        "textPrimary":   "#E5E5E5",
        "textSecondary": "#A3A3A3",
        "textMuted":     "#6B6B6B",
        "textDim":       "#454545",
        "stateCritical": "#E8E8E8",
        "stateSafe":     "#8A8A8A",
        "stateWarning":  "#B8B8B8",
        "borderActive":  "#C8C8C8",
        "borderIdle":    "#333333",
        "bgConsole":     "#161616",
        "borderConsole": "#333333",
        "glowConsole":   "#555555",
        // ANSI 0–15. Ash greys by default; wallust overwrites with wallpaper hues.
        "color0":  "#121212",
        "color1":  "#8A8A8A",
        "color2":  "#A3A3A3",
        "color3":  "#B8B8B8",
        "color4":  "#C8C8C8",
        "color5":  "#A3A3A3",
        "color6":  "#737373",
        "color7":  "#E5E5E5",
        "color8":  "#454545",
        "color9":  "#8A8A8A",
        "color10": "#A3A3A3",
        "color11": "#B8B8B8",
        "color12": "#C8C8C8",
        "color13": "#A3A3A3",
        "color14": "#737373",
        "color15": "#E5E5E5"
    })

    property var _palette: _defaults
    property string colorsSource: "defaults"

    function _hexOf(key) {
        const p = _palette
        if (p && p[key] !== undefined && p[key] !== null && String(p[key]).length)
            return String(p[key])
        return String(_defaults[key])
    }

    function _applyJsonText(text) {
        if (text === undefined || text === null)
            return
        const raw = String(text).trim()
        if (!raw.length)
            return
        try {
            const data = JSON.parse(raw)
            const next = Object.assign({}, _defaults)
            for (const key in _defaults) {
                if (data[key] !== undefined && data[key] !== null && String(data[key]).length)
                    next[key] = String(data[key])
            }
            _palette = next
            colorsSource = (data._source !== undefined && String(data._source).length)
                ? String(data._source)
                : "active"
        } catch (e) {
            console.warn("Theme: failed to parse colors JSON:", e)
        }
    }

    FileView {
        id: colorsFile
        path: root.colorsPath
        watchChanges: true
        blockLoading: true

        onFileChanged: reload()
        onLoaded: root._applyJsonText(text())
        Component.onCompleted: {
            // text() is available after initial load when blockLoading is true
            try {
                root._applyJsonText(text())
            } catch (e) {
                // keep _defaults
            }
        }
    }

    // Backgrounds
    readonly property color bgPrimary:   root._hexOf("bgPrimary")
    readonly property color bgSurface:   root._hexOf("bgSurface")
    readonly property color bgElevated:  root._hexOf("bgElevated")

    // Core accents
    readonly property color accent:      root._hexOf("accent")
    readonly property color accentWarm:  root._hexOf("accentWarm")
    readonly property color accentSoft:  root._hexOf("accentSoft")

    // Text
    readonly property color textPrimary:   root._hexOf("textPrimary")
    readonly property color textSecondary: root._hexOf("textSecondary")
    readonly property color textMuted:     root._hexOf("textMuted")
    readonly property color textDim:       root._hexOf("textDim")

    // State colors
    readonly property color stateCritical: root._hexOf("stateCritical")
    readonly property color stateSafe:     root._hexOf("stateSafe")
    readonly property color stateWarning:  root._hexOf("stateWarning")

    // Border / stroke color (widths now live in Tokens)
    readonly property color borderActive:  root._hexOf("borderActive")
    readonly property color borderIdle:    root._hexOf("borderIdle")

    // Expansion panel visuals
    readonly property color bgConsole:     root._hexOf("bgConsole")
    readonly property color borderConsole: root._hexOf("borderConsole")
    readonly property color glowConsole:   root._hexOf("glowConsole")

    // Wallust / ANSI scheme (color0–15). Ash greys when wallust is off.
    function scheme(n) {
        const i = Math.max(0, Math.min(15, Math.round(Number(n) || 0)))
        return root._hexOf("color" + i)
    }

    function _hexLum(h) {
        const s = String(h || "").replace("#", "")
        if (s.length < 6)
            return 0
        const r = parseInt(s.substring(0, 2), 16)
        const g = parseInt(s.substring(2, 4), 16)
        const b = parseInt(s.substring(4, 6), 16)
        if (isNaN(r) || isNaN(g) || isNaN(b))
            return 0
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    // Prefer the brighter of color N / N+8 so icons stay readable on Ash.
    // If both are too dim, fall back to accent.
    function inkOf(n) {
        const i = Math.max(1, Math.min(6, Math.round(Number(n) || 1)))
        const dark = String(root._hexOf("color" + i))
        const bright = String(root._hexOf("color" + (i + 8)))
        const pick = root._hexLum(bright) >= root._hexLum(dark) ? bright : dark
        if (root._hexLum(pick) < 90)
            return root._hexOf("accent")
        return pick
    }

    readonly property color color0:  root.scheme(0)
    readonly property color color1:  root.scheme(1)
    readonly property color color2:  root.scheme(2)
    readonly property color color3:  root.scheme(3)
    readonly property color color4:  root.scheme(4)
    readonly property color color5:  root.scheme(5)
    readonly property color color6:  root.scheme(6)
    readonly property color color7:  root.scheme(7)
    readonly property color color8:  root.scheme(8)
    readonly property color color9:  root.scheme(9)
    readonly property color color10: root.scheme(10)
    readonly property color color11: root.scheme(11)
    readonly property color color12: root.scheme(12)
    readonly property color color13: root.scheme(13)
    readonly property color color14: root.scheme(14)
    readonly property color color15: root.scheme(15)

    readonly property color inkRed:     root.inkOf(1)
    readonly property color inkGreen:   root.inkOf(2)
    readonly property color inkYellow:  root.inkOf(3)
    readonly property color inkBlue:    root.inkOf(4)
    readonly property color inkMagenta: root.inkOf(5)
    readonly property color inkCyan:    root.inkOf(6)

    // SYSTEM ICONS --- breeze symbolic, tinted at use site to theme colors
    readonly property string iconThemeActions: "file:///usr/share/icons/breeze/actions/22/"
    readonly property string iconPoweroff: iconThemeActions + "system-shutdown-symbolic.svg"
    readonly property string iconReboot:   iconThemeActions + "system-reboot-symbolic.svg"
    readonly property string iconLogout:   iconThemeActions + "system-log-out-symbolic.svg"
    readonly property string iconSleep:    iconThemeActions + "system-suspend-symbolic.svg"
    readonly property string iconLock:     iconThemeActions + "system-lock-screen-symbolic.svg"

    // Edge panel tiles --- full file URIs (icons live in actions/status/devices)
    readonly property string iconThemeStatus:  "file:///usr/share/icons/breeze/status/22/"
    readonly property string iconThemeDevices: "file:///usr/share/icons/breeze/devices/22/"
    readonly property string iconWifi:       iconThemeDevices + "network-wireless-symbolic.svg"
    readonly property string iconBluetooth:  iconThemeStatus  + "network-bluetooth-symbolic.svg"
    readonly property string iconSettings:   iconThemeActions  + "configure-symbolic.svg"
    readonly property string iconNotif:      iconThemeActions  + "notifications-symbolic.svg"
    readonly property string iconDashboard:  iconThemeActions  + "dashboard-show-symbolic.svg"
    readonly property string iconConsole:    iconThemeActions  + "dialog-scripts-symbolic.svg"
    readonly property string iconMedia:      iconThemeActions  + "media-playback-start-symbolic.svg"
    readonly property string iconRefresh:    iconThemeActions  + "view-refresh-symbolic.svg"
    readonly property string iconBrightness: iconThemeActions  + "brightness-high-symbolic.svg"
    readonly property string iconAudio:      iconThemeStatus  + "audio-volume-high-symbolic.svg"
    readonly property string iconKbd:        iconThemeDevices + "input-keyboard-symbolic.svg"
    readonly property string iconScreenshot: iconThemeActions  + "view-fullscreen-symbolic.svg"
    readonly property string iconRecord:     iconThemeActions  + "media-record-symbolic.svg"
    readonly property string iconThemeApp:   iconThemeActions  + "games-config-theme-symbolic.svg"
    readonly property string iconCaffeine:   iconThemeActions  + "system-suspend-symbolic.svg"
    readonly property string iconIdleLock:   iconThemeActions  + "system-lock-screen-symbolic.svg"

    // TYPOGRAPHY --- family names only, sizes now live in Tokens
    readonly property string fontMono:    "Fira Code"
    readonly property string fontDisplay: "KogniGear"

    // OPACITY --- unitless, correctly does NOT scale with screen size
    readonly property real opacityBar:    0.8
    readonly property real opacityPanel:  0.96
    readonly property real opacityMuted:  0.45
    readonly property real opacityVisible: 1.0
    readonly property real opacityHidden:  0.0
    readonly property real opacityConsole: 0.95

    // ---
    //  ANIMATION EASING NOTES
    // ---
    //  Straighten phase: Easing.InOutCubic  --- mechanical, deliberate
    //  Expand phase:     Easing.OutCubic    --- decisive deployment
    //  Fade phase:       Easing.InQuad      --- content materializes
}
