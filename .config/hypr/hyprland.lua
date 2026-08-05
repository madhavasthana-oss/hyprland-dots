-- This file sources other files in `hyprland` and `custom` folders
-- You wanna add your stuff in files in `custom`

-- Internal stuff --
require("hyprland.lib")
require("hyprland.services")

-- Environment variables --
require("hyprland.env")

-- Variables (apps + animationPreset) --
require("hyprland.variables")
if is_file_exists(HOME .. "/.config/hypr/custom/variables.lua") then
	require("custom.variables")
end

-- Default configurations --
require("hyprland.execs")
require("hyprland.general")
require("hyprland.animations") -- selectable pack (see animationPreset)
require("hyprland.rules")
require("hyprland.colors")
require("hyprland.keybinds")

-- nwg-displays support --
if is_file_exists(HOME .. "/.config/hypr/workspaces.lua") then
	require("workspaces")
end
if is_file_exists(HOME .. "/.config/hypr/monitors.lua") then
	require("monitors")
end

require("hyprcaffeine-keybinds")
