# ═══════════════════════════════════════════════════════════
# Doomslayer CLI-HUD — zsh init (lives in the git repo)
# Clone Doomslayer-mod, keep one line in ~/.zshrc that sources this.
# ═══════════════════════════════════════════════════════════

# Always resolve mod root from this file's real path
_this="${(%):-%x}"
[[ -n "$_this" && -e "$_this" ]] || _this="$HOME/Doomslayer-mod/config/CLI-HUD/zsh/init.zsh"
_this="${_this:A}"
_DS_ZSH_DIR="${_this:h}"
# .../Doomslayer-mod/config/CLI-HUD/zsh → up 3 = Doomslayer-mod
export DOOMSLAYER_MOD="${_DS_ZSH_DIR:h:h:h}"
if [[ ! -d "$DOOMSLAYER_MOD/config/CLI-HUD" ]]; then
  export DOOMSLAYER_MOD="$HOME/Doomslayer-mod"
  _DS_ZSH_DIR="$DOOMSLAYER_MOD/config/CLI-HUD/zsh"
fi

# ── Prompt ──
[[ -r "$_DS_ZSH_DIR/prompt.zsh" ]] && source "$_DS_ZSH_DIR/prompt.zsh"

# ── Optional tools ──
command -v direnv >/dev/null && eval "$(direnv hook zsh)"
command -v zoxide >/dev/null && eval "$(zoxide init zsh --cmd cd)"

if command -v eza >/dev/null; then
  alias ls='eza --icons --group-directories-first -1'
  alias l='ls'
  alias ll='ls -l'
  alias la='ls -a'
  alias lla='ls -la'
  alias lt='ls --tree'
fi

alias lg='lazygit'
alias gd='git diff'
alias ga='git add .'
alias gc='git commit -am'
alias gl='git log'
alias gs='git status'
alias gst='git stash'
alias gsp='git stash pop'
alias gp='git push'
alias gpl='git pull'
alias gsw='git switch'
alias gsm='git switch main'
alias gb='git branch'
alias gbd='git branch -d'
alias gco='git checkout'
alias gsh='git show'

# Fastfetch: use MOD config path only (does not own ~/.config/fastfetch)
_FF_CFG="$DOOMSLAYER_MOD/config/fastfetch/config.jsonc"
alias doomfetch="fastfetch --config ${_FF_CFG}"

if [[ -o interactive && -t 1 ]] && command -v fastfetch >/dev/null; then
  if [[ -z "$FASTFETCH_SHOWN" && -z "$VSCODE_INJECTION" && "$TERM_PROGRAM" != "vscode" ]]; then
    export FASTFETCH_SHOWN=1
    [[ -r "$_FF_CFG" ]] && fastfetch --config "$_FF_CFG"
  fi
fi
