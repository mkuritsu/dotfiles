##############
# FUNCTIONS
##############
function fish_greeting
end

function cd_fzf
    set lookup_dirs
    if test -d ~/Dev
        set lookup_dirs $lookup_dirs ~/Dev
    end
    if test -d ~/Projects
        set lookup_dirs $lookup_dirs ~/Projects/
    end
    set dir $(find $lookup_dirs -mindepth 1 -maxdepth 1 -type d -o -type l | fzf)
    if test -n "$dir"
        cd $dir
        commandline -f repaint
    end
end
bind ctrl-f cd_fzf

function worktree_fzf
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        echo "not inside a git repository"
        return
    end
    set project $(basename $(dirname $(realpath $(git rev-parse --git-common-dir))))
    set dir $(begin
        git worktree list | awk '{print $1}'
        find ~/Dev/worktrees -mindepth 1 -maxdepth 1 -type d -name "$project-*" 2>/dev/null
    end | sort -u | fzf)
    if test -n "$dir"
        cd $dir
        commandline -f repaint
    end
end
bind ctrl-t worktree_fzf

function project_worktree_fzf
    if not test -d ~/Dev
        echo "~/Dev does not exist"
        return
    end
    set project $(find ~/Dev -mindepth 1 -maxdepth 1 \( -type d -o -type l \) ! -path "*/Dev/worktrees" | fzf)
    if test -z "$project"
        return
    end
    if not git -C $project rev-parse --is-inside-work-tree >/dev/null 2>&1
        echo "$project is not a git repository"
        return
    end
    set project_name $(basename $project)
    set dir $(begin
        git -C $project worktree list | awk '{print $1}'
        find ~/Dev/worktrees -mindepth 1 -maxdepth 1 -type d -name "$project_name-*" 2>/dev/null
    end | sort -u | fzf)
    if test -n "$dir"
        cd $dir
        commandline -f repaint
    end
end
bind ctrl-g project_worktree_fzf

function worktree
    set branch $argv[1]
    set dirname $argv[2]
    if test -z "$branch"
        echo "usage: worktree <branch> [dirname]"
        return 1
    end
    if test -z "$dirname"
        set dirname $branch
    end
    if not git rev-parse --is-inside-work-tree >/dev/null 2>&1
        echo "not inside a git repository"
        return 1
    end
    set repo_root $(dirname $(realpath $(git rev-parse --git-common-dir)))
    set project $(basename $repo_root)
    set dest ~/Dev/worktrees/$project-$dirname
    if not test -d $dest
        mkdir -p $(dirname $dest)
        if git show-ref --verify --quiet refs/heads/$branch
            git worktree add $dest $branch
        else
            git worktree add -b $branch $dest
        end
    end
    if test -d $dest
        cd $dest
        commandline -f repaint
    end
end

##############
# PATH
##############
fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/.cache/.bun/bin"
fish_add_path "$HOME/.bun/bin"
fish_add_path "$HOME/.go/bin"
fish_add_path "$HOME/.cargo/bin"
if test (uname) = Linux
    fish_add_path "/home/linuxbrew/.linuxbrew/bin"
end

##############
# VARS
##############
set -x GOPATH "$HOME/.go" # so go does not polute my home dir
set -x BUN_INSTALL "$HOME/.bun"

##############
# SOURCE
##############
if test -f "$HOME/.vite-plus/env.fish"
    source "$HOME/.config/vite-plus/env.fish"
end

if test -f "$HOME/.cargo/env.fish"
    source "$HOME/.cargo/env.fish"
end

if type -q starship
    starship init fish | source
end

if type -q mise
	mise activate fish | source
end

##############
# ALIASES
##############

alias cf-curl="cloudflared access curl"