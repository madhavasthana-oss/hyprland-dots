require("hyprland.lib")
require("hyprland.variables")
if is_file_exists(HOME .. "/.config/hypr/custom/variables.lua") then
	require("custom.variables")
end

local hyprScripts = "$HOME/.config/hypr/hyprland/scripts"

hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("brightness increment || brightnessctl s 5%+"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("brightness decrement || brightnessctl s 5%-"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+ -l 1.5"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"),
	{ locked = true, repeating = true }
)
hl.bind(
	"SUPER + XF86MonBrightnessUp",
	hl.dsp.exec_cmd("keyboard brightness increment || brightnessctl --device='*::kbd_backlight' s +50%"),
	{ locked = true, repeating = true }
)
hl.bind(
	"SUPER + XF86MonBrightnessDown",
	hl.dsp.exec_cmd("keyboard brightness decrement || brightnessctl --device='*::kbd_backlight' s 50%-"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86KbdBrightnessUp",
	hl.dsp.exec_cmd("keyboard brightness increment || brightnessctl --device='*::kbd_backlight' s +50%"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86KbdBrightnessDown",
	hl.dsp.exec_cmd("keyboard brightness decrement || brightnessctl --device='*::kbd_backlight' s 50%-"),
	{ locked = true, repeating = true }
)

-- Color picker
hl.bind(
	"SUPER + SHIFT + C",
	hl.dsp.exec_cmd("hyprpicker -a"),
	{ description = "Utilities: Pick color #RRGGBB >> clipboard" }
)

-- Zoom
local function zoomfunction(value)
	local zoomvalue = hl.get_config("cursor:zoom_factor")
	if (zoomvalue + value) > 3.0 then
		hl.config({ cursor = { zoom_factor = 3.0 } })
	elseif (zoomvalue + value) < 1.0 then
		hl.config({ cursor = { zoom_factor = 1.0 } })
	else
		hl.config({ cursor = { zoom_factor = zoomvalue + value } })
	end
end
hl.bind("SUPER + Minus", function()
	zoomfunction(-0.3)
end, { repeating = true, description = "Screen: Zoom out" })
hl.bind("SUPER + Equal", function()
	zoomfunction(0.3)
end, { repeating = true, description = "Screen: Zoom in" })

-- Zoom with keypad
hl.bind("SUPER + code:82", function()
	zoomfunction(-0.3)
end, { repeating = true })
hl.bind("SUPER + code:86", function()
	zoomfunction(0.3)
end, { repeating = true })

-- Media
local mediaNextCommand =
	'playerctl next || playerctl position `bc <<< "100 * $(playerctl metadata mpris:length) / 1000000 / 100"`'
hl.bind("SUPER + SHIFT + N", hl.dsp.exec_cmd(mediaNextCommand), { locked = true, description = "Media: Next track" })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd(mediaNextCommand), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("SUPER + SHIFT + ALT + mouse:275", hl.dsp.exec_cmd("playerctl previous"))
hl.bind("SUPER + SHIFT + ALT + mouse:276", hl.dsp.exec_cmd(mediaNextCommand))
hl.bind(
	"SUPER + SHIFT + B",
	hl.dsp.exec_cmd("playerctl previous"),
	{ locked = true, description = "Media: Previous track" }
)
hl.bind(
	"SUPER + SHIFT + P",
	hl.dsp.exec_cmd("playerctl play-pause"),
	{ locked = true, description = "Media: Play/pause media" }
)
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle"), { locked = true })
hl.bind(
	"SUPER + SHIFT + M",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle"),
	{ locked = true, description = "Media: Toggle mute" }
)
hl.bind("ALT + XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"), { locked = true })
hl.bind(
	"SUPER + ALT + M",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"),
	{ locked = true, description = "Media: Toggle mic" }
)

-- Focusing
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Window: Move" })
hl.bind("SUPER + mouse:274", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Window: Resize" })

for i = 1, 4 do
	local arrowkey = { "Left", "Right", "Up", "Down" }
	local focusdir = { "l", "r", "u", "d" }
	hl.bind(
		"SUPER + " .. arrowkey[i],
		hl.dsp.focus({ direction = focusdir[i] }),
		{ description = "Window: Focus " .. arrowkey[i] }
	)
end
for i = 1, 2 do
	local arrowkey = { "BracketLeft", "BracketRight" }
	local focusdir = { "l", "r" }
	hl.bind("SUPER + " .. arrowkey[i], hl.dsp.focus({ direction = focusdir[i] }))
end
--/ bind = SUPER + SHIFT, <--/<|/→/|>,, -- Move in direction
for i = 1, 4 do
	local arrowkey = { "Left", "Right", "Up", "Down" }
	local focusdir = { "l", "r", "u", "d" }
	hl.bind(
		"SUPER + SHIFT + " .. arrowkey[i],
		hl.dsp.window.move({ direction = focusdir[i] }),
		{ description = "Window: Move " .. arrowkey[i] }
	)
end

hl.bind("ALT + F4", function()
	hl.exec_cmd('notify-send "Wrong close keybind" "Super+Q to close. Use Alt+F4 for Windows VMs" -a Hyprland')
end, { non_consuming = true })
hl.bind("SUPER + Q", hl.dsp.window.close(), { description = "Window: Close" })
hl.bind("SUPER + SHIFT + ALT + Q", hl.dsp.exec_cmd("hyprctl kill"), { description = "Window: Forcefully zap a window" })

--/ binde = SUPER, ;/',, -- Adjust split ratio
hl.bind("SUPER + Semicolon", hl.dsp.layout("splitratio -0.1"), { repeating = true })
hl.bind("SUPER + Apostrophe", hl.dsp.layout("splitratio +0.1"), { repeating = true })
-- Positioning mode
hl.bind("SUPER + ALT + Space", hl.dsp.window.float({ action = "toggle" }), { description = "Window: Float/Tile" })
hl.bind(
	"SUPER + D",
	hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }),
	{ description = "Window: Maximize" }
)
hl.bind(
	"SUPER + F",
	hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }),
	{ description = "Window: Fullscreen" }
)

--/ bind = SUPER+ALT, Hash,, -- Send to workspace -- (1, 2, 3,...)
for i = 1, 10 do
	hl.bind("SUPER + ALT + " .. (i % 10), function()
		hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(i), follow = false }))
	end, { description = "Window: Send to workspace " .. i })
end
-- We also use raw keycodes because some keyboard layouts register number keys as different chars. The codes can be verified with `wev`
-- for i = 1, 10 do
--     local numberkey = { 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 }
--     hl.bind("SUPER + ALT + code:" .. numberkey[i], function()
--         hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(i), follow = false }))
--     end)
-- end
-- keypad numbers
for i = 1, 10 do
	local numpadkey = { 87, 88, 89, 83, 84, 85, 79, 80, 81, 90 }
	hl.bind("SUPER + ALT + code:" .. numpadkey[i], function()
		hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(i), follow = false }))
	end)
end

-- Send window left/right: infinite, non-wrapping (can create higher workspaces)
hl.bind("SUPER + SHIFT + mouse_down", function()
	cycle_move_window(1)
end, { description = "Window: Move to next workspace" })
hl.bind("SUPER + SHIFT + mouse_up", function()
	cycle_move_window(-1)
end, { description = "Window: Move to previous workspace" })
hl.bind("SUPER + ALT + mouse_down", function()
	cycle_move_window(1)
end)
hl.bind("SUPER + ALT + mouse_up", function()
	cycle_move_window(-1)
end)

hl.bind("SUPER + SHIFT + Page_Down", function()
	cycle_move_window(1)
end, { description = "Window: Move to next workspace" })
hl.bind("SUPER + SHIFT + Page_Up", function()
	cycle_move_window(-1)
end, { description = "Window: Move to previous workspace" })
hl.bind("SUPER + ALT + Page_Down", function()
	cycle_move_window(1)
end)
hl.bind("SUPER + ALT + Page_Up", function()
	cycle_move_window(-1)
end)
hl.bind("CTRL + SUPER + SHIFT + Right", function()
	cycle_move_window(1)
end)
hl.bind("CTRL + SUPER + SHIFT + Left", function()
	cycle_move_window(-1)
end)

hl.bind(
	"SUPER + ALT + S",
	hl.dsp.window.move({ workspace = "special:special", follow = false }),
	{ description = "Window: Send to scratchpad" }
)
hl.bind("CTRL + SUPER + S", hl.dsp.workspace.toggle_special("special"))

-- Workspace
for i = 1, 10 do
	hl.bind("SUPER + " .. (i % 10), function()
		hl.dispatch(hl.dsp.focus({ workspace = workspace_in_group(i) }))
	end, { description = "Workspace: Focus " .. i })
end
-- We also use raw keycodes because some keyboard layouts register number keys as different chars. The codes can be verified with `wev`
for i = 1, 10 do
	local numberkey = { 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 }
	hl.bind("SUPER + code:" .. numberkey[i], function()
		hl.dispatch(hl.dsp.focus({ workspace = workspace_in_group(i) }))
	end)
end
-- keypad numbers
for i = 1, 10 do
	local numpadkey = { 87, 88, 89, 83, 84, 85, 79, 80, 81, 90 }
	hl.bind("SUPER + code:" .. numpadkey[i], function()
		hl.dispatch(hl.dsp.focus({ workspace = workspace_in_group(i) }))
	end)
end

-- Relative focus: infinite, non-wrapping (can create workspace 11, 12, …)
hl.bind("CTRL + SUPER + Left", function()
	cycle_workspace(-1)
end, { description = "Workspace: Previous" })
hl.bind("CTRL + SUPER + Right", function()
	cycle_workspace(1)
end, { description = "Workspace: Next" })
hl.bind("CTRL + SUPER + ALT + Left", function()
	cycle_workspace(-1)
end)
hl.bind("CTRL + SUPER + ALT + Right", function()
	cycle_workspace(1)
end)

hl.bind("SUPER + Page_Down", function()
	cycle_workspace(1)
end, { description = "Workspace: Next" })
hl.bind("SUPER + Page_Up", function()
	cycle_workspace(-1)
end, { description = "Workspace: Previous" })
hl.bind("CTRL + SUPER + Page_Down", function()
	cycle_workspace(1)
end)
hl.bind("CTRL + SUPER + Page_Up", function()
	cycle_workspace(-1)
end)

hl.bind("SUPER + mouse_down", function()
	cycle_workspace(1)
end, { description = "Workspace: Next (scroll)" })
hl.bind("SUPER + mouse_up", function()
	cycle_workspace(-1)
end, { description = "Workspace: Previous (scroll)" })
hl.bind("CTRL + SUPER + mouse_down", function()
	cycle_workspace(1)
end)
hl.bind("CTRL + SUPER + mouse_up", function()
	cycle_workspace(-1)
end)

-- Special
hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("special"), { description = "Workspace: Toggle scratchpad" })
hl.bind("SUPER + mouse:275", hl.dsp.workspace.toggle_special("special"))

hl.bind("CTRL + SUPER + BracketLeft", function()
	cycle_workspace(-1)
end, { description = "Workspace: Previous" })
hl.bind("CTRL + SUPER + BracketRight", function()
	cycle_workspace(1)
end, { description = "Workspace: Next" })hl.bind("CTRL + SUPER + Up", function()
	cycle_workspace(-1)
end)
hl.bind("CTRL + SUPER + Down", function()
	cycle_workspace(1)
end)

-- Virtual machines
hl.define_submap("virtual-machine", function()
	hl.bind("SUPER + ALT + F1", function()
		local currentsubmap = hl.get_current_submap()
		if currentsubmap == "virtual-machine" then
			hl.dispatch(
				hl.dsp.exec_cmd("notify-send 'Exited Virtual Machine submap' 'Keybinds re-enabled' -a 'Hyprland'")
			)
			hl.dispatch(hl.dsp.submap("reset"))
		elseif currentsubmap == "" then
			hl.dispatch(
				hl.dsp.exec_cmd(
					"notify-send 'Entered Virtual Machine submap' 'Keybinds disabled. hit SUPER+ALT+F1 to escape' -a 'Hyprland'"
				)
			)
			hl.dispatch(hl.dsp.submap("virtual-machine"))
		end
	end, { submap_universal = true })
end)

--!
-- Testing
hl.bind(
	"SUPER + ALT + F11",
	hl.dsp.exec_cmd(
		'bash -c \'RANDOM_IMAGE=$(find ~/Pictures/Wallpapers/ -type f | shuf -n 1); ACTION=$(notify-send "Test notification with body image" "This notification should contain your user account <b>image</b> and <a href=\\"https://discord.com/app\\">Discord</a> <b>icon</b>. Oh and here is a random image in your Pictures folder: <img src=\\"$RANDOM_IMAGE\\" alt=\\"Testing image\\"/>" -a "Hyprland" -p -h "string:image-path:/var/lib/AccountsService/icons/$USER" -t 6000 -i "discord" -A "openImage=Profile image" -A "action2=Open the random image" -A "action3=Useless button"); [[ $ACTION == *openImage ]] && xdg-open "/var/lib/AccountsService/icons/$USER"; [[ $ACTION == *action2 ]] && xdg-open "$RANDOM_IMAGE"\''
	)
) --  [hidden]
hl.bind(
	"SUPER + ALT + F12",
	hl.dsp.exec_cmd(
		'bash -c \'RANDOM_IMAGE=$(find ~/Pictures -type f | shuf -n 1); ACTION=$(notify-send "Test notification" "This notification should contain a random image in your <b>Pictures</b> folder and <a href=\\"https://discord.com/app\\">Discord</a> <b>icon</b>.\n<i>Flick right to dismiss!</i>" -a "Discord (fake)" -p -h "string:image-path:$RANDOM_IMAGE" -t 6000 -i "discord" -A "openImage=Profile image" -A "action2=Useless button"); [[ $ACTION == *openImage ]] && xdg-open "/var/lib/AccountsService/icons/$USER"\''
	)
) --  [hidden]
hl.bind(
	"SUPER + ALT + Equal",
	hl.dsp.exec_cmd("notify-send 'Urgent notification' 'Ah hell no' -u critical -a 'Hyprland keybind'")
) --  [hidden]

-- Session
hl.bind("SUPER + L", hl.dsp.exec_cmd("loginctl lock-session"), { description = "Session: Lock" })
hl.bind(
	"SUPER + SHIFT + L",
	hl.dsp.exec_cmd("systemctl suspend || loginctl suspend"),
	{ locked = true, description = "Session: Sleep" }
) -- Sleep
-- hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("systemctl suspend || loginctl suspend"), {locked = true} ) --  [hidden] Suspend when laptop lid is closed, uncomment if for whatever reason it's not the default behavior

hl.bind(
	"CTRL + SHIFT + ALT + SUPER + Delete",
	hl.dsp.exec_cmd("systemctl poweroff || loginctl poweroff"),
	{ description = "Session: Shut down" }
) --  [hidden] Power off

-- Apps
hl.bind("SUPER + T", hl.dsp.exec_cmd(terminalPrimary), { description = "App: Primary Terminal" })
hl.bind("SUPER + ALT + T", hl.dsp.exec_cmd(terminalSecondary), { description = "App: Secondary Terminal" })
hl.bind("SUPER + CTRL + T", hl.dsp.exec_cmd(terminalTertiary), { description = "App: Tertiary Terminal" })
hl.bind("SUPER + E", hl.dsp.exec_cmd(fileManager), { description = "App: File manager" })
hl.bind("SUPER + B", hl.dsp.exec_cmd(browser), { description = "App: Browser" })
hl.bind("SUPER + C", hl.dsp.exec_cmd(codeEditor), { description = "App: Code editor" })
hl.bind("SUPER + X", hl.dsp.exec_cmd(textEditor), { description = "App: Text editor" })
hl.bind("CTRL + SUPER + V", hl.dsp.exec_cmd(volumeMixer), { description = "App: Volume mixer" })
hl.bind("SUPER + I", hl.dsp.exec_cmd(settingsApp), { description = "App: Settings app" })
hl.bind("CTRL + SHIFT + Escape", hl.dsp.exec_cmd(taskManager), { description = "App: Task manager" })
hl.bind("SUPER + A", hl.dsp.exec_cmd(appManager), { description = "App: Console launcher"})
-- Emoji picker (fuzzel-emoji in hyprland/scripts)
hl.bind(
	"SUPER + Period",
	hl.dsp.exec_cmd(hyprScripts .. "/fuzzel-emoji.sh both"),
	{ description = "Utilities: Emoji picker" }
)
-- Pear Desktop (CachyOS package); youtube-music wrapper; Spotify fallback
hl.bind(
	"SUPER + M",
	hl.dsp.exec_cmd(
		"~/.config/hypr/hyprland/scripts/launch_first_available.sh 'pear-desktop' 'youtube-music' 'spotify'"
	),
	{ description = "App: YouTube Music (Pear Desktop)" }
)
hl.bind(
	"SUPER + ALT + V",
	hl.dsp.exec_cmd("$HOME/Doomslayer-mod/scripts/bash/cava-overlay.sh toggle"),
	{ description = "Media: Toggle cava overlay" }
)

-- Cursed stuff
-- Make window not amogus large
hl.bind("CTRL + SUPER + Backslash", hl.dsp.window.resize({ x = 640, y = 480, "exact" }))

-- Clipboard history
-- Needs: cliphist, wl-clipboard, fuzzel; daemon started in execs.lua
hl.bind(
	"SUPER + V",
	hl.dsp.exec_cmd("cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"),
	{ description = "Clipboard: history picker" }
)
hl.bind(
	"SUPER + SHIFT + V",
	hl.dsp.exec_cmd("cliphist wipe && notify-send -a Hyprland 'Clipboard' 'History wiped'"),
	{ description = "Clipboard: wipe history" }
)

-- Wallpaper cycler (also recolors astral-vagabond + hypr borders via wallust from live awww image)
hl.bind(
	"SUPER + W",
	hl.dsp.exec_cmd(
		string.format(
			"%s/wallpaper.sh --next", hyprScripts
		)
	),
	{ description = "Wallpaper: next + wallust theme (astral-vagabond + hypr borders)" }
)

-- Restore constant Ash palette for astral-vagabond + hypr borders (no wallpaper recolor)
hl.bind(
	"SUPER + SHIFT + W",
	hl.dsp.exec_cmd(
		"$HOME/.config/quickshell/astral-vagabond/utils/scripts/load-legacy-colors.sh --activate && notify-send -a Astral-Vagabond 'Theme' 'Ash colors restored (astral-vagabond + hypr)'"
	),
	{ description = "Theme: restore Ash colors (astral-vagabond + hypr)" }
)


-- Screenshots
local screenshot_dir = "$HOME/Pictures/Screenshots"
hl.bind(
	"Print",
	hl.dsp.exec_cmd("grim - | wl-copy && notify-send -a Hyprland 'Screenshot' 'Full screen → clipboard'"),
	{ description = "Screenshot: full -> clipboard" }
)
hl.bind(
	"SUPER + Print",
	hl.dsp.exec_cmd(
		"mkdir -p "
			.. screenshot_dir
			.. ' && grim "'
			.. screenshot_dir
			.. "/$(date +%Y-%m-%d_%H-%M-%S).png\" && notify-send -a Hyprland 'Screenshot' 'Full screen saved'"
	),
	{ description = "Screenshot: full → file" }
)
hl.bind(
	"SUPER + SHIFT + S",
	hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy && notify-send -a Hyprland 'Screenshot' 'Region → clipboard'"),
	{ description = "Screenshot: region → clipboard" }
)
hl.bind(
	"SUPER + SHIFT + Print",
	hl.dsp.exec_cmd(
		'grim -g "$(slurp)" - | satty -f - --copy-command wl-copy --output-filename "'
			.. screenshot_dir
			.. '/$(date +%Y-%m-%d_%H-%M-%S).png"'
	),
	{ description = "Screenshot: region → satty annotate" }
)

-- Screen recording
local record_dir = "$HOME/Videos/Recordings"
hl.bind(
	"SUPER + SHIFT + R",
	hl.dsp.exec_cmd(
		"mkdir -p "
			.. record_dir
			.. " && notify-send -a Hyprland 'Recording' 'Full screen started' && wf-recorder -a -f \""
			.. record_dir
			.. '/rec-$(date +%Y%m%d-%H%M%S).mp4"'
	),
	{ description = "Record: start full screen" }
)
hl.bind(
	"SUPER + ALT + R",
	hl.dsp.exec_cmd(
		"mkdir -p "
			.. record_dir
			.. " && notify-send -a Hyprland 'Recording' 'Region started' && wf-recorder -a -g \"$(slurp)\" -f \""
			.. record_dir
			.. '/rec-$(date +%Y%m%d-%H%M%S).mp4"'
	),
	{ description = "Record: start region" }
)
hl.bind(
	"SUPER + SHIFT + ALT + R",
	hl.dsp.exec_cmd("pkill -INT wf-recorder && notify-send -a Hyprland 'Recording' 'Stopped'"),
	{ description = "Record: stop" }
)
