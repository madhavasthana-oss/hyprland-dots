pragma Singleton
import Quickshell
import QtQuick 2.15
import "."

QtObject {
    id: root

    readonly property var primaryScreen: Qt.application.screens.length > 0
        ? Qt.application.screens[0] : null

    readonly property real dpiScale: primaryScreen
        ? primaryScreen.devicePixelRatio : 1.0

    property real customScale: 1.25

    readonly property real resScale: primaryScreen
        ? Math.min(primaryScreen.width / 1920, primaryScreen.height / 1080) : 1.0

    readonly property real predefinedScale: primaryScreen
        ? Math.max(0.65, Math.min(1.0, resScale * dpiScale)) : 1.0

    readonly property real scale: customScale > 0 ? customScale : predefinedScale

    // =====================================================================
    //  NESTED TOKEN GROUPS  (preferred API: Tokens.spacing.md, Tokens.radius.lg, …)
    // =====================================================================

    readonly property QtObject spacing: QtObject {
        readonly property int xss: Math.round(2  * root.scale)
        readonly property int xs:  Math.round(4  * root.scale)
        readonly property int sm:  Math.round(6  * root.scale)
        readonly property int md:  Math.round(10 * root.scale)   // medium
        readonly property int lg:  Math.round(16 * root.scale)
        readonly property int xl:  Math.round(24 * root.scale)
    }

    readonly property QtObject border: QtObject {
        readonly property int xss: Math.round(2  * root.scale)
        readonly property int xs:  Math.round(4  * root.scale)
        readonly property int sm:  Math.round(6  * root.scale)
        readonly property int md:  Math.round(10 * root.scale)
        readonly property int lg:  Math.round(16 * root.scale)
    }

    readonly property QtObject radius: QtObject {
        readonly property int xss: Math.round(3  * root.scale)
        readonly property int xs:  Math.round(5  * root.scale)
        readonly property int sm:  Math.round(6  * root.scale)
        readonly property int md:  Math.round(10 * root.scale)
        readonly property int lg:  Math.round(16 * root.scale)
        readonly property int xl:  Math.round(24 * root.scale)
    }

    readonly property QtObject padding: QtObject {
        readonly property int h: Math.round(6 * root.scale)
        readonly property int v: Math.round(6 * root.scale)
    }

    // Named "type" (not "font"/"console") — those collide with QML reserved names
    readonly property QtObject type: QtObject {
        readonly property int tiny:     Math.round(9  * root.scale)
        readonly property int small:    Math.round(11 * root.scale)
        readonly property int base:     Math.round(13 * root.scale)
        readonly property int label:    Math.round(9  * root.scale)
        readonly property int cons:     Math.round(11 * root.scale)  // console body text
        readonly property int medium:   Math.round(16 * root.scale)
        readonly property int stat:     Math.round(18 * root.scale)
        readonly property int large:    Math.round(22 * root.scale)
        readonly property int huge:     Math.round(32 * root.scale)
    }

    readonly property QtObject icon: QtObject {
        readonly property int small:  Math.round(4  * root.scale)
        readonly property int base:   Math.round(8  * root.scale)
        readonly property int medium: Math.round(12 * root.scale)
        readonly property int large:  Math.round(14 * root.scale)
        readonly property int bottom: Math.max(large, root.bottomBarHeight - 2 * root.padding.v)
    }

    readonly property QtObject stroke: QtObject {
        readonly property real base:   1.0 * root.scale
        readonly property real active: 1.5 * root.scale
    }

    readonly property QtObject anim: QtObject {
        readonly property int instant:    60
        readonly property int fast:       120
        readonly property int medium:     220
        readonly property int slow:       400
        readonly property int straighten: 150
        readonly property int expand:     300
        readonly property int fadeIn:     150
        readonly property int fadeDelay:  450
    }

    // Screen / bar geometry for the unified top bar
    readonly property QtObject rounding: QtObject {
        // Concave cutout size under the bar and beside deployed panels
        readonly property int screen: Math.round(16 * root.scale)
    }

    readonly property QtObject bar: QtObject {
        // Slim full-width top bar (hugs screen edge)
        readonly property int height: Math.round(40 * root.scale)
        readonly property int topMargin: 0
        readonly property int exclusiveZone: height
        // Soft side padding inside the bar content row
        readonly property int padH: Math.round(10 * root.scale)
        readonly property int sectionGap: Math.round(10 * root.scale)
        // Zone preferred widths (flex, not hard windows)
        readonly property int leftPreferred:  Math.round(340 * root.scale)
        readonly property int rightPreferred: Math.round(360 * root.scale)
        readonly property int centerMin:      Math.round(280 * root.scale)
        // Glow under the bar strip
        readonly property int glowHeight: Math.round(10 * root.scale)
        readonly property real glowOpacity: 0.55
    }

    // =====================================================================
    //  FLAT ALIASES  (back-compat with existing widgets)
    // =====================================================================

    readonly property int topMargin:  bar.topMargin
    readonly property int sideMargin: 0
    readonly property int spacingXss: spacing.xss
    readonly property int spacingXs:  spacing.xs
    readonly property int spacingSm:  spacing.sm
    readonly property int spacingMd:  spacing.md
    readonly property int spacingLg:  spacing.lg
    readonly property int spacingXl:  spacing.xl

    readonly property int borderXss: border.xss
    readonly property int borderXs:  border.xs
    readonly property int borderSm:  border.sm
    readonly property int borderMd:  border.md
    readonly property int borderLg:  border.lg

    readonly property int columnSpacing: spacing.xs
    readonly property int marginTop:     0

    readonly property int paddingH: padding.h
    readonly property int paddingV: padding.v

    readonly property int barGap:       0
    readonly property int barMarginTop: Math.round(8 * scale)

    readonly property int radiusXss: radius.xss
    readonly property int radiusXs:  radius.xs
    readonly property int radiusSm:  radius.sm
    readonly property int radiusMd:  radius.md
    readonly property int radiusLg:  radius.lg
    readonly property int radiusXl:  radius.xl

    // Legacy three-bar geometry — kept for widgets that still reference them
    readonly property int rightWidth:   bar.rightPreferred
    readonly property int rightHeight:  bar.height
    readonly property int leftWidth:    bar.leftPreferred
    readonly property int leftHeight:   bar.height
    readonly property int workspaceBarVisible: 5
    readonly property int centerWidth:  Math.round(800 * scale)
    readonly property int centerHeight: bar.height
    readonly property int centerSmallerWidth: Math.round(640 * scale)

    readonly property int preferredWidthNoGreeting: Math.round(80  * scale)
    readonly property int greetingWidth:            Math.round(204 * scale)

    readonly property int exclusiveZone: bar.exclusiveZone

    // CENTER EXPANSION GEOMETRY
    readonly property int centerCollapsedWidth:  Math.round(640 * scale)
    readonly property int centerCollapsedHeight: Math.round(30  * scale)
    readonly property int centerExpandedWidth:   Math.round(800 * scale)
    readonly property int centerExpandedHeight:  Math.round(420 * scale)

    readonly property int angleOffsetCollapsed: Math.round(30 * scale)
    readonly property int angleOffsetExpanded:  0
    readonly property int angleOffsetDefault:   Math.round(45 * scale)

    // PANEL DIMENSIONS
    readonly property int statPanelWidth:  Math.round(580 * scale)
    readonly property int statPanelHeight: Math.round(190 * scale)

    // DROPDOWN / LIST GEOMETRY
    readonly property int listPanelWidth:   Math.round(108 * scale)
    readonly property int listRowHeight:    Math.round(22  * scale)
    readonly property int statBoxHeight:    Math.round(40  * scale)
    readonly property int actionBtnHeight:  Math.round(28  * scale)
    readonly property int tabHeight:        Math.round(20  * scale)
    readonly property int sliderTrackWidth: Math.round(50  * scale)
    readonly property int sliderTrackDepth: Math.round(4   * scale)
    readonly property int usageBarWidth:    Math.round(50  * scale)
    readonly property int usageBarHeight:   Math.round(4   * scale)

    // WEATHER / FORECAST
    readonly property int forecastDayCount:         7
    readonly property int forecastRowHeight:        Math.round(statBoxHeight + spacing.xs)
    readonly property int forecastDowWidth:         Math.round(spacing.xl + spacing.sm)
    readonly property int forecastIconWidth:        spacing.lg
    readonly property int forecastTempWidth:        Math.round(spacing.xl * 2 + spacing.sm)
    readonly property int weatherCardMinHeight:     statBoxHeight * 3
    readonly property int weatherCurrentMaxLines:   2
    readonly property int weatherHourlySampleIndex: 4
    readonly property int weatherRefreshMs:         600000
    readonly property int weatherFetchTimeoutSec:   10

    // SLAYER DASHBOARD
    readonly property int missionFocusSec:     25 * 60
    readonly property int missionBreakSec:      5 * 60
    readonly property int missionLongBreakSec: 15 * 60
    readonly property int diskRefreshMs:        30000
    readonly property int netRefreshMs:         2000
    readonly property int updatesRefreshMs:     300000
    readonly property int updatesRefreshActiveMs: 60000
    readonly property int notifBadgePollMs:     3000
    readonly property int wallpaperScanMax:     48
    readonly property int wallpaperListRows:    6
    readonly property int diskNetCardHeight: Math.round(statBoxHeight * 1.75 + spacing.sm)
    readonly property int diskArcSize:       Math.round(statBoxHeight * 1.35)
    readonly property int netBarCount:       7
    readonly property int netBarGap:         Math.max(1, Math.round(2 * scale))

    // SCREEN GEOMETRY
    readonly property int screenWidth:  primaryScreen ? primaryScreen.width  : 0
    readonly property int screenHeight: primaryScreen ? primaryScreen.height : 0

    readonly property int screenCenterX: Math.round(screenWidth  / 2)
    readonly property int screenCenterY: Math.round(screenHeight / 2)

    readonly property int screenTopCenterX:    screenCenterX
    readonly property int screenBottomCenterX: screenCenterX
    readonly property int screenLeftCenterY:   screenCenterY
    readonly property int screenRightCenterY:  screenCenterY

    readonly property int screenTopY:    0
    readonly property int screenBottomY: screenHeight
    readonly property int screenLeftX:   0
    readonly property int screenRightX:  screenWidth

    // EDGE PANELS
    readonly property int edgeHoverZoneWidth: Math.round(45  * scale)
    readonly property int edgePanelWidth:     Math.round(280 * scale)
    readonly property int edgeToggleHeight:   Math.round(48  * scale)
    readonly property int edgeHotzonePx:      Math.round(4   * scale)

    // BOTTOM POWER BAR
    readonly property int bottomBarWidth:  centerSmallerWidth
    readonly property int bottomBarHeight: bar.height
    readonly property int bottomBarOriginX: screenBottomCenterX - Math.round(bottomBarWidth / 2)

    readonly property int edgePanelPad: Math.max(radius.xl + border.xs, border.md + border.xs)
    readonly property int edgeWidgetWidth:  edgePanelWidth
    readonly property int edgeWidgetHeight: Math.round(edgePanelWidth * 1.5)
    readonly property int edgeWindowWidth:  edgeWidgetWidth  + 2 * edgePanelPad
    readonly property int edgeWindowHeight: edgeWidgetHeight + 2 * edgePanelPad
    readonly property int edgeWidgetOriginY: screenRightCenterY - Math.round(edgeWindowHeight / 2)

    readonly property int edgeHoverZoneCollapsed: Math.max(edgeHotzonePx, barInset)
    readonly property int bottomHoverZoneHeight: Math.max(edgeHotzonePx, barInset)
    readonly property int bottomBarMargin: barMarginTop
    readonly property int bottomHideDelay: anim.medium
    readonly property int edgeHideDelay:   anim.medium
    readonly property int edgeForceTimeoutMs: 10000

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

    // PIPEWIRE AUDIO INIT
    readonly property int audioInitDelayMs:    300
    readonly property int audioRetryFastMs:    250
    readonly property int audioRetrySlowMs:    2000
    readonly property int audioRetryFastCount: 120

    readonly property int iconSizeSmall:  icon.small
    readonly property int iconSizeBase:   icon.base
    readonly property int iconSizeMedium: icon.medium
    readonly property int iconSizeLarge:  icon.large
    readonly property int iconSizeBottom: icon.bottom

    readonly property int fontSizeTiny:    type.tiny
    readonly property int fontSizeSmall:   type.small
    readonly property int fontSizeBase:    type.base
    readonly property int fontSizeLabel:   type.label
    readonly property int fontSizeConsole: type.cons
    readonly property int fontSizeMedium:  type.medium
    readonly property int fontSizeStat:    type.stat
    readonly property int fontSizeLarge:   type.large
    readonly property int fontSizeHuge:    type.huge

    readonly property real monoCharWidth:  type.small  * 0.6
    readonly property real kogniCharWidth: type.base   * 0.75
    readonly property real kogniMedWidth:  type.medium * 0.75

    readonly property real strokeWidth:       stroke.base
    readonly property real strokeWidthActive: stroke.active

    readonly property int blurRadius: Math.round(18 * scale)
    readonly property int barInset: Math.round(6 * scale)

    readonly property int workspaceToggleMargin: Math.round(10 * scale)
    readonly property int workspaceMargins:      Math.round(6  * scale)
    readonly property int workspacePollMs:       750
    readonly property int workspaceCellWidth:    Math.round(type.small + spacing.sm)
    readonly property int workspaceStripIcon:    Math.max(icon.medium, Math.round(14 * scale))
    readonly property int workspaceStripMaxIcons: 4
    readonly property int workspaceBarIconSize:  Math.max(icon.large, Math.round(16 * scale))
    readonly property int workspaceBoardCols:    5
    readonly property int workspaceBoardMiniW:   Math.round(170 * scale)
    readonly property int workspaceBoardGap:     spacing.sm
    readonly property int workspaceBoardIcon:    Math.round(18 * scale)
    readonly property int workspaceMiniPad:      Math.round(4 * scale)
    readonly property int workspaceBoardLabelH:  Math.round(16 * scale)
    readonly property int workspaceBoardPad:     padding.h
    readonly property int workspaceBoardWidth: {
        const cols = workspaceBoardCols
        const gap  = workspaceBoardGap
        const pad  = workspaceBoardPad * 2
        return pad + cols * workspaceBoardMiniW + Math.max(0, cols - 1) * gap
    }
    readonly property int workspaceBoardHeight: {
        const rows = 2
        const gap  = workspaceBoardGap
        const pad  = workspaceBoardPad * 2
        const miniH = Math.round(workspaceBoardMiniW * 9 / 16)
        const cellH = workspaceBoardLabelH + miniH + spacing.xss
        const title = actionBtnHeight + spacing.sm + Math.round(stroke.base) + spacing.sm
        return pad + title + rows * cellH + Math.max(0, rows - 1) * gap
    }

    readonly property int animInstant:    anim.instant
    readonly property int animFast:       anim.fast
    readonly property int animMedium:     anim.medium
    readonly property int animSlow:       anim.slow
    readonly property int animStraighten: anim.straighten
    readonly property int animExpand:     anim.expand
    readonly property int animFadeIn:     anim.fadeIn
    readonly property int animFadeDelay:  anim.fadeDelay
}
