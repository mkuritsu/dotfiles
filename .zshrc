HISTFILE=~/.histfile
HISTSIZE=100000
SAVEHIST=100000
unsetopt beep

alias ls='ls --color=auto'
alias code='code --enable-features=WaylandLinuxDrmSyncobj' # fuck nvidia

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

bindkey -s "^f" "~/.local/bin/tmux-sessionizer\n"
bindkey -s "^t" "tmux a || tmux\n"

# oh-my-zsh setup
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)
source $ZSH/oh-my-zsh.sh

eval "$(direnv hook zsh)"
