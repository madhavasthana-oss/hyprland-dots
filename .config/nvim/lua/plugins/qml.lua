return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        qmlls = {
          mason = false, -- installed via pacman
          cmd = { "qmlls" },
          filetypes = { "qml", "qmljs" },
          root_markers = { ".git", "qmldir", ".qmlls.ini" },
        },
      },
    },
  },
}
