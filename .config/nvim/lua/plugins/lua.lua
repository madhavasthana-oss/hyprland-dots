-- Lua LSP for Neovim config + Hyprland Lua config (hl API).
--
-- LazyVim already wires nvim-lspconfig + lua_ls + lazydev.
-- Do NOT call require("lspconfig") at the top level of this file —
-- that runs before the plugin is on the runtime path and fails with
-- "could not load lspconfig" / module not found.
--
-- Configure servers only via the LazyVim `opts` merge pattern below.

return {
  -- Hyprland traditional .conf syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "lua", "hyprlang" },
    },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        lua_ls = {
          -- Prefer the system/mason binary already present; no extra work needed.
          settings = {
            Lua = {
              runtime = {
                version = "LuaJIT",
                -- So `require("hyprland.*")` resolves when editing under ~/.config/hypr
                path = {
                  "?.lua",
                  "?/init.lua",
                  vim.fn.expand("~/.config/hypr/?.lua"),
                  vim.fn.expand("~/.config/hypr/?/init.lua"),
                },
              },

              diagnostics = {
                -- Injected by Neovim / Hyprland's Lua config runtime
                globals = {
                  "vim",
                  "hl", -- Hyprland Lua API (hl.bind, hl.config, hl.env, ...)
                  "HOME",
                  "workspaceGroupSize",
                  "is_file_exists",
                  "create_if_not_exists",
                  "workspace_in_group",
                },
              },

              workspace = {
                checkThirdParty = false,
                -- Do NOT set library = { vim.env.VIMRUNTIME } alone —
                -- that overrides lazydev and breaks nvim-config completion.
              },

              telemetry = {
                enable = false,
              },
            },
          },
        },
      },
    },
  },

  -- Mark Hyprland/QuickShell-ish .conf files as hyprlang for treesitter
  {
    "LazyVim/LazyVim",
    init = function()
      vim.filetype.add({
        pattern = {
          [".*/hypr/.*%.conf"] = "hyprlang",
          [".*/hyprland%.conf"] = "hyprlang",
          [".*/hyprlock%.conf"] = "hyprlang",
          [".*/hypridle%.conf"] = "hyprlang",
          [".*/hyprpaper%.conf"] = "hyprlang",
        },
      })
    end,
  },
}
