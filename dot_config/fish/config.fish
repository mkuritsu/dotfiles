function fish_greeting
end

function cd_fzf
    set dir $(find ~/ ~/Dev . -mindepth 1 -maxdepth 1 -type d -o -type l | fzf)
    if test -n "$dir"
        cd $dir
        commandline -f repaint
    end
end
bind ctrl-f cd_fzf

fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/.cache/.bun/bin"

# eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv fish)"

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


# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
