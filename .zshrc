unsetopt beep
setopt prompt_subst

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

function git_branch_name()
{
    branch=$(git symbolic-ref HEAD 2> /dev/null | awk 'BEGIN{FS="/"} {print $NF}')
    if [[ $branch == "" ]];
    then
    :
    else
        echo ' (%F{yellow}'$branch'%F{magenta})'
    fi
}

alias ls='ls --color=auto'
alias vscode='code --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform-hint=auto'

bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

prompt='%F{magenta}%n - [%f%~%F{magenta}]$(git_branch_name) > '
