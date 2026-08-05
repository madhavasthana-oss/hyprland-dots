# Hyprland animation presets (Lua only)

These are the **only** animation packs Hypr loads.

Select in `hyprland/variables.lua`:

```lua
animationPreset = "end4"
```

Then: `hyprctl reload`

Old HyDE `animations/*.conf` + `animations.conf` were removed — they were not sourced by the Lua config.
