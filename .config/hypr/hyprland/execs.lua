-- put former exec-once commands inside the func and former exec commands outside
hl.on("hyprland.start", function()
	-- local variables
	local home = os.getenv("HOME")
	local wallpaper_script_path = string.format("%s/.config/hypr/hyprland/scripts/wallpaper.sh", home)
	local quickshell_cfg_main = string.format("astral-vagabond")
	
	-- Bar, wallpaper
	hl.exec_cmd("$HOME/.config/hypr/hyprland/scripts/start_geoclue_agent.sh")
	hl.exec_cmd("$HOME/.config/hypr/custom/scripts/__restore_video_wallpaper.sh")

	-- Core components (authentication, lock screen, notification daemon)
	hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
	-- Honor settings AUTOLOCK tile (~/.config/hypridle/.disabled)
	hl.exec_cmd("sh -c 'f=\"${XDG_CONFIG_HOME:-$HOME/.config}/hypridle/.disabled\"; [ -f \"$f\" ] || exec /usr/bin/hypridle'")
	hl.exec_cmd("dbus-update-activation-environment --all")
	hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP") -- Some fix idk

	-- GhosTTY initializer
	-- If GhosTTY lags behind, uncomment to make it faster, this will keep a window open in the background
	hl.exec_cmd("ghostty --gtk-single-instance=true --quit-after-last-window-closed=false --initial-window=false")

	-- notification daemon initializer
	hl.exec_cmd("mako")

	-- Audio
	hl.exec_cmd("easyeffects --hide-window --service-mode")

	-- Clipboard: history
	hl.exec_cmd("wl-paste --watch cliphist store")

	-- Cursor
	hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")

	-- Wallpaper: awww (replaces hyprpaper; animated transitions + native GIF)
	-- Kill legacy hyprpaper if anything still spawns it, start the daemon, then
	-- apply the default image via wallpaper.sh (waits for the socket + fade).
	hl.exec_cmd("pkill -x hyprpaper 2>/dev/null || true")
	hl.exec_cmd("sh -c 'pgrep -u \"$USER\" -x awww-daemon >/dev/null || exec awww-daemon'")

	-- load quickshell
	hl.exec_cmd(string.format("quickshell -c %s",quickshell_cfg_main))
end)
