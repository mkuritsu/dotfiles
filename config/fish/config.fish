# fix distrobox wrong colors
if test -n "$CONTAINER_ID"
    set -g fish_color_autosuggestion 585858
end

##############
# FUNCTIONS
##############
function fish_greeting
end

# Paths of all worktrees of the current repo, main checkout first
function __git_worktrees
    git worktree list --porcelain 2>/dev/null | string replace -rf '^worktree ' ''
end

# Path of the worktree that has branch $argv[1] checked out, if any
function __git_branch_worktree -a branch
    set -l wt
    for line in (git worktree list --porcelain 2>/dev/null)
        switch $line
            case 'worktree *'
                set wt (string replace 'worktree ' '' -- $line)
            case "branch refs/heads/$branch"
                echo $wt
                return 0
        end
    end
    return 1
end

function cd_fzf -d "Pick a project in ~/Dev or ~/Projects with fzf and cd into it"
    set -l lookup_dirs (path filter -d ~/Dev ~/Projects)
    if test (count $lookup_dirs) -eq 0
        echo "cd_fzf: neither ~/Dev nor ~/Projects exists" >&2
        commandline -f repaint
        return 1
    end
    # -L so symlinks to directories are listed (and symlinks to files are not)
    set -l dir (find -L $lookup_dirs -mindepth 1 -maxdepth 1 -type d 2>/dev/null | fzf)
    if test -n "$dir"
        cd $dir
    end
    commandline -f repaint
end
bind ctrl-f cd_fzf

function worktree_fzf -d "Pick a worktree of the current git repo with fzf and cd into it"
    set -l worktrees (__git_worktrees)
    if test (count $worktrees) -eq 0
        echo "worktree_fzf: not inside a git repository" >&2
        commandline -f repaint
        return 1
    end
    # path filter drops worktrees whose directory was deleted but not pruned
    set -l dir (path filter -d $worktrees | fzf)
    if test -n "$dir"
        cd $dir
    end
    commandline -f repaint
end
bind ctrl-t worktree_fzf

function worktree -d "Create a worktree for a branch in ~/Dev/worktrees (or jump to it) and cd into it"
    set -l branch $argv[1]
    set -l name $argv[2]
    if test -z "$branch"; or test (count $argv) -gt 2
        echo "usage: worktree <branch> [dirname]" >&2
        return 1
    end
    set -l main (__git_worktrees)[1]
    if test -z "$main"
        echo "worktree: not inside a git repository" >&2
        return 1
    end

    # Branch already checked out somewhere (git refuses a second checkout): go there
    set -l dest (__git_branch_worktree $branch)
    if test -z "$dest"
        # "feature/foo" -> "feature-foo" so the worktree dir is not nested
        test -n "$name"; or set name (string replace -a / - -- $branch)
        set dest ~/Dev/worktrees/(path basename $main)-$name
        if test -e $dest
            echo "worktree: $dest already exists but is not a worktree for $branch" >&2
            return 1
        end
        mkdir -p (path dirname $dest); or return 1
        # A local branch, or a remote-only one (git creates a tracking branch)
        if git show-ref --verify --quiet refs/heads/$branch
            or test -n "$(git for-each-ref --count=1 "refs/remotes/*/$branch")"
            git worktree add $dest $branch; or return 1
        else
            git worktree add -b $branch $dest; or return 1
        end
    end
    cd $dest
    commandline -f repaint
end
complete -c worktree -f -n '__fish_is_nth_token 1' -a '(
    git for-each-ref --format="%(refname:lstrip=2)" refs/heads 2>/dev/null
    git for-each-ref --format="%(refname:lstrip=3)" refs/remotes 2>/dev/null | string match -v HEAD
)'

##############
# PATH
##############
fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/.cache/.bun/bin"
fish_add_path "$HOME/.bun/bin"
fish_add_path "$HOME/.go/bin"
fish_add_path "$HOME/.cargo/bin"
fish_add_path "$HOME/.opencode/bin"
fish_add_path "$HOME/.grok/bin"

##############
# VARS
##############
set -gx GOPATH "$HOME/.go" # so go does not polute my home dir
set -gx BUN_INSTALL "$HOME/.bun"
set -gx EDITOR "nvim"

##############
# SOURCE
##############
if type -q mise
	mise activate fish | source
end

if test -f "$HOME/.config/vite-plus/env.fish"
    source "$HOME/.config/vite-plus/env.fish"
end

if test -f "$HOME/.cargo/env.fish"
    source "$HOME/.cargo/env.fish"
end

if type -q starship
    starship init fish | source
end

##############
# ALIASES
##############
alias cf-curl="cloudflared access curl"
