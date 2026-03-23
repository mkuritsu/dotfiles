function fish_greeting
end

function cd_fzf
    set dir $(find ~/ ~/Dev . -mindepth 1 -maxdepth 1 -type d -o -type l | fzf)
    if test -n "$dir"
        cd $dir
        commandline -f repaint
    end
end

fish_add_path $HOME/.local/bin

if type -q zeditor
    alias zed=zeditor
end

bind ctrl-f cd_fzf

starship init fish | source

