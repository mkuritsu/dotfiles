HISTFILE=~/.histfile
HISTSIZE=100000
SAVEHIST=100000
unsetopt beep

export PATH="$HOME/.local/bin:$PATH"

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

alias ls='ls --color=auto'
alias code='code --enable-features=WaylandLinuxDrmSyncobj' # fuck nvidia

bindkey "^[[1;3C" forward-word
bindkey "^[[1;3D" backward-word
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word
bindkey  "^[[H"   beginning-of-line
bindkey  "^[[F"   end-of-line
bindkey  "^[[3~"  delete-char

bindkey -s "^f" "~/.local/bin/tmux-sessionizer\n"
bindkey -s "^t" "tmux a || tmux\n"

eval "$(direnv hook zsh)"
eval "$(starship init zsh)"
