set fish_greeting
set OH_MY_POSH "$HOME/.config/oh-my-posh"
set FASTFETCH "$HOME/.config/fastfetch"

# Ash monochrome (matches monoshell / kitty / ghostty)
set -g fish_color_normal e5e5e5
set -g fish_color_command c8c8c8
set -g fish_color_keyword c8c8c8 --bold
set -g fish_color_param a3a3a3
set -g fish_color_option a3a3a3
set -g fish_color_quote a3a3a3
set -g fish_color_redirection 8a8a8a
set -g fish_color_end 737373
set -g fish_color_error e8e8e8 --bold
set -g fish_color_comment 6b6b6b
set -g fish_color_operator c8c8c8
set -g fish_color_escape 8a8a8a
set -g fish_color_autosuggestion 454545
set -g fish_color_selection e5e5e5 --background=333333
set -g fish_color_search_match e5e5e5 --background=333333
set -g fish_color_cwd c8c8c8
set -g fish_color_cwd_root e8e8e8
set -g fish_color_user a3a3a3
set -g fish_color_host 8a8a8a
set -g fish_color_host_remote a3a3a3
set -g fish_color_status e8e8e8
set -g fish_color_cancel e8e8e8
set -g fish_color_valid_path --underline
set -g fish_color_history_current --bold
set -g fish_pager_color_progress c8c8c8
set -g fish_pager_color_prefix e5e5e5 --bold
set -g fish_pager_color_completion a3a3a3
set -g fish_pager_color_description 6b6b6b
set -g fish_pager_color_selected_background --background=242424
set -g fish_pager_color_selected_prefix e5e5e5 --bold
set -g fish_pager_color_selected_completion e5e5e5
set -g fish_pager_color_selected_description a3a3a3

if test -r "$FASTFETCH/config.jsonc"
    fastfetch
end

if test -r "$OH_MY_POSH/ash-info-util.omp.json"
    oh-my-posh init fish --config "$OH_MY_POSH/ash-info-util.omp.json" | source
end
