-- Apps
-- PULL REQUESTS ADDING MORE WILL NOT BE ACCEPTED, CONFIG FOR YOURSELF
terminalPrimary =
"~/.config/hypr/hyprland/scripts/launch_first_available.sh 'kitty -1' 'alacritty' 'wezterm' 'konsole' 'kgx' 'uxterm' 'xterm'"
terminalSecondary =
"~/.config/hypr/hyprland/scripts/launch_first_available.sh 'ghostty --gtk-single-instance=true' 'kitty -1' 'alacritty' 'wezterm' 'konsole' 'kgx' 'uxterm' 'xterm'"
terminalTertiary =
	"~/.config/hypr/hyprland/scripts/launch_first_available.sh 'wezterm' 'konsole' 'kgx' 'uxterm' 'xterm'"
fileManager =
	"~/.config/hypr/hyprland/scripts/launch_first_available.sh 'dolphin' 'nautilus' 'nemo' 'thunar' 'kitty -1 fish -c yazi'"
browser =
	"~/.config/hypr/hyprland/scripts/launch_first_available.sh 'google-chrome-stable' 'zen-browser' 'firefox' 'brave' 'chromium' 'microsoft-edge-stable' 'opera' 'librewolf'"
codeEditor =
	"~/.config/hypr/hyprland/scripts/launch_first_available.sh 'windsurf' 'antigravity' 'cursor' 'code' 'codium' 'zed' 'zedit' 'zeditor' 'kate' 'gnome-text-editor' 'emacs' 'command -v nvim && kitty -1 nvim' 'command -v micro && kitty -1 micro'"
officeSoftware =
	"~/.config/hypr/hyprland/scripts/launch_first_available.sh 'wps' 'onlyoffice-desktopeditors' 'libreoffice'"
textEditor = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'kate' 'gnome-text-editor' 'emacs'"
volumeMixer = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'pavucontrol-qt' 'pavucontrol'"
settingsApp =
	"XDG_CURRENT_DESKTOP=GNOME ~/.config/hypr/hyprland/scripts/launch_first_available.sh 'gnome-control-center' 'nwg-look' 'systemsettings' 'better-control'"
taskManager =
	"~/.config/hypr/hyprland/scripts/launch_first_available.sh 'gnome-system-monitor' 'plasma-systemmonitor --page-name Processes' 'command -v btop && kitty -1 fish -c btop'"
appManager = "~/.config/fuzzel/launch.sh"

-- Number-key bank size for Super+1..0 (relative nav is infinite, non-wrapping)
workspaceGroupSize = 10

-- Animation preset (hyprland/animations/*.lua)
-- Options: end4, impulse, theme, classic, standard, fast, high, dynamic,
--   optimized, moving, vertical, diablo-1, diablo-2, me-1, me-2,
--   minimal-1, minimal-2, ja, LimeFrenzy, disable
animationPreset = "impulse"
