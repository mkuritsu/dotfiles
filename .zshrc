HISTFILE=~/.histfile
HISTSIZE=100000
SAVEHIST=100000
unsetopt beep

export PATH="$HOME/.local/bin:$PATH"

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

alias ls='ls --color=auto'
alias code='code --enable-features=WaylandLinuxDrmSyncobj' # fuck nvidia

bindkey -s "^f" "~/.local/bin/tmux-sessionizer\n"
bindkey -s "^t" "tmux a || tmux\n"

eval "$(direnv hook zsh)"
eval "$(starship init zsh)"
