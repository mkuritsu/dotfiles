status is-interactive; and begin
    if test "$TERM" != dum
        starship init fish | source
    end
end

fish_add_path $HOME/.local/bin/
