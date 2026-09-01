set fish_greeting

fish_add_path --global --path $HOME/.local/bin
fish_add_path --global --path $HOME/.cargo/bin

if test -x /opt/brew/bin/brew
    /opt/brew/bin/brew shellenv | source
end

set OH_MY_POSH "$HOME/.config/oh-my-posh"
set FASTFETCH "$HOME/.config/fastfetch"

# if test -r "$FASTFETCH/config.jsonc"
    # fastfetch
# end

# if test -r "$OH_MY_POSH"
#     oh-my-posh init fish --config "$OH_MY_POSH/smoothie.omp.json" | source
# end

starship init fish | source