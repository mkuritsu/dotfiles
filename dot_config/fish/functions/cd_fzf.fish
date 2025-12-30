function cd_fzf
    set dir $(find ~/ ~/Dev . -mindepth 1 -maxdepth 1 \( -type d -o -type l \) | fzf)
    if test -n "$dir"
        cd $dir
        commandline -f repaint
    end
end

