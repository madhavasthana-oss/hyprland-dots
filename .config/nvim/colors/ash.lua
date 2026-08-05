-- =========================================================
--  ASH — Neovim colorscheme
--  Ported 1:1 from theme.qml (Ash adventure palette)
--  Fire red / ember orange on a near-black void, acid-green
--  reserved strictly for "safe" / success states.
-- =========================================================

vim.cmd("hi clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end

vim.o.termguicolors = true
vim.g.colors_name = "ash"

-- ---------------------------------------------------------
-- Palette (straight from theme.qml)
-- ---------------------------------------------------------
local p = {
  bg_primary   = "#121212",
  bg_surface   = "#1A1A1A",
  bg_elevated  = "#242424",
  bg_console   = "#161616",

  accent       = "#C8C8C8", -- silver
  accent_warm  = "#A3A3A3", -- soft
  accent_soft  = "#737373", -- muted

  text_primary   = "#C8C8C8",
  text_secondary = "#A3A3A3",
  text_muted     = "#6B6B6B",
  text_dim       = "#454545",

  state_critical = "#6B6B6B",
  state_safe     = "#8A8A8A",
  state_warning  = "#A3A3A3",

  border_active  = "#C8C8C8",
  border_idle    = "#6B6B6B",
  border_console = "#6B6B6B",
  glow_console   = "#555555",

  white = "#E5E5E5",
  black = "#000000",
}

local function hi(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- ---------------------------------------------------------
-- Editor UI
-- ---------------------------------------------------------
hi("Normal",       { fg = p.white,          bg = p.bg_primary })
hi("NormalFloat",  { fg = p.white,          bg = p.bg_console })
hi("NormalNC",     { fg = p.white,          bg = p.bg_primary })
hi("FloatBorder",  { fg = p.border_console, bg = p.bg_console })
hi("FloatTitle",   { fg = p.accent_warm,    bg = p.bg_console, bold = true })

hi("Cursor",       { fg = p.bg_primary, bg = p.accent })
hi("CursorLine",   { bg = p.bg_surface })
hi("CursorLineNr", { fg = p.accent, bold = true })
hi("LineNr",       { fg = p.text_dim })
hi("SignColumn",   { bg = p.bg_primary })
hi("ColorColumn",  { bg = p.bg_elevated })

hi("VertSplit",    { fg = p.border_idle, bg = p.bg_primary })
hi("WinSeparator", { fg = p.border_idle, bg = p.bg_primary })

hi("Visual",       { bg = p.bg_elevated })
hi("VisualNOS",    { bg = p.bg_elevated })

hi("Search",       { fg = p.bg_primary, bg = p.accent_warm })
hi("IncSearch",    { fg = p.bg_primary, bg = p.accent })
hi("CurSearch",    { fg = p.bg_primary, bg = p.accent })

hi("Pmenu",        { fg = p.text_secondary, bg = p.bg_console })
hi("PmenuSel",      { fg = p.bg_primary, bg = p.accent, bold = true })
hi("PmenuSbar",    { bg = p.bg_elevated })
hi("PmenuThumb",   { bg = p.accent })

hi("StatusLine",   { fg = p.text_primary, bg = p.bg_surface })
hi("StatusLineNC", { fg = p.text_dim,     bg = p.bg_surface })
hi("TabLine",      { fg = p.text_muted,   bg = p.bg_surface })
hi("TabLineSel",   { fg = p.accent_warm,  bg = p.bg_elevated, bold = true })
hi("TabLineFill",  { bg = p.bg_primary })

hi("Directory",    { fg = p.accent_soft })
hi("Title",        { fg = p.accent_warm, bold = true })

hi("MatchParen",   { fg = p.accent_warm, bold = true, underline = true })

hi("NonText",      { fg = p.text_dim })
hi("Whitespace",   { fg = p.text_dim })
hi("EndOfBuffer",  { fg = p.bg_primary })
hi("Folded",       { fg = p.text_muted, bg = p.bg_elevated })
hi("FoldColumn",   { fg = p.text_dim,  bg = p.bg_primary })

-- ---------------------------------------------------------
-- Diagnostics / state colors
-- ---------------------------------------------------------
hi("DiagnosticError", { fg = p.state_critical })
hi("DiagnosticWarn",  { fg = p.state_warning })
hi("DiagnosticInfo",  { fg = p.accent_soft })
hi("DiagnosticHint",  { fg = p.text_muted })
hi("DiagnosticOk",    { fg = p.state_safe })

hi("DiagnosticUnderlineError", { undercurl = true, sp = p.state_critical })
hi("DiagnosticUnderlineWarn",  { undercurl = true, sp = p.state_warning })
hi("DiagnosticUnderlineInfo",  { undercurl = true, sp = p.accent_soft })
hi("DiagnosticUnderlineHint",  { undercurl = true, sp = p.text_muted })

hi("Error",   { fg = p.state_critical, bold = true })
hi("WarningMsg", { fg = p.state_warning })
hi("ErrorMsg",   { fg = p.state_critical, bold = true })
hi("ModeMsg",    { fg = p.accent_warm })
hi("MoreMsg",    { fg = p.state_safe })
hi("Question",   { fg = p.accent_warm })

-- ---------------------------------------------------------
-- Syntax
-- ---------------------------------------------------------
hi("Comment",     { fg = p.accent_soft, italic = true })

hi("Constant",    { fg = p.accent_soft })
hi("String",      { fg = p.state_safe })
hi("Character",   { fg = p.state_safe })
hi("Number",      { fg = p.accent_warm })
hi("Boolean",     { fg = p.accent_warm, bold = true })
hi("Float",       { fg = p.accent_warm })

hi("Identifier",  { fg = p.text_secondary })
hi("Function",    { fg = p.accent, bold = true })

hi("Statement",   { fg = p.accent })
hi("Conditional", { fg = p.accent })
hi("Repeat",      { fg = p.accent })
hi("Label",       { fg = p.accent_warm })
hi("Operator",    { fg = p.text_secondary })
hi("Keyword",     { fg = p.accent, bold = true })
hi("Exception",   { fg = p.state_critical })

hi("PreProc",     { fg = p.accent_soft })
hi("Include",     { fg = p.accent_soft })
hi("Define",      { fg = p.accent_soft })
hi("Macro",       { fg = p.accent_soft })

hi("Type",        { fg = p.text_secondary, bold = true })
hi("StorageClass", { fg = p.accent })
hi("Structure",   { fg = p.text_secondary })
hi("Typedef",     { fg = p.text_secondary })

hi("Special",     { fg = p.accent_warm })
hi("SpecialChar", { fg = p.accent_warm })
hi("Tag",         { fg = p.accent })
hi("Delimiter",   { fg = p.text_muted })
hi("SpecialComment", { fg = p.text_muted, italic = true })
hi("Underlined",  { fg = p.accent_soft, underline = true })

hi("Ignore",      { fg = p.text_dim })
hi("Todo",        { fg = p.bg_primary, bg = p.accent_warm, bold = true })

-- ---------------------------------------------------------
-- Treesitter (modern captures)
-- ---------------------------------------------------------
hi("@variable",           { fg = p.text_secondary })
hi("@variable.builtin",   { fg = p.accent, italic = true })
hi("@variable.parameter", { fg = p.text_secondary })
hi("@variable.member",    { fg = p.accent_soft })

hi("@constant",           { fg = p.accent_soft })
hi("@constant.builtin",   { fg = p.accent_warm, bold = true })

hi("@string",             { fg = p.state_safe })
hi("@string.escape",      { fg = p.accent_warm })

hi("@function",           { fg = p.accent, bold = true })
hi("@function.builtin",   { fg = p.accent, italic = true })
hi("@function.call",      { fg = p.accent })
hi("@method",             { fg = p.accent })
hi("@method.call",        { fg = p.accent })
hi("@constructor",        { fg = p.text_secondary })

hi("@keyword",            { fg = p.accent, bold = true })
hi("@keyword.function",   { fg = p.accent, bold = true })
hi("@keyword.return",     { fg = p.accent, bold = true })
hi("@keyword.operator",   { fg = p.text_secondary })
hi("@conditional",        { fg = p.accent })
hi("@repeat",             { fg = p.accent })

hi("@type",               { fg = p.text_secondary, bold = true })
hi("@type.builtin",       { fg = p.text_secondary, italic = true })
hi("@attribute",          { fg = p.accent_soft })
hi("@namespace",          { fg = p.text_secondary })

hi("@tag",                { fg = p.accent })
hi("@tag.attribute",      { fg = p.accent_soft })
hi("@tag.delimiter",      { fg = p.text_muted })

hi("@punctuation.bracket",  { fg = p.text_muted })
hi("@punctuation.delimiter", { fg = p.text_muted })
hi("@punctuation.special",   { fg = p.accent_warm })

hi("@comment",            { fg = p.accent_soft, italic = true })
hi("@comment.todo",       { fg = p.bg_primary, bg = p.accent_warm, bold = true })
hi("@comment.warning",    { fg = p.bg_primary, bg = p.state_warning, bold = true })
hi("@comment.error",      { fg = p.white, bg = p.state_critical, bold = true })

hi("@markup.heading",     { fg = p.accent_warm, bold = true })
hi("@markup.link",        { fg = p.accent_soft, underline = true })
hi("@markup.raw",         { fg = p.state_safe })

-- ---------------------------------------------------------
-- LSP semantic tokens
-- ---------------------------------------------------------
hi("@lsp.type.class",     { link = "Type" })
hi("@lsp.type.interface", { link = "Type" })
hi("@lsp.type.enum",      { link = "Type" })
hi("@lsp.type.parameter", { link = "@variable.parameter" })
hi("@lsp.type.property",  { link = "@variable.member" })

-- ---------------------------------------------------------
-- Diffs / Git
-- ---------------------------------------------------------
hi("DiffAdd",    { fg = p.state_safe,     bg = p.bg_elevated })
hi("DiffChange", { fg = p.state_warning,  bg = p.bg_elevated })
hi("DiffDelete", { fg = p.state_critical, bg = p.bg_elevated })
hi("DiffText",   { fg = p.accent_warm,    bg = p.bg_elevated, bold = true })

hi("GitSignsAdd",    { fg = p.state_safe })
hi("GitSignsChange", { fg = p.state_warning })
hi("GitSignsDelete", { fg = p.state_critical })

-- ---------------------------------------------------------
-- Telescope / Snacks picker (best-effort common groups)
-- ---------------------------------------------------------
hi("TelescopeNormal",       { fg = p.text_secondary, bg = p.bg_console })
hi("TelescopeBorder",       { fg = p.border_console, bg = p.bg_console })
hi("TelescopeSelection",    { fg = p.accent_warm, bg = p.bg_elevated, bold = true })
hi("TelescopePromptBorder", { fg = p.border_active, bg = p.bg_console })
hi("TelescopeTitle",        { fg = p.accent, bold = true })
hi("TelescopeMatching",     { fg = p.accent, bold = true })

hi("SnacksDashboardHeader", { fg = p.accent, bold = true })
hi("SnacksDashboardDesc",   { fg = p.text_secondary })
hi("SnacksDashboardIcon",   { fg = p.accent_warm })
hi("SnacksDashboardKey",    { fg = p.accent, bold = true })
hi("SnacksDashboardFooter", { fg = p.text_dim, italic = true })
hi("SnacksDashboardTitle",  { fg = p.accent_warm, bold = true })

-- Snacks picker (Files/Grep/etc list UI) — the dimmed path segment
-- before the filename ("Doomslayer-mod/config/.../") uses the "Dir"
-- groups below; kept in rose to match Comment/Directory.
hi("SnacksPickerDir",       { fg = p.accent_soft })
hi("SnacksPickerDirectory", { fg = p.accent_soft })
hi("SnacksPickerPathHidden",{ fg = p.accent_soft })
hi("SnacksPickerFile",      { fg = p.text_secondary })
hi("SnacksPickerTitle",     { fg = p.accent, bold = true })
hi("SnacksPickerBorder",    { fg = p.border_console, bg = p.bg_console })
hi("SnacksPickerNormal",    { fg = p.text_secondary, bg = p.bg_console })
hi("SnacksPickerMatch",     { fg = p.accent_warm, bold = true })
hi("SnacksPickerSelected",  { fg = p.accent_warm, bg = p.bg_elevated, bold = true })
hi("SnacksPickerCursorLine",{ bg = p.bg_elevated })
hi("SnacksPickerPrompt",    { fg = p.accent })
hi("SnacksPickerCount",     { fg = p.text_dim })

-- ---------------------------------------------------------
-- Bufferline (if used)
-- ---------------------------------------------------------
hi("BufferLineFill",             { bg = p.bg_primary })
hi("BufferLineBackground",       { fg = p.text_dim, bg = p.bg_surface })
hi("BufferLineBufferSelected",   { fg = p.accent_warm, bg = p.bg_elevated, bold = true })
hi("BufferLineIndicatorSelected",{ fg = p.accent, bg = p.bg_elevated })

-- ---------------------------------------------------------
-- Terminal colors (used by :terminal + image/chafa rendering)
-- ---------------------------------------------------------
vim.g.terminal_color_0  = p.bg_primary
vim.g.terminal_color_1  = p.state_critical
vim.g.terminal_color_2  = p.state_safe
vim.g.terminal_color_3  = p.state_warning
vim.g.terminal_color_4  = p.accent_soft
vim.g.terminal_color_5  = p.accent_soft
vim.g.terminal_color_6  = p.accent_warm
vim.g.terminal_color_7  = p.white
vim.g.terminal_color_8  = p.text_dim
vim.g.terminal_color_9  = p.accent
vim.g.terminal_color_10 = p.state_safe
vim.g.terminal_color_11 = p.accent_warm
vim.g.terminal_color_12 = p.accent_soft
vim.g.terminal_color_13 = p.accent_soft
vim.g.terminal_color_14 = p.accent_warm
vim.g.terminal_color_15 = p.white
