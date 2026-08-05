-- Selectable animation presets (converted from animations/*.conf)
-- Set animationPreset in hyprland/variables.lua (default: end4)

local presets = {
    ["LimeFrenzy"] = "hyprland.animations.lime_frenzy",
    ["lime_frenzy"] = "hyprland.animations.lime_frenzy",
    ["diablo-1"] = "hyprland.animations.diablo_1",
    ["diablo_1"] = "hyprland.animations.diablo_1",
    ["diablo-2"] = "hyprland.animations.diablo_2",
    ["diablo_2"] = "hyprland.animations.diablo_2",
    ["disable"] = "hyprland.animations.disable",
    ["dynamic"] = "hyprland.animations.dynamic",
    ["end4"] = "hyprland.animations.end4",
    ["fast"] = "hyprland.animations.fast",
    ["high"] = "hyprland.animations.high",
    ["ja"] = "hyprland.animations.ja",
    ["me-1"] = "hyprland.animations.me_1",
    ["me_1"] = "hyprland.animations.me_1",
    ["me-2"] = "hyprland.animations.me_2",
    ["me_2"] = "hyprland.animations.me_2",
    ["minimal-1"] = "hyprland.animations.minimal_1",
    ["minimal_1"] = "hyprland.animations.minimal_1",
    ["minimal-2"] = "hyprland.animations.minimal_2",
    ["minimal_2"] = "hyprland.animations.minimal_2",
    ["moving"] = "hyprland.animations.moving",
    ["optimized"] = "hyprland.animations.optimized",
    ["standard"] = "hyprland.animations.standard",
    ["theme"] = "hyprland.animations.theme",
    ["vertical"] = "hyprland.animations.vertical",
    ["classic"] = "hyprland.animations.classic",
    ["impulse"] = "hyprland.animations.impulse",
    ["doomslayer"] = "hyprland.animations.impulse",
}

local name = animationPreset or "end4"
local path = presets[name]
if not path and type(name) == "string" then
    path = presets[name:lower()]
end
if not path then
    path = presets["end4"] or presets["theme"]
end
if path then
    require(path)
end
