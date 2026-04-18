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

starship init fish | source
zoxide init fish | source

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv fish)"

set -x EDITOR $(which nvim)

if type -q zeditor
    alias zed="zeditor"
end

if type -q eza
    alias ls="eza"
end

alias cd="z"
alias oc="opencode"

