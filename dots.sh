#!/usr/bin/env bash
#
# dots - manage this dotfiles repo by symlinking its files into $HOME
#
# Every file under the repo's top-level directories is symlinked, one file at
# a time (never whole directories), to the matching path in $HOME:
#   config/  -> ~/.config/
#   local/   -> ~/.local/
#   pi/      -> ~/.pi/
# Paths listed in LINUX_ONLY_PATHS (config/hypr, config/uwsm, config/vicinae)
# are only linked on Linux. `link` also installs this script as
# ~/.local/bin/dots, so after the first run it can be called as `dots`.
#
# Profiles: machine-specific files live in profiles/<name>/ with the same
# layout (e.g. profiles/work/config/git/config). The active profile's files are
# linked on top of the shared ones and win when both have the same path. The
# active profile is stored in ~/.local/state/dots/profile; the DOTS_PROFILE
# environment variable overrides it (set it to "" to disable profiles).
#
# .dotsignore: one path per line (relative to $HOME or to the repo, or
# absolute) that `check` should not report as untracked; "#" starts a comment.
# Each profile can add its own profiles/<name>/.dotsignore. It does not
# affect `link`.
#
# Usage:
#   dots <command> [options]
#
# Commands:
#   link [--dry-run] [--force|-f] [--profile NAME] [PATH...]
#       Symlink every tracked file into $HOME. An existing regular file is
#       moved to <file>.bak first (skipped if <file>.bak already exists).
#       A symlink pointing elsewhere is left alone unless --force is given.
#       With PATHs, only link the tracked files at or under them (and skip
#       installing ~/.local/bin/dots). A PATH can be a repo path (config/nvim),
#       a $HOME path (~/.config/nvim) or a path relative to the current dir.
#   unlink [--dry-run] [--restore]
#       Remove the symlinks that point into the repo (shared files and every
#       profile). With --restore, move <file>.bak back into place.
#   check [--interactive|-i] [--profile NAME]
#       List tracked files that are not symlinked, and files in linked
#       directories that are not in the repo. With -i, offer to `add` each
#       untracked file.
#   add [--profile NAME] FILE
#       Move FILE (which must be under ~/.config, ~/.local or ~/.pi) into the
#       repo, or into the profile, and replace it with a symlink.
#   ignore [--profile NAME] PATH
#       Add PATH (under $HOME) to .dotsignore, or to the profile's.
#   profile [list | set NAME | unset]
#       Show, list, switch or clear the active profile.
#   diff [GIT_ARGS...]      Run git diff in the repo.
#   status [GIT_ARGS...]    Run git status in the repo.
#   help                    Show usage.
#
# Examples:
#   ./dots.sh link                          # first-time setup, from the repo
#   dots link --dry-run                     # preview what link would do
#   dots link --force                       # also replace foreign symlinks
#   dots link config/nvim ~/.config/fish    # link only nvim and fish configs
#   dots link --dry-run pi/agent/AGENTS.md  # preview linking a single file
#   dots check -i                           # review and adopt new config files
#   dots add ~/.config/foo/foo.toml         # start tracking a file
#   dots add --profile work ~/.config/git/config
#   dots ignore ~/.config/fish/fish_variables
#   dots profile set work && dots link
#   DOTS_PROFILE=work dots link --dry-run   # try a profile without switching
#   dots unlink --restore                   # undo link, bring back .bak files
#
# Compatibility: must run on bash 3.2 (macOS /bin/bash) with BSD tools, so no
# associative arrays, namerefs or other bash 4+ features, empty arrays are
# expanded as ${arr[@]+"${arr[@]}"} (plain "${arr[@]}" fails with set -u),
# and no GNU-only flags such as readlink -f.
#
set -euo pipefail

# With CDPATH set, `cd` prints the directory it changed to, which would end up
# in $(cd ... && pwd) results such as REPO_DIR
unset CDPATH

resolve_link() {
    local path="$1" target
    while [[ -L "$path" ]]; do
        target="$(readlink "$path")"
        if [[ "$target" == /* ]]; then
            path="$target"
        else
            path="$(dirname "$path")/$target"
        fi
    done
    echo "$path"
}

REPO_DIR="$(cd "$(dirname "$(resolve_link "$0")")" && pwd)"
OS="$(uname -s)"
SCRIPT_NAME="$(basename "$(resolve_link "$0")")"

# Top-level directory mappings (repo_name:target_name)
DIR_MAPPINGS=(
    "config:.config"
    "local:.local"
    "pi:.pi"
)

# Linux-only directories (relative to repo root)
LINUX_ONLY_PATHS=(
    "config/hypr"
    "config/uwsm"
    "config/vicinae"
)

# ─── Profile ─────────────────────────────────────────────────

PROFILE_DIR="$HOME/.local/state/dots"
PROFILE_FILE="$PROFILE_DIR/profile"
ACTIVE_PROFILE=""

load_profile() {
    if [[ "${DOTS_PROFILE+set}" == "set" ]]; then
        ACTIVE_PROFILE="${DOTS_PROFILE:-}"
    elif [[ -f "$PROFILE_FILE" ]]; then
        ACTIVE_PROFILE="$(< "$PROFILE_FILE")"
    else
        ACTIVE_PROFILE=""
    fi
}

check_profile_name() {
    local name="$1"
    if [[ -z "$name" || "$name" == */* || "$name" == .* ]]; then
        echo "Error: invalid profile name '$name'." >&2
        exit 1
    fi
}

# Load the active profile, apply a --profile override and make sure it exists
resolve_profile() {
    local override="$1"
    load_profile
    [[ -n "$override" ]] && ACTIVE_PROFILE="$override"
    [[ -z "$ACTIVE_PROFILE" ]] && return 0
    check_profile_name "$ACTIVE_PROFILE"
    if [[ ! -d "$REPO_DIR/profiles/$ACTIVE_PROFILE" ]]; then
        echo "Error: profile '$ACTIVE_PROFILE' not found in profiles/ (see '$SCRIPT_NAME profile list')." >&2
        exit 1
    fi
}

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME <command> [options]

Commands:
  link [path...]    Create symlinks for all tracked files (or only those under path) in \$HOME
  unlink            Remove symlinks created by link
  check             List tracked files not symlinked and untracked files in linked dirs
  add <file>        Copy a file into the repo and replace it with a symlink
  ignore <path>     Resolve path and add it to .dotsignore
  profile           Manage profiles (set, list, unset)
  diff [args]       Run git diff in the repo directory
  status [args]     Show git status of the repo directory
  help              Show this help message

Options:
  --dry-run         For link/unlink: show what would be done without doing it
  --restore         For unlink: restore .bak files when removing symlinks
  --force, -f       For link: overwrite existing symlinks pointing elsewhere
  --interactive, -i For check: prompt before adding each untracked file
  --profile <name>  For add/ignore/link/check: target a specific profile
EOF
    exit "${1:-1}"
}

unknown_option() {
    echo "Error: unknown option for $1: $2" >&2
    exit 1
}

# ─── Dotsignore ───────────────────────────────────────────────

DOTSIGNORE_FILE="$REPO_DIR/.dotsignore"
DOTSIGNORE_PATHS=()

# Append the non-comment, non-empty lines of an ignore file to DOTSIGNORE_PATHS
read_ignore_file() {
    local f="$1" line
    [[ -f "$f" ]] || return 0
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%%#*}"
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -z "$line" ]] && continue
        DOTSIGNORE_PATHS+=("$line")
    done < "$f"
}

load_dotsignore() {
    DOTSIGNORE_PATHS=()
    read_ignore_file "$DOTSIGNORE_FILE"
    if [[ -n "$ACTIVE_PROFILE" ]]; then
        read_ignore_file "$REPO_DIR/profiles/$ACTIVE_PROFILE/.dotsignore"
    fi
}

is_ignored() {
    local target_path="$1"
    local repo_rel="$2"
    local home_rel="${target_path#"$HOME"/}"
    local pattern
    for pattern in ${DOTSIGNORE_PATHS[@]+"${DOTSIGNORE_PATHS[@]}"}; do
        local pat="${pattern%/}"
        if [[ "$repo_rel" == "$pat" || "$repo_rel" == "$pat"/* ]] || \
           [[ "$home_rel" == "$pat" || "$home_rel" == "$pat"/* ]] || \
           [[ "$target_path" == "$pat" ]]; then
            return 0
        fi
    done
    return 1
}

# ─── File sources ───────────────────────────────────────────

get_shared_files() {
    local mapping d
    for mapping in "${DIR_MAPPINGS[@]}"; do
        d="${mapping%%:*}"
        [[ -d "$REPO_DIR/$d" ]] && find "$REPO_DIR/$d" -type f -print0
    done
}

get_profile_files() {
    local profile="$1"
    local mapping d dd
    for mapping in "${DIR_MAPPINGS[@]}"; do
        d="${mapping%%:*}"
        dd="$REPO_DIR/profiles/$profile/$d"
        [[ -d "$dd" ]] && find "$dd" -type f ! -name '.dotsignore' -print0
    done
}

# Tracked files to link, as parallel arrays: TARGET_PATHS[i] (in $HOME) links
# to TARGET_FILES[i] (in the repo). Filled by collect_targets.
TARGET_PATHS=()
TARGET_FILES=()

# Collect the shared files plus the active profile's files; a profile file
# replaces the shared file with the same path
collect_targets() {
    TARGET_PATHS=()
    TARGET_FILES=()
    local file rel prof_dir=""
    [[ -n "$ACTIVE_PROFILE" ]] && prof_dir="$REPO_DIR/profiles/$ACTIVE_PROFILE"

    while IFS= read -r -d '' file; do
        rel="${file#"$REPO_DIR"/}"
        should_include "$rel" || continue
        [[ -n "$prof_dir" && -f "$prof_dir/$rel" ]] && continue
        TARGET_PATHS+=("$(to_target_path "$rel")")
        TARGET_FILES+=("$file")
    done < <(get_shared_files)

    if [[ -n "$prof_dir" ]]; then
        while IFS= read -r -d '' file; do
            rel="${file#"$prof_dir"/}"
            should_include "$rel" || continue
            TARGET_PATHS+=("$(to_target_path "$rel")")
            TARGET_FILES+=("$file")
        done < <(get_profile_files "$ACTIVE_PROFILE")
    fi
}

# True if $1 is equal to one of the remaining arguments
contains() {
    local needle="$1" item
    shift
    for item in "$@"; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

# ─── OS / filtering ────────────────────────────────────────

is_linux_only() {
    local path="$1"
    local lp
    for lp in "${LINUX_ONLY_PATHS[@]}"; do
        [[ "$path" == "$lp" || "$path" == "$lp"/* ]] && return 0
    done
    return 1
}

should_include() {
    local path="$1"
    is_linux_only "$path" || return 0
    [[ "$OS" == "Linux" ]]
}

# ─── Path conversion ───────────────────────────────────────

to_target_path() {
    local repo_rel="$1"
    local first="${repo_rel%%/*}"
    local rest=""
    [[ "$first" != "$repo_rel" ]] && rest="${repo_rel#*/}"

    local mapped_first=""
    local mapping rn tn
    for mapping in "${DIR_MAPPINGS[@]}"; do
        rn="${mapping%%:*}"
        tn="${mapping#*:}"
        if [[ "$first" == "$rn" ]]; then
            mapped_first="$tn"
            break
        fi
    done
    if [[ -z "$mapped_first" ]]; then
        [[ "$first" == dot_* ]] && mapped_first=".${first:4}" || mapped_first="$first"
    fi

    local target="$HOME/$mapped_first"
    [[ -n "$rest" ]] && target="$target/$rest"
    echo "$target"
}

to_repo_path() {
    local target_path="$1"
    local rel="${target_path#"$HOME"/}"

    local first="${rel%%/*}"
    local rest=""
    [[ "$first" != "$rel" ]] && rest="${rel#*/}"

    local mapped_first=""
    local mapping rn tn
    for mapping in "${DIR_MAPPINGS[@]}"; do
        rn="${mapping%%:*}"
        tn="${mapping#*:}"
        if [[ "$first" == "$tn" ]]; then
            mapped_first="$rn"
            break
        fi
    done
    if [[ -z "$mapped_first" ]]; then
        mapped_first="$first"
    fi

    local result="$mapped_first"
    if [[ -n "$rest" ]]; then
        result="$result/$rest"
    fi

    echo "$result"
}

# Expand a leading ~ (as in a quoted "~/foo"). Not ${1/#\~/"$HOME"}: bash 3.2
# keeps the quotes of the replacement literally.
expand_tilde() {
    local path="$1"
    if [[ "$path" == "~" || "$path" == "~/"* ]]; then
        path="$HOME${path:1}"
    fi
    echo "$path"
}

# Absolute path of $1 (with a leading ~ expanded) without resolving symlinks,
# so a file under a symlinked directory keeps its path under $HOME
abs_path() {
    local path dir
    path="$(expand_tilde "$1")"
    path="${path%/}"
    [[ "$path" == /* ]] || path="$PWD/$path"
    if [[ "$path" == */. || "$path" == */.. ]]; then
        (cd "$path" 2>/dev/null && pwd)
        return
    fi
    dir="$(cd "$(dirname "$path")" 2>/dev/null && pwd)" || return 1
    echo "${dir%/}/$(basename "$path")"
}

# True if $1 (an absolute path) is inside one of the mapped $HOME directories
is_under_mapped_dir() {
    local path="$1" mapping
    for mapping in "${DIR_MAPPINGS[@]}"; do
        [[ "$path" == "$HOME/${mapping#*:}"/* ]] && return 0
    done
    return 1
}

# Convert a `link` PATH argument to the $HOME path it covers. Accepts repo
# paths (config/nvim, profiles/work/config/git), $HOME paths (~/.config/nvim)
# and paths relative to the current directory
to_link_filter() {
    local path first mapping rel
    path="$(expand_tilde "$1")"
    path="${path%/}"

    if [[ -e "$path" || -L "$path" ]]; then
        path=$(abs_path "$path") || return 1
    elif [[ "$path" != /* ]]; then
        # Not relative to the current dir: try as a repo or $HOME-relative path
        first="${path%%/*}"
        for mapping in "${DIR_MAPPINGS[@]}"; do
            if [[ "$first" == "${mapping%%:*}" ]]; then
                to_target_path "$path"
                return 0
            elif [[ "$first" == "${mapping#*:}" ]]; then
                echo "$HOME/$path"
                return 0
            fi
        done
        return 1
    fi

    if [[ "$path" == "$REPO_DIR"/* ]]; then
        rel="${path#"$REPO_DIR"/}"
        [[ "$rel" == profiles/*/* ]] && rel="${rel#profiles/*/}"
        to_target_path "$rel"
    elif [[ "$path" == "$HOME"/* ]]; then
        echo "$path"
    else
        return 1
    fi
}

# ─── Commands ───────────────────────────────────────────────

cmd_link() {
    local dry_run=false force=false
    local profile_override=""
    local paths=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run) dry_run=true; shift ;;
            --force|-f) force=true; shift ;;
            --profile) [[ $# -ge 2 ]] && { profile_override="$2"; shift 2; } || { echo "Error: --profile requires a name." >&2; exit 1; } ;;
            --) shift; paths+=("$@"); break ;;
            -*) unknown_option link "$1" ;;
            *) paths+=("$1"); shift ;;
        esac
    done

    resolve_profile "$profile_override"

    collect_targets

    local count=0 i file tgt cur

    # Only keep the targets at or under the given paths
    if [[ ${#paths[@]} -gt 0 ]]; then
        local sel_paths=() sel_files=()
        local p filter matched
        for p in "${paths[@]}"; do
            filter=$(to_link_filter "$p") || {
                echo "Error: '$p' is not a repo path or a path under ~/.config, ~/.local or ~/.pi." >&2
                exit 1
            }
            matched=false
            for ((i = 0; i < ${#TARGET_PATHS[@]}; i++)); do
                tgt="${TARGET_PATHS[i]}"
                [[ "$tgt" == "$filter" || "$tgt" == "$filter"/* ]] || continue
                matched=true
                # Overlapping PATHs (config and config/nvim) select a file twice
                contains "$tgt" ${sel_paths[@]+"${sel_paths[@]}"} && continue
                sel_paths+=("$tgt")
                sel_files+=("${TARGET_FILES[i]}")
            done
            $matched || { echo "Error: no tracked files match '$p' ($filter)." >&2; exit 1; }
        done
        TARGET_PATHS=("${sel_paths[@]}")
        TARGET_FILES=("${sel_files[@]}")
    fi

    for ((i = 0; i < ${#TARGET_PATHS[@]}; i++)); do
        tgt="${TARGET_PATHS[i]}"
        file="${TARGET_FILES[i]}"

        if [[ -L "$tgt" ]]; then
            cur=$(readlink "$tgt")
            [[ "$cur" == "$file" ]] && continue
            if ! $force; then
                echo "Warning: $tgt links to $cur (expected $file). Skipping." >&2
                continue
            fi
            if $dry_run; then
                echo "[DRY RUN] $tgt -> $file (replacing link to $cur)"
            else
                ln -sfn "$file" "$tgt"
                echo "Linked (forced): $tgt -> $file"
            fi
        elif [[ -e "$tgt" ]]; then
            # A parent directory is a symlink into the repo, so $tgt already
            # is the repo file; moving it to .bak would move the repo file
            if [[ "$tgt" -ef "$file" ]]; then
                echo "Warning: $tgt already resolves to $file through a symlinked parent directory. Skipping." >&2
                continue
            fi
            if [[ -e "$tgt.bak" || -L "$tgt.bak" ]]; then
                echo "Warning: $tgt exists and $tgt.bak is already taken. Skipping." >&2
                continue
            fi
            if $dry_run; then
                echo "[DRY RUN] $tgt -> $file (backing up existing file to $tgt.bak)"
            else
                mv "$tgt" "$tgt.bak"
                echo "Backed up: $tgt -> $tgt.bak"
                ln -s "$file" "$tgt"
                echo "Linked: $tgt -> $file"
            fi
        else
            if $dry_run; then
                echo "[DRY RUN] $tgt -> $file"
            else
                mkdir -p "$(dirname "$tgt")"
                ln -s "$file" "$tgt"
                echo "Linked: $tgt -> $file"
            fi
        fi
        ((++count))
    done

    local self_target="$HOME/.local/bin/dots"
    local self_src="$REPO_DIR/dots.sh"
    local needs_self=true
    if [[ ${#paths[@]} -gt 0 ]]; then
        needs_self=false
    elif [[ -L "$self_target" ]]; then
        [[ "$(readlink "$self_target")" == "$self_src" ]] && needs_self=false
    elif [[ -e "$self_target" ]]; then
        echo "Warning: $self_target exists and is not a symlink. Skipping." >&2
        needs_self=false
    fi
    if $needs_self; then
        if $dry_run; then
            echo "[DRY RUN] $self_target -> $self_src"
        else
            mkdir -p "$(dirname "$self_target")"
            ln -sfn "$self_src" "$self_target"
            echo "Linked: $self_target -> $self_src"
        fi
        ((++count))
    fi

    if $dry_run; then
        echo "[DRY RUN] Would create $count symlinks."
    elif [[ $count -eq 0 ]]; then
        echo "Everything is already linked."
    fi
    return 0
}

cmd_check() {
    local interactive=false
    local profile_override=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --interactive|-i) interactive=true; shift ;;
            --profile) [[ $# -ge 2 ]] && { profile_override="$2"; shift 2; } || { echo "Error: --profile requires a name." >&2; exit 1; } ;;
            *) unknown_option check "$1" ;;
        esac
    done

    resolve_profile "$profile_override"
    load_dotsignore

    local i file tgt tgt_dir entry lt rp
    local unlinked=()
    local untracked=()

    collect_targets

    # ── List 1: non-linked files (tracked in repo but not symlinked) ──
    for ((i = 0; i < ${#TARGET_PATHS[@]}; i++)); do
        tgt="${TARGET_PATHS[i]}"
        file="${TARGET_FILES[i]}"
        [[ -L "$tgt" && "$(readlink "$tgt")" == "$file" ]] && continue
        unlinked+=("${file#"$REPO_DIR"/}")
    done

    # ── List 2: untracked files ──
    # Scan the dirs holding tracked files, except the top-level ones
    # (~/.config itself etc.), which hold too many unrelated files
    local top_targets=() mapping
    for mapping in "${DIR_MAPPINGS[@]}"; do
        top_targets+=("$HOME/${mapping#*:}")
    done

    local target_dirs=()
    for ((i = 0; i < ${#TARGET_PATHS[@]}; i++)); do
        tgt_dir=$(dirname "${TARGET_PATHS[i]}")
        contains "$tgt_dir" "${top_targets[@]}" && continue
        contains "$tgt_dir" ${target_dirs[@]+"${target_dirs[@]}"} && continue
        target_dirs+=("$tgt_dir")
    done

    local dir
    for dir in ${target_dirs[@]+"${target_dirs[@]}"}; do
        [[ -d "$dir" ]] || continue
        [[ "$dir" == "$HOME/.local/bin" ]] && continue

        while IFS= read -r -d '' entry; do
            [[ -f "$entry" || -L "$entry" ]] || continue

            if [[ -L "$entry" ]]; then
                lt=$(readlink "$entry")
                [[ "$lt" == "$REPO_DIR"/* ]] && continue
            fi

            rp=$(to_repo_path "$entry")
            # Check both shared and current profile directories
            if [[ -f "$REPO_DIR/$rp" ]]; then
                continue
            fi
            if [[ -n "$ACTIVE_PROFILE" && -f "$REPO_DIR/profiles/$ACTIVE_PROFILE/$rp" ]]; then
                continue
            fi

            is_ignored "$entry" "$rp" && continue
            untracked+=("$entry")
        done < <(find "$dir" -maxdepth 1 \( -type f -o -type l \) -print0 2>/dev/null)
    done

    # ── Output ──
    if [[ ${#unlinked[@]} -eq 0 && ${#untracked[@]} -eq 0 ]]; then
        echo "All clean — tracked files are symlinked and no untracked files found."
        return 0
    fi

    if [[ ${#unlinked[@]} -gt 0 ]]; then
        echo "Non-linked files (tracked but not symlinked):"
        printf '  \033[32m%s\033[0m\n' "${unlinked[@]}"
        echo
    fi

    if [[ ${#untracked[@]} -gt 0 ]]; then
        echo "Untracked files (in linked dirs, not in repo):"
        printf '  \033[31m%s\033[0m\n' "${untracked[@]}"
        echo
    fi

    if $interactive && [[ ${#untracked[@]} -gt 0 ]]; then
        local f yn
        for f in "${untracked[@]}"; do
            read -rp "Add '$f' to the repo? [Y/n] " yn || { echo; break; }
            case "$yn" in
                [Nn]*) ;;
                # Subshell so a failed add skips the file instead of aborting
                *) ( cmd_add "$f" ) || echo "Skipped: $f" >&2 ;;
            esac
        done
    fi
}

cmd_add() {
    local target_file=""
    local profile_name=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --profile) [[ $# -ge 2 ]] && { profile_name="$2"; shift 2; } || { echo "Error: --profile requires a name." >&2; exit 1; } ;;
            --) shift; [[ $# -gt 0 ]] && { target_file="$1"; shift; } ;;
            -*) unknown_option add "$1" ;;
            *)
                [[ -n "$target_file" ]] && { echo "Error: add takes a single file." >&2; exit 1; }
                target_file="$1"; shift ;;
        esac
    done

    [[ -z "$target_file" ]] && { echo "Error: add requires a file path." >&2; exit 1; }
    target_file="$(expand_tilde "$target_file")"
    [[ -n "$profile_name" ]] && check_profile_name "$profile_name"
    [[ -f "$target_file" || -L "$target_file" ]] || {
        echo "Error: $target_file does not exist or is not a file." >&2
        exit 1
    }

    local abs
    abs=$(abs_path "$target_file") || {
        echo "Error: cannot resolve path '$target_file'." >&2
        exit 1
    }

    if [[ "$abs" == "$REPO_DIR"/* ]] || \
       { [[ -L "$abs" ]] && [[ "$(resolve_link "$abs")" == "$REPO_DIR"/* ]]; }; then
        echo "Error: $target_file is already managed by this repo." >&2
        exit 1
    fi

    if ! is_under_mapped_dir "$abs"; then
        echo "Error: $abs is not under a linked directory (~/.config, ~/.local or ~/.pi)." >&2
        exit 1
    fi

    local repo_rel repo_full
    repo_rel=$(to_repo_path "$abs")

    if [[ -n "$profile_name" ]]; then
        repo_full="$REPO_DIR/profiles/$profile_name/$repo_rel"
    else
        repo_full="$REPO_DIR/$repo_rel"
    fi

    if [[ -e "$repo_full" ]]; then
        echo "Error: $repo_full already exists." >&2
        exit 1
    fi

    # Checked explicitly: errexit is off when called from `check -i`, and the
    # original must not be removed unless the copy succeeded
    mkdir -p "$(dirname "$repo_full")" && cp -p "$abs" "$repo_full" || {
        echo "Error: failed to copy $abs to $repo_full." >&2
        exit 1
    }

    rm -f "$abs"
    ln -s "$repo_full" "$abs" || {
        echo "Error: failed to link $abs; the file is saved at $repo_full." >&2
        exit 1
    }
    echo "Added: $abs -> $repo_full"
}

cmd_ignore() {
    local raw_path=""
    local profile_name=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --profile) [[ $# -ge 2 ]] && { profile_name="$2"; shift 2; } || { echo "Error: --profile requires a name." >&2; exit 1; } ;;
            --) shift; [[ $# -gt 0 ]] && { raw_path="$1"; shift; } ;;
            -*) unknown_option ignore "$1" ;;
            *)
                [[ -n "$raw_path" ]] && { echo "Error: ignore takes a single path." >&2; exit 1; }
                raw_path="$1"; shift ;;
        esac
    done

    [[ -z "$raw_path" ]] && { echo "Error: ignore requires a file path." >&2; exit 1; }
    [[ -n "$profile_name" ]] && check_profile_name "$profile_name"

    local abs
    abs=$(abs_path "$raw_path") || {
        echo "Error: cannot resolve path '$raw_path'." >&2
        exit 1
    }

    [[ "$abs" == "$HOME"/* ]] || {
        echo "Error: path '$raw_path' is not under \$HOME ($HOME)." >&2
        exit 1
    }

    local home_rel="${abs#"$HOME"/}"

    local ignore_file="$DOTSIGNORE_FILE"
    if [[ -n "$profile_name" ]]; then
        ignore_file="$REPO_DIR/profiles/$profile_name/.dotsignore"
        mkdir -p "$(dirname "$ignore_file")"
    fi

    # Load relevant ignores for duplicate check
    DOTSIGNORE_PATHS=()
    read_ignore_file "$ignore_file"

    local pattern
    for pattern in ${DOTSIGNORE_PATHS[@]+"${DOTSIGNORE_PATHS[@]}"}; do
        [[ "$pattern" == "$home_rel" ]] && {
            echo "Already ignored: $home_rel"
            return 0
        }
    done

    if [[ -s "$ignore_file" ]]; then
        local file_end
        file_end="$(tail -c 1 "$ignore_file"; echo x)"
        file_end="${file_end%x}"
        [[ "$file_end" == $'\n' ]] || printf '\n' >> "$ignore_file"
    fi
    echo "$home_rel" >> "$ignore_file"
    echo "Added to ${ignore_file#"$REPO_DIR"/}: $home_rel"
}

# Remove $2 if it is a symlink to $1, restoring $2.bak when --restore was given.
# Uses dry_run, restore and count from the calling cmd_unlink.
unlink_target() {
    local file="$1" tgt="$2"
    [[ -L "$tgt" && "$(readlink "$tgt")" == "$file" ]] || return 0

    local bak="$tgt.bak" do_restore=false
    if $restore && [[ -e "$bak" || -L "$bak" ]]; then
        do_restore=true
    fi

    if $dry_run; then
        if $do_restore; then
            echo "[DRY RUN] Remove $tgt, restore $bak"
        else
            echo "[DRY RUN] Remove $tgt"
        fi
    else
        rm "$tgt"
        if $do_restore; then
            mv "$bak" "$tgt"
            echo "Restored: $tgt <- $bak"
        else
            echo "Removed: $tgt"
        fi
    fi
    ((++count))
}

cmd_unlink() {
    local dry_run=false restore=false
    local arg

    for arg in "$@"; do
        case "$arg" in
            --dry-run) dry_run=true ;;
            --restore) restore=true ;;
            *) unknown_option unlink "$arg" ;;
        esac
    done

    local count=0 file rel

    # Shared files
    while IFS= read -r -d '' file; do
        rel="${file#"$REPO_DIR"/}"
        should_include "$rel" || continue
        unlink_target "$file" "$(to_target_path "$rel")"
    done < <(get_shared_files)

    # All profiles (a target links to at most one file, so no dedup is needed)
    if [[ -d "$REPO_DIR/profiles" ]]; then
        local prof
        while IFS= read -r -d '' prof; do
            while IFS= read -r -d '' file; do
                rel="${file#"$prof"/}"
                should_include "$rel" || continue
                unlink_target "$file" "$(to_target_path "$rel")"
            done < <(get_profile_files "$(basename "$prof")")
        done < <(find "$REPO_DIR/profiles" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
    fi

    if $dry_run; then
        echo "[DRY RUN] Would remove $count symlinks."
    elif [[ $count -eq 0 ]]; then
        echo "No symlinks to remove."
    fi
}

cmd_diff() {
    git -C "$REPO_DIR" diff "$@"
}

cmd_status() {
    git -C "$REPO_DIR" status "$@"
}

cmd_profile() {
    load_profile

    local action="${1:-}"

    case "$action" in
        list)
            echo "Available profiles:"
            local p found=false
            for p in "$REPO_DIR/profiles/"*/; do
                if [[ -d "$p" ]]; then
                    local name; name="$(basename "$p")"
                    if [[ "$name" == "$ACTIVE_PROFILE" ]]; then
                        echo "  $name (active)"
                    else
                        echo "  $name"
                    fi
                    found=true
                fi
            done
            $found || echo "  (none)"
            ;;
        set)
            local name="${2:-}"
            [[ -z "$name" ]] && { echo "Error: profile set requires a name." >&2; exit 1; }
            check_profile_name "$name"
            if [[ -d "$REPO_DIR/profiles/$name" ]]; then
                mkdir -p "$PROFILE_DIR"
                echo "$name" > "$PROFILE_FILE"
                ACTIVE_PROFILE="$name"
                echo "Switched to profile: $name (run '$SCRIPT_NAME link' to apply)"
            else
                echo "Error: profile '$name' not found in profiles/." >&2
                exit 1
            fi
            ;;
        unset)
            rm -f "$PROFILE_FILE"
            ACTIVE_PROFILE=""
            echo "Profile unset."
            ;;
        "")
            if [[ -n "$ACTIVE_PROFILE" ]]; then
                echo "Active profile: $ACTIVE_PROFILE"
            else
                echo "No active profile."
            fi
            ;;
        *)
            echo "Unknown profile subcommand: $action" >&2
            echo "Usage: $SCRIPT_NAME profile {set|list|unset}" >&2
            exit 1
            ;;
    esac
}

# ─── Main ───────────────────────────────────────────────────

[[ $# -lt 1 ]] && usage

load_profile

case "$1" in
    link)    shift; cmd_link "$@" ;;
    unlink)  shift; cmd_unlink "$@" ;;
    check)   shift; cmd_check "$@" ;;
    add)     shift; cmd_add "$@" ;;
    ignore)  shift; cmd_ignore "$@" ;;
    profile) shift; cmd_profile "$@" ;;
    diff)    shift; cmd_diff "$@" ;;
    status)  shift; cmd_status "$@" ;;
    help|--help|-h) usage 0 ;;
    *)       echo "Unknown command: $1" >&2; usage ;;
esac
