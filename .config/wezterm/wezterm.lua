-- WezTerm config (Monoshell / Ash monochrome)
-- Hyprland: native Wayland is broken on wezterm 20240203 → force XWayland.

local wezterm = require("wezterm")
local config = wezterm.config_builder()

--------------------------------------------------------------------------
-- Platform / launch
--------------------------------------------------------------------------
config.enable_wayland = false
config.enable_kitty_graphics = true
-- config.default_prog = { "/usr/bin/env zsh" }

--------------------------------------------------------------------------
-- Font + ligatures / OpenType features
-- CaskaydiaCove = Cascadia Code Nerd Font (same as Kitty / Ghostty)
-- calt/liga/clig  = programming ligatures (=>, !=, ===, ->, ...)
-- ss01..ss20      = stylistic sets (font-dependent; safe to request)
-- zero            = slashed zero when the font has it
--------------------------------------------------------------------------
config.font = wezterm.font_with_fallback({
	{
		family = "Fira Code",
		weight = "Regular",
		harfbuzz_features = {
			"calt=1",
			"clig=1",
			"liga=1",
			"zero=1",
			"ss01=1",
			"ss02=1",
			"ss03=1",
			"ss04=1",
			"ss05=1",
			"ss06=1",
			"ss07=1",
			"ss08=1",
			"ss09=1",
			"ss10=1",
			"ss19=1",
			"ss20=1",
		},
	},
	"CaskaydiaCove Nerd Font",
	"JetBrains Mono",
	"Symbols Nerd Font Mono",
})
config.font_size = 12
config.line_height = 1.0
config.cell_width = 1.0
config.freetype_load_target = "Normal"
config.freetype_render_target = "Normal"
config.allow_square_glyphs_to_overflow_width = "WhenFollowedBySpace"
config.warn_about_missing_glyphs = false

-- Bold / italic variants keep the same ligature features
config.font_rules = {
	{
		intensity = "Bold",
		font = wezterm.font({
			family = "Fira Code",
			weight = "Bold",
			harfbuzz_features = {
				"calt=1",
				"clig=1",
				"liga=1",
				"zero=1",
			},
		}),
	},
	{
		italic = true,
		font = wezterm.font({
			family = "CaskaydiaCove Nerd Font Mono",
			style = "Italic",
			harfbuzz_features = {
				"calt=1",
				"clig=1",
				"liga=1",
				"zero=1",
			},
		}),
	},
	{
		intensity = "Bold",
		italic = true,
		font = wezterm.font({
			family = "CaskaydiaCove Nerd Font Mono",
			weight = "Bold",
			style = "Italic",
			harfbuzz_features = {
				"calt=1",
				"clig=1",
				"liga=1",
				"zero=1",
			},
		}),
	},
}

--------------------------------------------------------------------------
-- Window / chrome
--------------------------------------------------------------------------
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = true
config.window_decorations = "TITLE | RESIZE"
config.window_padding = {
	left = 25,
	right = 25,
	top = 25,
	bottom = 25,
}
config.window_frame = {
	font = wezterm.font({
		family = "CaskaydiaCove Nerd Font Mono",
		weight = "Regular",
	}),
	font_size = 9,
}

--------------------------------------------------------------------------
-- Terminal opacity
-- No background image anymore, so this is just a plain, flat opaque
-- terminal. Set to 1.0 = fully opaque. Lower it if you want a plain
-- (imageless) glass/transparency effect via WezTerm itself; just be
-- aware your Hyprland decoration:active_opacity / inactive_opacity
-- settings (confirmed present on this machine at 0.95 / 0.90) apply
-- on top of whatever you set here, since that's compositor-level and
-- outside WezTerm's control.
--------------------------------------------------------------------------
config.window_background_opacity = 0.7
config.text_background_opacity = 0.7

--------------------------------------------------------------------------
-- Colors — load Ghostty / Kitty theme (Ash monochrome)
-- Prefer Kitty theme.conf (shared source); fall back to Ghostty theme.conf.
-- Hardcoded palette matches both when theme files are missing.
--------------------------------------------------------------------------
local function expand_home(path)
	if path:sub(1, 2) == "~/" then
		return (os.getenv("HOME") or "") .. path:sub(2)
	end
	return path
end

-- Kitty:  key #hex   |  Ghostty:  key = #hex  /  palette = N=#hex
local function load_terminal_theme(path)
	path = expand_home(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end

	local colors = {
		ansi = {},
		brights = {},
	}
	local palette = {}

	for line in f:lines() do
		line = line:match("^%s*(.-)%s*$") or ""
		if line ~= "" and not line:match("^#") then
			-- Ghostty: palette = N=#RRGGBB
			local idx, hex = line:match("^palette%s*=%s*(%d+)%s*=%s*(#%x+)")
			if idx and hex then
				palette[tonumber(idx)] = hex
			else
				-- Ghostty: key = #hex  |  Kitty: key #hex  |  Kitty: colorN #hex
				local key, val = line:match("^([%w_-]+)%s*=%s*(#%x+)")
				if not key then
					key, val = line:match("^([%w_]+)%s+(#%x+)")
				end
				if key and val then
					key = key:lower():gsub("-", "_")
					if key == "foreground" then
						colors.foreground = val
					elseif key == "background" then
						colors.background = val
					elseif key == "cursor" or key == "cursor_color" then
						colors.cursor_bg = val
						colors.cursor_border = val
					elseif key == "cursor_text" or key == "cursor_text_color" then
						colors.cursor_fg = val
					elseif key == "selection_foreground" then
						colors.selection_fg = val
					elseif key == "selection_background" then
						colors.selection_bg = val
					elseif key:match("^color%d+$") then
						local n = tonumber(key:match("%d+"))
						palette[n] = val
					end
				end
			end
		end
	end
	f:close()

	for i = 0, 7 do
		colors.ansi[i + 1] = palette[i]
	end
	for i = 8, 15 do
		colors.brights[i - 7] = palette[i]
	end

	-- Require a full 16-color palette
	if not colors.foreground or not colors.background or not colors.ansi[1] or not colors.brights[8] then
		return nil
	end
	return colors
end

local theme_paths = {
	"~/hyprland-dots/.config/kitty/theme.conf",
	"~/.config/kitty/theme.conf",
	"~/hyprland-dots/.config/ghostty/theme.conf",
	"~/.config/ghostty/theme.conf",
}

local colors = nil
for _, p in ipairs(theme_paths) do
	colors = load_terminal_theme(p)
	if colors then
		break
	end
end

-- Fallback: Ash monochrome (matches Kitty/Ghostty theme.conf)
if not colors then
	colors = {
		foreground = "#E5E5E5",
		background = "#121212",
		cursor_bg = "#C8C8C8",
		cursor_fg = "#121212",
		cursor_border = "#C8C8C8",
		selection_fg = "#E5E5E5",
		selection_bg = "#333333",
		ansi = {
			"#1A1A1A",
			"#8A8A8A",
			"#737373",
			"#A3A3A3",
			"#C8C8C8",
			"#A3A3A3",
			"#8A8A8A",
			"#E5E5E5",
		},
		brights = {
			"#454545",
			"#E8E8E8",
			"#A3A3A3",
			"#C8C8C8",
			"#E5E5E5",
			"#C8C8C8",
			"#B8B8B8",
			"#F0F0F0",
		},
	}
end

-- Defaults for optional fields if a theme file omits them
colors.cursor_bg = colors.cursor_bg or colors.foreground
colors.cursor_fg = colors.cursor_fg or colors.background
colors.cursor_border = colors.cursor_border or colors.cursor_bg
colors.selection_fg = colors.selection_fg or colors.foreground
colors.selection_bg = colors.selection_bg or colors.ansi[2]

-- Tab bar derived from the same palette (no leftover blue chrome)
colors.tab_bar = {
	background = colors.background,
	active_tab = {
		bg_color = colors.brights[2] or "#FF0033", -- bright red
		fg_color = colors.background,
	},
	inactive_tab = {
		bg_color = colors.ansi[1] or "#000000",
		fg_color = colors.foreground,
	},
	inactive_tab_hover = {
		bg_color = colors.selection_bg,
		fg_color = colors.selection_fg,
	},
	new_tab = {
		bg_color = colors.ansi[1] or "#000000",
		fg_color = colors.brights[2] or colors.foreground,
	},
	new_tab_hover = {
		bg_color = colors.selection_bg,
		fg_color = colors.selection_fg,
	},
}

config.colors = colors

--------------------------------------------------------------------------
-- Cursor / term / performance
--------------------------------------------------------------------------
config.default_cursor_style = "BlinkingBlock"
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"
config.term = "xterm-256color"
config.bold_brightens_ansi_colors = false
config.max_fps = 120
config.animation_fps = 60
config.front_end = "OpenGL"
config.webgpu_power_preference = "HighPerformance"

-- Unicode / emoji / undercurl
config.unicode_version = 14
config.custom_block_glyphs = true
config.underline_thickness = "200%"
config.underline_position = "-2pt"

--------------------------------------------------------------------------
-- Keys (ALT for tabs & splits)
--------------------------------------------------------------------------
config.keys = {
	-- Tabs
	{ key = "t", mods = "ALT", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
	{ key = "w", mods = "ALT", action = wezterm.action.CloseCurrentTab({ confirm = false }) },
	{ key = "n", mods = "ALT", action = wezterm.action.ActivateTabRelative(1) },
	{ key = "p", mods = "ALT", action = wezterm.action.ActivateTabRelative(-1) },

	-- Panes
	{ key = "v", mods = "ALT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "h", mods = "ALT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "q", mods = "ALT", action = wezterm.action.CloseCurrentPane({ confirm = false }) },

	-- Pane navigation
	{ key = "LeftArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Left") },
	{ key = "RightArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Right") },
	{ key = "UpArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Up") },
	{ key = "DownArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Down") },

	-- Clipboard (explicit)
	{ key = "c", mods = "CTRL|SHIFT", action = wezterm.action.CopyTo("Clipboard") },
	{ key = "v", mods = "CTRL|SHIFT", action = wezterm.action.PasteFrom("Clipboard") },

	-- Font size
	{ key = "=", mods = "CTRL", action = wezterm.action.IncreaseFontSize },
	{ key = "-", mods = "CTRL", action = wezterm.action.DecreaseFontSize },
	{ key = "0", mods = "CTRL", action = wezterm.action.ResetFontSize },

	-- Fullscreen
	{ key = "Enter", mods = "ALT", action = wezterm.action.ToggleFullScreen },
}

--------------------------------------------------------------------------
-- Scrollback / misc
--------------------------------------------------------------------------
config.scrollback_lines = 10000
config.enable_scroll_bar = false
config.audible_bell = "Disabled"
config.check_for_updates = false

return config
