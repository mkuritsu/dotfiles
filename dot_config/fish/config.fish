function fish_greeting
end

function cd_fzf
    set lookup_dirs ~/ .
    if test -d ~/Dev
        set lookup_dirs $lookup_dirs ~/Dev
    end
    if test -d ~/Projects
        set lookup_dirs $lookup_dirs ~/Projects/
    end
    set dir $(find $lookup_dirs -mindepth 1 -maxdepth 1 -type d -o -type l | fzf)
    if test -n "$dir"
        cd $dir
        commandline -f repaint
    end
end
bind ctrl-f cd_fzf

fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/.cache/.bun/bin"
fish_add_path "$HOME/.bun/bin"

if type -q starship
    starship init fish | source
end

if type -q zoxide
    zoxide init fish | source
    alias cd="z"
end

if type -q zeditor
    alias zed="zeditor"
end

if type -q eza
    alias ls="eza"
end

alias oc="opencode"

set -x EDITOR $(which nvim)
set -x GOPATH "$HOME/.go"
set --export BUN_INSTALL "$HOME/.bun"

source "$HOME/.vite-plus/env.fish"
