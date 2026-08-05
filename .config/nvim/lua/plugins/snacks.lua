-- IMPORTANT: this must be the FLATTENED (non-transparent) version of the
-- logo. The original ultra-nightmare-ascii.png is ~99% fully transparent
-- (only the thin red linework is opaque), so `chafa` — which treats
-- transparent pixels as "nothing to draw" — renders it as blank output.
-- Flatten it once onto the Doomshell void color (#121212) and use that
-- copy here instead.

local HEADER_TEXT = [[
  ██████╗  ██████╗  ██████╗ ███╗   ███╗██╗   ██╗██╗███╗   ███╗ 
  ██╔══██╗██╔═══██╗██╔═══██╗████╗ ████║██║   ██║██║████╗ ████║ 
  ██║  ██║██║   ██║██║   ██║██╔████╔██║██║   ██║██║██╔████╔██║ 
  ██║  ██║██║   ██║██║   ██║██║╚██╔╝██║╚██╗ ██╔╝██║██║╚██╔╝██║ 
  ██████╔╝╚██████╔╝╚██████╔╝██║ ╚═╝ ██║ ╚████╔╝ ██║██║ ╚═╝ ██║ 
  ╚═════╝  ╚═════╝  ╚═════╝ ╚═╝     ╚═╝  ╚═══╝  ╚═╝╚═╝     ╚═╝ ]]

return {
  "folke/snacks.nvim",
  -- IMPORTANT: this must be an `opts` FUNCTION (not a static table) and it
  -- must call `require("lazyvim.util").opts("snacks.nvim")` (or just build
  -- fresh opts) so we fully control `dashboard.sections` ourselves.
  -- LazyVim's own dashboard spec also sets `opts` as a function; if both
  -- specs use plain tables, the *last one merged* wins outright for the
  -- `sections` key instead of combining — which is why the logo wasn't
  -- showing before. Using a function here guarantees ours applies last
  -- and completely, since lazy.nvim always runs the higher-priority /
  -- later-declared spec's opts function last and lets it mutate the
  -- table lazy.nvim built from ancestors.
  opts = function(_, opts)
    opts.image = opts.image or {}
    opts.image.enabled = true
	opts.explorer = {
	  enabled = true,
	}
    opts.dashboard = opts.dashboard or {}
    opts.dashboard.enabled = true

    opts.dashboard.preset = opts.dashboard.preset or {}
    opts.dashboard.preset.header = HEADER_TEXT
    opts.dashboard.preset.keys = {
      { icon = " ", key = "f", desc = "Find File", action = ":lua LazyVim.pick()()" },
      { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
      { icon = " ", key = "g", desc = "Find Text", action = ':lua LazyVim.pick("live_grep")()' },
      { icon = " ", key = "r", desc = "Recent Files", action = ':lua LazyVim.pick("oldfiles")()' },
      { icon = " ", key = "c", desc = "Config", action = ":lua LazyVim.pick.config_files()()" },
      { icon = " ", key = "s", desc = "Restore Session", action = 'lua require("persistence").load()' },
      { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
      { icon = " ", key = "q", desc = "Quit", action = ":qa" },
    }

    -- Force our own sections, fully replacing whatever LazyVim's default
    -- dashboard extra set (that's what was rendering "LAZYVIM" ASCII text
    -- before instead of the PNG).
    opts.dashboard.sections = {
      { section = "header", padding = 1 },

      -- Renders ultra-nightmare-ascii.png via `chafa`. This is the
      -- officially-documented snacks.nvim approach for images on the
      -- dashboard (see snacks.nvim/docs/dashboard.md "chafa" example) and
      -- works in ANY terminal, no graphics protocol required.
      -- Requires `chafa` installed:
      --   macOS:  brew install chafa
      --   Debian: sudo apt install chafa
      --   Arch:   sudo pacman -S chafa
      { section = "keys", gap = 1, padding = 1 },
      { section = "startup" },
    }

    return opts
  end,
}
