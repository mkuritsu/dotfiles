##############
# OPTIONS
##############
mkdir -p "$HOME/.local/state/zsh" "$HOME/.cache/zsh"
HISTFILE="$HOME/.local/state/zsh/history"
HISTSIZE=100000
SAVEHIST=100000
setopt share_history hist_ignore_all_dups hist_ignore_space hist_reduce_blanks
setopt auto_cd interactive_comments no_beep

autoload -Uz compinit
compinit -d "$HOME/.cache/zsh/zcompdump"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

##############
# KEYBINDINGS
##############
bindkey -e

# stop word motions at "/" like fish does
WORDCHARS=${WORDCHARS//\/}

# up/down search history by the typed prefix, like fish
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search edit-command-line
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
zle -N edit-command-line

# both normal (CSI) and application (SS3) mode sequences
bindkey '^[[A'    up-line-or-beginning-search   # up
bindkey '^[OA'    up-line-or-beginning-search
bindkey '^[[B'    down-line-or-beginning-search # down
bindkey '^[OB'    down-line-or-beginning-search
bindkey '^[[H'    beginning-of-line             # home
bindkey '^[OH'    beginning-of-line
bindkey '^[[1~'   beginning-of-line
bindkey '^[[F'    end-of-line                   # end
bindkey '^[OF'    end-of-line
bindkey '^[[4~'   end-of-line
bindkey '^[[3~'   delete-char                   # delete
bindkey '^[[1;5D' backward-word                 # ctrl+left
bindkey '^[[1;5C' forward-word                  # ctrl+right
bindkey '^[[1;3D' backward-word                 # alt+left
bindkey '^[[1;3C' forward-word                  # alt+right
bindkey '^H'      backward-kill-word            # ctrl+backspace
bindkey '^[^?'    backward-kill-word            # alt+backspace
bindkey '^[[3;5~' kill-word                     # ctrl+delete
bindkey '^[[3;3~' kill-word                     # alt+delete
bindkey '^[[Z'    reverse-menu-complete         # shift+tab
bindkey '^[e'     edit-command-line             # alt+e, edit in $EDITOR

##############
# FUNCTIONS
##############
# Paths of all worktrees of the current repo, main checkout first
__git_worktrees() {
    git worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p'
}

# Path of the worktree that has branch $1 checked out, if any
__git_branch_worktree() {
    local branch=$1 wt line
    while IFS= read -r line; do
        case $line in
            "worktree "*) wt=${line#worktree } ;;
            "branch refs/heads/$branch")
                print -r -- "$wt"
                return 0
                ;;
        esac
    done < <(git worktree list --porcelain 2>/dev/null)
    return 1
}

# Pick a project in ~/Dev, ~/Dev/tmp or ~/Projects with fzf and cd into it
cd_fzf() {
    local -a lookup_dirs=(~/Dev(N/) ~/Dev/tmp(N/) ~/Projects(N/))
    if (( ${#lookup_dirs} == 0 )); then
        # as a zle message when running from the key binding
        if [[ -n "$WIDGET" ]]; then
            zle -M "cd_fzf: neither ~/Dev nor ~/Projects exists"
        else
            print -u2 "cd_fzf: neither ~/Dev nor ~/Projects exists"
        fi
        return 1
    fi
    # -L so symlinks to directories are listed (and symlinks to files are not)
    local dir=$(find -L $lookup_dirs -mindepth 1 -maxdepth 1 -type d 2>/dev/null | fzf)
    if [[ -n "$dir" ]]; then
        cd -- "$dir"
    fi
    # redraw the prompt when running from the key binding (rerun precmd so starship updates)
    if [[ -n "$WIDGET" ]]; then
        local precmd
        for precmd in $precmd_functions; do
            $precmd
        done
        zle reset-prompt
    fi
}
zle -N cd_fzf
bindkey '^F' cd_fzf

# Pick a worktree of the current git repo with fzf and cd into it
worktree_fzf() {
    local -a worktrees=("${(@f)$(__git_worktrees)}")
    worktrees=(${worktrees:#})
    if (( ${#worktrees} == 0 )); then
        # as a zle message when running from the key binding
        if [[ -n "$WIDGET" ]]; then
            zle -M "worktree_fzf: not inside a git repository"
        else
            print -u2 "worktree_fzf: not inside a git repository"
        fi
        return 1
    fi
    # drop worktrees whose directory was deleted but not pruned
    local wt
    local -a existing=()
    for wt in $worktrees; do
        [[ -d "$wt" ]] && existing+=("$wt")
    done
    local dir=$(print -rl -- $existing | fzf)
    if [[ -n "$dir" ]]; then
        cd -- "$dir"
    fi
    # redraw the prompt when running from the key binding (rerun precmd so starship updates)
    if [[ -n "$WIDGET" ]]; then
        local precmd
        for precmd in $precmd_functions; do
            $precmd
        done
        zle reset-prompt
    fi
}
zle -N worktree_fzf
bindkey '^T' worktree_fzf

# Create a worktree for a branch in ~/Dev/.worktrees (or jump to it) and cd into it
#   ~/Dev/dotfiles $ worktree feature/zsh        # -> ~/Dev/.worktrees/dotfiles-feature-zsh
#   ~/Dev/dotfiles $ worktree feature/zsh zsh    # -> ~/Dev/.worktrees/dotfiles-zsh
worktree() {
    local branch=$1 name=$2
    if [[ -z "$branch" ]] || (( $# > 2 )); then
        print -u2 "usage: worktree <branch> [dirname]"
        return 1
    fi
    local main=$(__git_worktrees | head -n1)
    if [[ -z "$main" ]]; then
        print -u2 "worktree: not inside a git repository"
        return 1
    fi

    # Branch already checked out somewhere (git refuses a second checkout): go there
    local dest=$(__git_branch_worktree "$branch")
    if [[ -z "$dest" ]]; then
        # "feature/foo" -> "feature-foo" so the worktree dir is not nested
        [[ -n "$name" ]] || name=${branch//\//-}
        dest=~/Dev/.worktrees/${main:t}-$name
        if [[ -e "$dest" ]]; then
            print -u2 "worktree: $dest already exists but is not a worktree for $branch"
            return 1
        fi
        mkdir -p "${dest:h}" || return 1
        # A local branch, or a remote-only one (git creates a tracking branch)
        if git show-ref --verify --quiet "refs/heads/$branch" \
            || [[ -n "$(git for-each-ref --count=1 "refs/remotes/*/$branch")" ]]; then
            git worktree add "$dest" "$branch" || return 1
        else
            git worktree add -b "$branch" "$dest" || return 1
        fi
    fi
    cd -- "$dest"
}
_worktree() {
    (( CURRENT == 2 )) || return 1
    local -a branches=(
        ${(f)"$(git for-each-ref --format='%(refname:lstrip=2)' refs/heads 2>/dev/null)"}
        ${(f)"$(git for-each-ref --format='%(refname:lstrip=3)' refs/remotes 2>/dev/null | grep -vx HEAD)"}
    )
    compadd -a branches
}
compdef _worktree worktree

##############
# PATH
##############
typeset -U path # drop duplicates, like fish_add_path
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cache/.bun/bin:$PATH"
export PATH="$HOME/.bun/bin:$PATH"
export PATH="$HOME/.go/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.opencode/bin:$PATH"
export PATH="$HOME/.grok/bin:$PATH"

##############
# VARS
##############
export GOPATH="$HOME/.go" # so go does not polute my home dir
export BUN_INSTALL="$HOME/.bun"
export EDITOR="nvim"

##############
# SOURCE
##############
if command -v mise >/dev/null; then
    eval "$(mise activate zsh)"
fi

if [[ -f "$HOME/.config/vite-plus/env" ]]; then
    source "$HOME/.config/vite-plus/env"
fi

if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
fi

if command -v starship >/dev/null; then
    eval "$(starship init zsh)"
fi

##############
# ALIASES
##############
alias cf-curl="cloudflared access curl"


##############
# PLUGINS
##############
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[arg0]=none
ZSH_HIGHLIGHT_STYLES[unknown-token]=fg=red
ZSH_HIGHLIGHT_STYLES[precommand]=underline
ZSH_HIGHLIGHT_STYLES[suffix-alias]=underline
ZSH_HIGHLIGHT_STYLES[autodirectory]=underline

__source_plugin() {
    local dir
    for dir in /usr/share /opt/homebrew/share; do
        if [[ -f "$dir/$1/$1.zsh" ]]; then
            source "$dir/$1/$1.zsh"
            return
        fi
    done
}
__source_plugin zsh-autosuggestions
__source_plugin zsh-syntax-highlighting
