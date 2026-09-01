# Changelog

History of **hyprland-dots** — astral-vagabond + Ash monochrome.  
Newest entries first.

---

## 2026-09-01 — Clipboard wipe resets cliphist index

- Super+V / Super+Shift+V go through `hypr/hyprland/scripts/fuzzel-clipboard.sh`
- Super+Shift+V deletes the cliphist db (not just `cliphist wipe`) so IDs start at 1 again

## 2026-08-25 — Quickshell console launcher + notification toasts

- **Console** is a first-class center-bar widget (QuickLaunch icon). Super+A / `qs -c astral-vagabond ipc call launcher toggle` opens it.
- Console lists every desktop app and applet (`DesktopEntries` + actions), with type-to-filter.
- Tokens: `consoleWidgetWidth` / `consoleWidgetHeight` (620×400). Other center widgets each have a unique width and height so the morph is distinct.
- **Notifications** are owned by Quickshell (`NotifServer` + top-right toasts). Mako is no longer started. Inbox / DND / silent stay in the notifications widget.
- Hypr layer `no_anim` is unchanged (still on for astral-vagabond surfaces). Toast and console motion is QML only.
- Fuzzel remains only for Super+. emoji and Super+V clipboard dmenu.

## 2026-08-25 — Wallust clients + fuzzel chrome

- Wallust / Ash loaders also paint **mako** and **fuzzel** from `active-colors.json` (`hypr/hyprland/scripts/apply-theme-clients.sh`)
- Mako layout lives in `mako/config.tmpl`; generated `mako/config` is what mako reads
- Fuzzel palette is `fuzzel/colors.ini` (included last); launcher is a compact rounded-rect card (2px accent border, radius 8)
- Hypr layer rules for `launcher` and `notifications`: blur, no anim, xray off

---

## 2026-08 — Astral-Vagabond rework (current)

### Console layout (directory)
- Moved Wi‑Fi / Bluetooth / settings / notifications from dead `edges/rightEdge/` into `widgets/centerBarWidgets/console/`
- `EdgeTabs` → `ConsoleTabs`; removed unused `RightEdgePanel` and the empty `edges/` tree

### Power inhibit (settings)
- **CAFFEINE** tile: toggles `hyprcaffeine` (blocks suspend / sleep)
- **AUTOLOCK / NO LOCK** tile: toggles hypridle via `utils/scripts/idle-toggle.sh` (no auto-lock)
- Active state highlighted on both tiles; polls status while settings stay open

### Shell & identity
- Renamed Quickshell stack **doomshell → astral-vagabond**
- Install entrypoint **`doom.sh` → `install`** (no theme lore in CLI)
- Dropped edge slide-out panel; Wi‑Fi / Bluetooth / settings / notifications live in **center Console**

### Ash monochrome palette
- Soft charcoal surfaces (`#121212` / `#1A1A1A` / `#242424`), silver accents, low-glare text
- Applied across astral-vagabond Theme, hypr borders, hyprlock, mako, fuzzel, rofi, KDE colors, nvim, oh-my-posh, kitty, ghostty, wezterm, fish
- Right-bar labels (BAT / VOL / CPU / GPU / RAM) contrast fixed for readability
- Scrollbars use Controls.Basic so system “red accent” no longer paints the thumb

### Wallust
- Wallpaper recolor limited to **text + icon accents**; Ash surfaces always kept
- Terminal/fish auto-write from wallust was tried and **reverted** (shell-only wallust)

### Console
- App list: plain categories and short descriptions (no lore)
- Right pane: edge controls (network, bluetooth, configuration, notifications)
- Layout: apps column capped so it cannot swallow the controls pane
- Labels: CODEX → APPS, DEPLOY → LAUNCH; VEGA → Grok

### Center status bar
- Cycling messages: system/session utility lines instead of combat slogans
- Battery / time greetings: plain AC / battery / good morning / late session

### Fixes
- ConsoleWidget `sourceSize` binding loop (stack overflow on icons)
- GPU frequency bars / usage fill use Theme greys instead of hardcoded orange
- `MonoScrollBar` replaces DoomScrollBar

### Installer
- `./install` — packages, config rsync, SDDM greeter (astronaut theme)
- Targets Arch / CachyOS; optional AUR via paru/yay

---

## Earlier (pre-astral-vagabond)

Forked from a HyDE / Bad Blood–era quickshell rice with a heavy theme overlay (doomshell, red/orange palette, themed launcher copy). That direction is retired; see git history if you need old assets.

Notable past experiments (superseded):

- Fastfetch / OMP / wallpapers oriented around that theme
- Waybar / AGS paths later replaced by Quickshell astral-vagabond
- SDDM astronaut conf under a themed filename (still installable as greeter config)

---

## Planned

- [ ] Finish de-theme remaining `scripts/bash/*` names and notify-send app names
- [ ] Neutral SDDM conf filename + wallpaper set
- [ ] Optional wallust → terminal themes (opt-in flag only)
- [ ] Clean `Pictures/` defaults (remove unused media)
- [ ] Document keybind map in README or `docs/keybinds.md`

---

*Prefer small, reversible changes. Keep Ash chrome stable.*
