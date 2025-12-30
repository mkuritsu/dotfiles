status is-interactive; and begin
    if type -q direnv
        direnv hook fish | source
    end
    if type -q starship
        starship init fish | source
    end
end

fish_add_path $HOME/.local/bin/

set -gx SHELL "fish"
set -gx GPG_TTY "$(tty)"
