pragma Singleton
import Quickshell
import QtQuick 2.15
import "."

QtObject {

    readonly property var primaryScreen: Qt.application.screens.length > 0 ? 
                                        Qt.application.screens[0] : null

    readonly property real dpiScale: primaryScreen ? 
                                         primaryScreen.devicePixelRatio : 1.0

    property real customScale: 1.25

    readonly property real resScale: primaryScreen ?
        Math.min(primaryScreen.width / 1920, primaryScreen.height / 1080) : 1.0

    readonly property real predefinedScale: primaryScreen ?
        Math.max(0.65, Math.min(1.0, resScale * dpiScale)) : 1.0

    readonly property real scale: customScale > 0 ? customScale : predefinedScale
    // SPACING SCALE
    
    readonly property int topMargin: Math.round(5 * scale)
    readonly property int sideMargin: Math.round(5 * scale)
    readonly property int spacingXss: Math.round(2 * scale)
    readonly property int spacingXs:  Math.round(4  * scale)
    readonly property int spacingSm:  Math.round(6  * scale)
    readonly property int spacingMd:  Math.round(10 * scale)
    readonly property int spacingLg:  Math.round(16 * scale)
    readonly property int spacingXl:  Math.round(24 * scale)

    readonly property int borderXss: Math.round(2 * scale)
    readonly property int borderXs:  Math.round(4 * scale)
    readonly property int borderSm:  Math.round(6 * scale)
    readonly property int borderMd:  Math.round(10 * scale)
    readonly property int borderLg:  Math.round(16 * scale)
    
    readonly property int columnSpacing: Math.round(4 * scale)

    readonly property int paddingH: Math.round(6 * scale)
    readonly property int paddingV: Math.round(6 * scale)

    readonly property int barMarginTop: Math.round(8 * scale)

    // RADII
    readonly property int radiusXss: Math.round(3  * scale)
    readonly property int radiusXs: Math.round(5  * scale)
    readonly property int radiusSm: Math.round(6  * scale)
    readonly property int radiusMd: Math.round(10 * scale)
    readonly property int radiusLg: Math.round(16 * scale)
    readonly property int radiusXl: Math.round(24 * scale)

    // BAR GEOMETRY
    // Left matches right bar width; left shows a sliding window of N workspaces.
    // centerSmallerWidth is the dashboard / bottom-bar width.
    readonly property int rightWidth:   Math.round(350 * scale)
    readonly property int rightHeight:  Math.round(35  * scale)
    readonly property int leftWidth:    rightWidth
    readonly property int leftHeight:   rightHeight
    readonly property int workspaceBarVisible: 5
    readonly property int centerWidth:  Math.round(840 * scale)
    readonly property int centerHeight: Math.round(45  * scale)

    readonly property int centerSmallerWidth: centerWidth - 2 * centerHeight

    readonly property int exclusiveZone: Math.round(45 * scale)

    // CENTER EXPANSION GEOMETRY
    // Collapsed: HUD-sized pill. Expanded: HUD + gap + per-widget body.
    readonly property int centerCollapsedWidth:  Math.round(520 * scale)
    readonly property int centerCollapsedHeight: leftHeight
    readonly property int centerExpandedHeight:  Math.round(420 * scale)

    // Per-widget body sizes (HUD chrome sits outside these).
    // Every center-bar widget has a unique width AND unique height so the
    // morph is obvious. Dashboard stays the wide throne.
    readonly property int widgetDashboardWidth:  centerSmallerWidth
    readonly property int widgetDashboardHeight: centerExpandedHeight
    // Console launcher body. QML property names cannot start with uppercase,
    // so these are consoleWidgetWidth / consoleWidgetHeight (not ConsoleWidget*).
    readonly property int consoleWidgetWidth:    Math.round(620 * scale)
    readonly property int consoleWidgetHeight:   Math.round(400 * scale)
    readonly property int widgetMediaWidth:      Math.round(545 * scale)
    readonly property int widgetMediaHeight:     Math.round(345 * scale)
    readonly property int widgetSettingsWidth:   Math.round(415 * scale)
    readonly property int widgetSettingsHeight:  Math.round(365 * scale)
    readonly property int widgetNotifWidth:      Math.round(370 * scale)
    readonly property int widgetNotifHeight:     Math.round(315 * scale)
    readonly property int widgetBluetoothWidth:  Math.round(335 * scale)
    readonly property int widgetBluetoothHeight: Math.round(285 * scale)
    readonly property int widgetWifiWidth:       Math.round(300 * scale)
    readonly property int widgetWifiHeight:      Math.round(250 * scale)

    function widgetWidthFor(id) {
        switch (id) {
        case "dashboard":     return widgetDashboardWidth
        case "console":       return consoleWidgetWidth
        case "media":         return widgetMediaWidth
        case "wifi":          return widgetWifiWidth
        case "bluetooth":     return widgetBluetoothWidth
        case "settings":      return widgetSettingsWidth
        case "notifications": return widgetNotifWidth
        default:              return widgetWifiWidth
        }
    }

    function widgetHeightFor(id) {
        switch (id) {
        case "dashboard":     return widgetDashboardHeight
        case "console":       return consoleWidgetHeight
        case "media":         return widgetMediaHeight
        case "wifi":          return widgetWifiHeight
        case "bluetooth":     return widgetBluetoothHeight
        case "settings":      return widgetSettingsHeight
        case "notifications": return widgetNotifHeight
        default:              return widgetWifiHeight
        }
    }

    // DROPDOWN / LIST GEOMETRY
    readonly property int listPanelWidth:   Math.round(108 * scale)
    readonly property int listRowHeight:    Math.round(22  * scale)
    readonly property int statBoxHeight:    Math.round(40  * scale)
    readonly property int actionBtnHeight:  Math.round(28  * scale)
    readonly property int sliderTrackWidth: Math.round(50  * scale)
    readonly property int sliderTrackDepth: Math.round(4   * scale)
    readonly property int usageBarWidth:    Math.round(50  * scale)
    readonly property int usageBarHeight:   Math.round(4   * scale)

    // WEATHER / FORECAST
    readonly property int forecastDayCount:         7
    readonly property int forecastRowHeight:        Math.round(statBoxHeight + spacingXs)
    readonly property int forecastDowWidth:         Math.round(spacingXl + spacingSm)
    readonly property int forecastIconWidth:        spacingLg
    readonly property int forecastTempWidth:        Math.round(spacingXl * 2 + spacingSm)
    readonly property int weatherCardMinHeight:     statBoxHeight * 3
    readonly property int weatherCurrentMaxLines:   2
    readonly property int weatherHourlySampleIndex: 4
    readonly property int weatherRefreshMs:         600000
    readonly property int weatherFetchTimeoutSec:   10

    // SLAYER DASHBOARD --- mission timer, disk, net, updates, notif badge
    readonly property int missionFocusSec:     25 * 60
    readonly property int missionBreakSec:      5 * 60
    readonly property int missionLongBreakSec: 15 * 60
    readonly property int diskRefreshMs:        30000
    readonly property int netRefreshMs:         2000
    readonly property int updatesRefreshMs:     300000   // 5 min background
    readonly property int updatesRefreshActiveMs: 60000  // 1 min while dashboard open
    readonly property int notifBadgePollMs:     3000
    readonly property int toastWidth:           Math.round(360 * scale)
    readonly property int toastMaxVisible:      5
    readonly property int toastTimeoutMs:       6000
    readonly property int toastCardMinHeight:   Math.round(76 * scale)
    readonly property int toastSurfaceWidth:    toastWidth + 2 * centerMaskPad
    readonly property int toastSurfaceHeight:   toastMaxVisible
        * (toastCardMinHeight + spacingLg + spacingXs)
        + 2 * centerMaskPad
    readonly property int wallpaperScanMax:     48
    readonly property int wallpaperListRows:    6
    // Side-by-side DISK (arc) + NET (bars) — keep short so weather/patches can flex
    readonly property int diskNetCardHeight: Math.round(statBoxHeight * 1.75 + spacingSm)
    readonly property int diskArcSize:       Math.round(statBoxHeight * 1.35)
    readonly property int netBarCount:       7
    readonly property int netBarGap:         Math.max(1, Math.round(2 * scale))


    readonly property int screenWidth:  primaryScreen ? primaryScreen.width  : 0
    readonly property int screenHeight: primaryScreen ? primaryScreen.height : 0

    readonly property int edgeToggleHeight: Math.round(48 * scale)

    // BOTTOM POWER BAR --- width tracks centerSmallerWidth, height tracks center bar
    readonly property int bottomBarWidth:  centerSmallerWidth
    readonly property int bottomBarHeight: centerHeight

    // MEDIA / CAVA
    readonly property int mediaPollMs:            1000
    readonly property int mediaArtMinSide:        statBoxHeight
    readonly property real mediaArtWidthFrac:     0.38
    readonly property real mediaArtHeightFrac:    0.42
    readonly property int cavaBars:               80
    readonly property int cavaFramerate:          60
    readonly property int cavaSensitivity:        100
    readonly property real cavaOverlayHeightFrac: 0.22
    readonly property real cavaOverlayYFrac:      0.78
    readonly property real cavaOverlayOpacity:    0.85

    // PIPEWIRE AUDIO INIT (never hard-stop; backoff after fast phase)
    readonly property int audioInitDelayMs:    300
    readonly property int audioRetryFastMs:    250
    readonly property int audioRetrySlowMs:    2000
    readonly property int audioRetryFastCount: 120   // ~30s of fast polls before slow

    readonly property int iconSizeSmall:  Math.round(4  * scale)
    readonly property int iconSizeBase:   Math.round(8  * scale)
    readonly property int iconSizeMedium: Math.round(12 * scale)
    readonly property int iconSizeLarge:  Math.round(14 * scale)
    readonly property int iconSizeBottom: Math.max(iconSizeLarge, bottomBarHeight - 2 * paddingV)


    readonly property int fontSizeTiny:    Math.round(9  * scale)
    readonly property int fontSizeSmall:   Math.round(11 * scale)
    readonly property int fontSizeBase:    Math.round(13 * scale)
    readonly property int fontSizeLabel:   Math.round(9  * scale)
    readonly property int fontSizeConsole: Math.round(11 * scale)
    readonly property int fontSizeMedium:  Math.round(16 * scale)
    readonly property int fontSizeStat:    Math.round(18 * scale)
    readonly property int fontSizeLarge:   Math.round(22 * scale)
    readonly property int fontSizeHuge:    Math.round(32 * scale)

    readonly property real monoCharWidth:  fontSizeSmall  * 0.6
    readonly property real kogniCharWidth: fontSizeBase   * 0.75
    readonly property real kogniMedWidth:  fontSizeMedium * 0.75

    readonly property real strokeWidth:       1.0 * scale
    readonly property real strokeWidthActive: 1.5 * scale

    // Extra hitbox around the morphing chrome. Scale-invariant; keeps the
    // input mask off the border AA and taller than the dashboard body.
    readonly property int centerMaskPad: Math.round(12 * scale)
    readonly property int centerBodyGap: Math.max(1, Math.round(strokeWidth))
    readonly property int centerChromeMaxHeight: centerHeight
        + centerBodyGap
        + Math.max(
            widgetDashboardHeight,
            consoleWidgetHeight,
            widgetMediaHeight,
            widgetWifiHeight,
            widgetBluetoothHeight,
            widgetSettingsHeight,
            widgetNotifHeight
        )
    // Always taller than the dashboard body: HUD + gap + dashboard + inner
    // padding + mask pad on both sides.
    readonly property int centerMaskHeight: Math.max(
        centerChromeMaxHeight + paddingV + 2 * centerMaskPad,
        widgetDashboardHeight + 2 * centerMaskPad
    )

    // Center layer surface stays this size so Hyprland never resizes/re-centers it.
    // Inner chrome morphs inside; input mask is padded to centerMaskHeight.
    readonly property int centerSurfaceWidth: Math.max(
        centerCollapsedWidth,
        widgetDashboardWidth,
        consoleWidgetWidth,
        widgetMediaWidth,
        widgetWifiWidth,
        widgetBluetoothWidth,
        widgetSettingsWidth,
        widgetNotifWidth
    ) + 2 * centerMaskPad
    readonly property int centerSurfaceHeight: centerMaskHeight

    readonly property int workspaceToggleMargin: Math.round(10 * scale)
    readonly property int workspacePollMs:       750
    // Compact workspace number cell (icons live in a separate strip, not in-cell)
    readonly property int workspaceCellWidth:    Math.round(fontSizeSmall + spacingSm)
    readonly property int workspaceStripIcon:    Math.max(iconSizeMedium, Math.round(14 * scale))
    readonly property int workspaceStripMaxIcons: 4
    readonly property int workspaceBarIconSize:  Math.max(iconSizeLarge, Math.round(16 * scale))
    // Board: content-sized 5×2 grid of landscape mini-desktops (screen aspect)
    // Sized to hug the grid — no giant empty panel. Matches bar/panel scale density.
    readonly property int workspaceBoardCols:    5
    readonly property int workspaceBoardMiniW:   Math.round(170 * scale)  // ~221 @ 1.3
    readonly property int workspaceBoardGap:     spacingSm
    readonly property int workspaceBoardIcon:    Math.round(18 * scale)
    readonly property int workspaceMiniPad:      Math.round(4 * scale)
    // Compact per-tile label strip (no separate FOOTER row — click tile to focus)
    readonly property int workspaceBoardLabelH:  Math.round(16 * scale)
    // Outer card padding around the grid + title row
    readonly property int workspaceBoardPad:     paddingH
    // Fallback fixed size (board prefers its own implicit size from content)
    readonly property int workspaceBoardWidth: {
        const cols = workspaceBoardCols
        const gap  = workspaceBoardGap
        const pad  = workspaceBoardPad * 2
        return pad + cols * workspaceBoardMiniW + Math.max(0, cols - 1) * gap
    }
    readonly property int workspaceBoardHeight: {
        // title + separator + 2 rows of (label + 16:9 mini) + gaps + pad
        // Real height is computed in WorkspaceBoard; this is a safe default.
        const rows = 2
        const gap  = workspaceBoardGap
        const pad  = workspaceBoardPad * 2
        const miniH = Math.round(workspaceBoardMiniW * 9 / 16)
        const cellH = workspaceBoardLabelH + miniH + spacingXss
        const title = actionBtnHeight + spacingSm + Math.round(strokeWidth) + spacingSm
        return pad + title + rows * cellH + Math.max(0, rows - 1) * gap
    }


    readonly property int animInstant:    60
    readonly property int animFast:       120
    readonly property int animMedium:     220
    readonly property int animSlow:       400
    readonly property int animStraighten: 150
    readonly property int animExpand:     300
    readonly property int animFadeIn:     150
    readonly property int animFadeDelay:  450
    // Inner chrome morph only — never used on the Wayland surface size.
    readonly property int widgetMorphMs:  animExpand

    // LOCK SCREEN (ext-session-lock via WlSessionLock)
    readonly property real lockHeightFrac:        0.70
    readonly property real lockWidthFrac:         0.88
    readonly property real lockRatio:             1.82
    readonly property int  lockPad:               Math.round(24 * scale)
    readonly property int  lockCenterWidth:       Math.round(300 * scale)
    readonly property int  lockClockSize:         Math.round(86 * scale)
    readonly property int  lockDotSize:           Math.round(10 * scale)
    readonly property int  lockFaceSize:          Math.round(96 * scale)
    readonly property int  lockInputHeight:       Math.round(48 * scale)
    readonly property int  lockShowForecastHeight: Math.round(520 * scale)
}
