#!/usr/bin/env bash
set -euo pipefail

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

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME <command> [options]

Commands:
  link              Create symlinks for all tracked files in \$HOME
  unlink            Remove symlinks created by link (restores .bak files)
  check             List files in linked directories not tracked in the repo
  add <file>        Copy a file into the repo and replace it with a symlink
  ignore <path>     Resolve path and add it to .dotsignore
  profile           Manage profiles (set, list, unset)
  diff [args]       Run git diff in the repo directory
  status            Show git status of the repo directory
  help              Show this help message

Options:
  --dry-run         For link/unlink: show what would be done without doing it
  --restore         For unlink: restore .bak files when removing symlinks
  --force, -f       For link: overwrite existing symlinks pointing elsewhere
  --interactive, -i For check: prompt before adding each untracked file
  --profile <name>  For add/ignore/link/check: target a specific profile
EOF
    exit 1
}

# ─── Dotsignore ───────────────────────────────────────────────

DOTSIGNORE_FILE="$REPO_DIR/.dotsignore"
DOTSIGNORE_PATHS=()

load_dotsignore() {
    DOTSIGNORE_PATHS=()
    local files=("$DOTSIGNORE_FILE")
    if [[ -n "$ACTIVE_PROFILE" ]]; then
        local pf="$REPO_DIR/profiles/$ACTIVE_PROFILE/.dotsignore"
        [[ -f "$pf" ]] && files+=("$pf")
    fi
    local f line
    for f in "${files[@]}"; do
        [[ -f "$f" ]] || continue
        while IFS= read -r line || [[ -n "$line" ]]; do
            line="${line%%#*}"
            line="${line#"${line%%[![:space:]]*}"}"
            line="${line%"${line##*[![:space:]]}"}"
            [[ -z "$line" ]] && continue
            DOTSIGNORE_PATHS+=("$line")
        done < "$f"
    done
}

is_ignored() {
    local target_path="$1"
    local repo_rel="$2"
    local home_rel="${target_path#$HOME/}"
    local pattern
    for pattern in "${DOTSIGNORE_PATHS[@]}"; do
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

# ─── OS / filtering ────────────────────────────────────────

is_linux_only() {
    local path="$1"
    local lp
    for lp in "${LINUX_ONLY_PATHS[@]}"; do
        [[ "$path" == "$lp"* ]] && return 0
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
    if [[ -n "$rest" ]]; then
        target="$target/$(process_path_components "$rest")"
    fi
    echo "$target"
}

process_path_components() {
    local path="$1"
    local result="" part
    IFS='/' read -ra parts <<< "$path"
    for part in "${parts[@]}"; do
        result="${result}/${part}"
    done
    echo "${result#/}"
}

to_repo_path() {
    local target_path="$1"
    local rel="${target_path#$HOME/}"

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

# ─── Commands ───────────────────────────────────────────────

cmd_link() {
    local dry_run=false force=false
    local profile_override=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run) dry_run=true; shift ;;
            --force|-f) force=true; shift ;;
            --profile) [[ $# -ge 2 ]] && { profile_override="$2"; shift 2; } || { echo "Error: --profile requires a name." >&2; exit 1; } ;;
            *) shift ;;
        esac
    done

    load_profile
    [[ -n "$profile_override" ]] && ACTIVE_PROFILE="$profile_override"

    declare -A targets
    local file rel tgt

    while IFS= read -r -d '' file; do
        rel="${file#$REPO_DIR/}"
        ! should_include "$rel" && continue
        tgt=$(to_target_path "$rel")
        targets["$tgt"]="$file"
    done < <(get_shared_files)

    if [[ -n "$ACTIVE_PROFILE" ]]; then
        local prof_dir="$REPO_DIR/profiles/$ACTIVE_PROFILE"
        while IFS= read -r -d '' file; do
            rel="${file#$prof_dir/}"
            ! should_include "$rel" && continue
            tgt=$(to_target_path "$rel")
            targets["$tgt"]="$file"
        done < <(get_profile_files "$ACTIVE_PROFILE")
    fi

    local count=0 tgt_dir cur
    for tgt in "${!targets[@]}"; do
        file="${targets[$tgt]}"
        tgt_dir=$(dirname "$tgt")

        if $dry_run; then
            echo "[DRY RUN] $tgt -> $file"
            ((++count))
            continue
        fi

        mkdir -p "$tgt_dir"

        if [[ -L "$tgt" ]]; then
            cur=$(readlink "$tgt")
            [[ "$cur" == "$file" ]] && continue
            if $force; then
                ln -sf "$file" "$tgt"
                echo "Linked (forced): $tgt -> $file"
                ((++count))
            else
                echo "Warning: $tgt links to $cur (expected $file). Skipping."
            fi
        elif [[ -e "$tgt" ]]; then
            mv "$tgt" "$tgt.bak"
            echo "Backed up: $tgt -> $tgt.bak"
            ln -s "$file" "$tgt"
            echo "Linked: $tgt -> $file"
            ((++count))
        else
            ln -s "$file" "$tgt"
            echo "Linked: $tgt -> $file"
            ((++count))
        fi
    done

    local self_target="$HOME/.local/bin/dots"
    if ! $dry_run; then
        mkdir -p "$HOME/.local/bin"
        if [[ -L "$self_target" ]]; then
            local self_cur; self_cur=$(readlink "$self_target")
            if [[ "$self_cur" != "$REPO_DIR/dots.sh" ]]; then
                ln -sf "$REPO_DIR/dots.sh" "$self_target"
                echo "Linked: $self_target -> $REPO_DIR/dots.sh"
                ((++count))
            fi
        elif [[ ! -e "$self_target" ]]; then
            ln -s "$REPO_DIR/dots.sh" "$self_target"
            echo "Linked: $self_target -> $REPO_DIR/dots.sh"
            ((++count))
        fi
    elif [[ ! -L "$self_target" && ! -e "$self_target" ]] || \
         { [[ -L "$self_target" ]] && [[ "$(readlink "$self_target")" != "$REPO_DIR/dots.sh" ]]; }; then
        echo "[DRY RUN] $self_target -> $REPO_DIR/dots.sh"
        ((++count))
    fi

    $dry_run && echo "[DRY RUN] Would create $count symlinks."
    return 0
}

cmd_check() {
    local interactive=false
    local profile_override=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --interactive|-i) interactive=true; shift ;;
            --profile) [[ $# -ge 2 ]] && { profile_override="$2"; shift 2; } || { echo "Error: --profile requires a name." >&2; exit 1; } ;;
            *) shift ;;
        esac
    done

    load_profile
    [[ -n "$profile_override" ]] && ACTIVE_PROFILE="$profile_override"
    load_dotsignore

    local file rel tgt entry lt rp
    local unlinked=()
    local untracked=()

    # Build tracked set (shared + profile)
    declare -A tracked
    while IFS= read -r -d '' file; do
        rel="${file#$REPO_DIR/}"
        ! should_include "$rel" && continue
        tracked["$file"]=1
    done < <(get_shared_files)

    if [[ -n "$ACTIVE_PROFILE" ]]; then
        local prof_dir="$REPO_DIR/profiles/$ACTIVE_PROFILE"
        while IFS= read -r -d '' file; do
            rel="${file#$prof_dir/}"
            ! should_include "$rel" && continue
            tracked["$file"]=1
        done < <(get_profile_files "$ACTIVE_PROFILE")
    fi

    # ── List 1: non-linked files (tracked in repo but not symlinked) ──
    for file in "${!tracked[@]}"; do
        if [[ "$file" == "$REPO_DIR/profiles/"* ]]; then
            rel="${file#$REPO_DIR/profiles/$ACTIVE_PROFILE/}"
        else
            rel="${file#$REPO_DIR/}"
        fi
        tgt=$(to_target_path "$rel")
        if [[ -L "$tgt" ]]; then
            lt=$(readlink "$tgt")
            [[ "$lt" == "$file" ]] && continue
        fi
        unlinked+=("$rel")
    done

    # ── List 2: untracked files ──
    local -A top_targets
    local mapping tn
    for mapping in "${DIR_MAPPINGS[@]}"; do
        tn="${mapping#*:}"
        top_targets["$HOME/$tn"]=1
    done

    declare -A target_dirs
    for file in "${!tracked[@]}"; do
        if [[ "$file" == "$REPO_DIR/profiles/"* ]]; then
            rel="${file#$REPO_DIR/profiles/$ACTIVE_PROFILE/}"
        else
            rel="${file#$REPO_DIR/}"
        fi
        tgt=$(to_target_path "$rel")
        tgt_dir=$(dirname "$tgt")
        [[ -n "${top_targets[$tgt_dir]:-}" ]] && continue
        target_dirs["$tgt_dir"]=1
    done

    local dir
    for dir in "${!target_dirs[@]}"; do
        [[ -d "$dir" ]] || continue
        [[ "$dir" == "$HOME/.local/bin" ]] && continue

        while IFS= read -r -d '' entry; do
            [[ -f "$entry" || -L "$entry" ]] || continue

            if [[ -L "$entry" ]]; then
                lt=$(readlink "$entry")
                [[ "$lt" == "$REPO_DIR"* ]] && continue
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
            read -rp "Add '$f' to the repo? [Y/n] " yn
            case "$yn" in
                [Nn]*) ;;
                *) cmd_add "$f" ;;
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
            --) shift; target_file="$1"; shift ;;
            *)  target_file="$1"; shift ;;
        esac
    done

    [[ -z "$target_file" ]] && { echo "Error: add requires a file path." >&2; exit 1; }
    [[ -f "$target_file" || -L "$target_file" ]] || {
        echo "Error: $target_file does not exist." >&2
        exit 1
    }

    if [[ -L "$target_file" ]]; then
        local real_f
        real_f=$(readlink -f "$target_file")
        if [[ "$real_f" == "$REPO_DIR"* ]]; then
            echo "Error: $target_file is already managed by this repo." >&2
            exit 1
        fi
    fi

    local repo_rel repo_full
    repo_rel=$(to_repo_path "$target_file")

    if [[ -n "$profile_name" ]]; then
        repo_full="$REPO_DIR/profiles/$profile_name/$repo_rel"
    else
        repo_full="$REPO_DIR/$repo_rel"
    fi

    if [[ -e "$repo_full" ]]; then
        echo "Error: $repo_full already exists." >&2
        exit 1
    fi

    mkdir -p "$(dirname "$repo_full")"

    cp "$target_file" "$repo_full"
    [[ -x "$target_file" ]] && chmod +x "$repo_full"

    rm -f "$target_file"
    ln -s "$repo_full" "$target_file"
    echo "Added: $target_file -> $repo_full"
}

cmd_ignore() {
    local raw_path=""
    local profile_name=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --profile) [[ $# -ge 2 ]] && { profile_name="$2"; shift 2; } || { echo "Error: --profile requires a name." >&2; exit 1; } ;;
            --) shift; raw_path="$1"; shift ;;
            *)  raw_path="$1"; shift ;;
        esac
    done

    [[ -z "$raw_path" ]] && { echo "Error: ignore requires a file path." >&2; exit 1; }

    local expanded="${raw_path/#\~/$HOME}"
    expanded="${expanded%/}"
    local dir dir_abs base abs_path
    dir="$(dirname "$expanded")"
    dir_abs="$(realpath "$dir" 2>/dev/null)" || {
        echo "Error: cannot resolve path '$raw_path'." >&2
        exit 1
    }
    base="$(basename "$expanded")"
    abs_path="$dir_abs/$base"

    [[ "$abs_path" == "$HOME"* ]] || {
        echo "Error: path '$raw_path' is not under \$HOME ($HOME)." >&2
        exit 1
    }

    local home_rel="${abs_path#$HOME/}"

    local ignore_file="$DOTSIGNORE_FILE"
    if [[ -n "$profile_name" ]]; then
        ignore_file="$REPO_DIR/profiles/$profile_name/.dotsignore"
        [[ -d "$(dirname "$ignore_file")" ]] || mkdir -p "$(dirname "$ignore_file")"
    fi

    # Load relevant ignores for duplicate check
    DOTSIGNORE_PATHS=()
    if [[ -f "$ignore_file" ]]; then
        local line
        while IFS= read -r line || [[ -n "$line" ]]; do
            line="${line%%#*}"
            line="${line#"${line%%[![:space:]]*}"}"
            line="${line%"${line##*[![:space:]]}"}"
            [[ -z "$line" ]] && continue
            DOTSIGNORE_PATHS+=("$line")
        done < "$ignore_file"
    fi

    local pattern
    for pattern in "${DOTSIGNORE_PATHS[@]}"; do
        [[ "$pattern" == "$home_rel" ]] && {
            echo "Already ignored: $home_rel"
            return 0
        }
    done

    if [[ -f "$ignore_file" ]]; then
        local file_end
        file_end="$(tail -c 1 "$ignore_file"; echo x)"
        file_end="${file_end%x}"
        [[ "$file_end" == $'\n' ]] || printf '\n' >> "$ignore_file"
    fi
    echo "$home_rel" >> "$ignore_file"
    echo "Added to .dotsignore: $home_rel"
}

cmd_unlink() {
    local dry_run=false restore=false

    for arg in "$@"; do
        case "$arg" in
            --dry-run) dry_run=true ;;
            --restore) restore=true ;;
        esac
    done

    local count=0 file rel tgt cur bak
    declare -A seen_targets

    # Shared files
    while IFS= read -r -d '' file; do
        rel="${file#$REPO_DIR/}"
        ! should_include "$rel" && continue
        tgt=$(to_target_path "$rel")
        [[ -n "${seen_targets[$tgt]:-}" ]] && continue
        seen_targets["$tgt"]=1

        [[ -L "$tgt" ]] || continue
        cur=$(readlink "$tgt")
        [[ "$cur" != "$file" ]] && continue

        bak="$tgt.bak"
        has_bak=false
        [[ -e "$bak" ]] && has_bak=true

        if $dry_run; then
            if $has_bak && $restore; then
                echo "[DRY RUN] Remove $tgt, restore $bak"
            else
                echo "[DRY RUN] Remove $tgt"
            fi
            ((++count))
            continue
        fi

        rm "$tgt"

        if $has_bak && $restore; then
            mv "$bak" "$tgt"
            echo "Restored: $tgt <- $bak"
        else
            echo "Removed: $tgt"
        fi
        ((++count))
    done < <(get_shared_files)

    # All profiles
    if [[ -d "$REPO_DIR/profiles" ]]; then
        local prof profile_dir
        while IFS= read -r -d '' prof; do
            profile_dir="$(basename "$prof")"
            while IFS= read -r -d '' file; do
                rel="${file#$prof/}"
                ! should_include "$rel" && continue
                tgt=$(to_target_path "$rel")
                [[ -n "${seen_targets[$tgt]:-}" ]] && continue
                seen_targets["$tgt"]=1

                [[ -L "$tgt" ]] || continue
                cur=$(readlink "$tgt")
                [[ "$cur" != "$file" ]] && continue

                bak="$tgt.bak"
                has_bak=false
                [[ -e "$bak" ]] && has_bak=true

                if $dry_run; then
                    if $has_bak && $restore; then
                        echo "[DRY RUN] Remove $tgt, restore $bak"
                    else
                        echo "[DRY RUN] Remove $tgt"
                    fi
                    ((++count))
                    continue
                fi

                rm "$tgt"

                if $has_bak && $restore; then
                    mv "$bak" "$tgt"
                    echo "Restored: $tgt <- $bak"
                else
                    echo "Removed: $tgt"
                fi
                ((++count))
            done < <(get_profile_files "$profile_dir")
        done < <(find "$REPO_DIR/profiles" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
    fi

    $dry_run && echo "[DRY RUN] Would remove $count symlinks."
}

cmd_diff() {
    git -C "$REPO_DIR" diff "$@"
}

cmd_status() {
    git -C "$REPO_DIR" status
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
                    echo "  $(basename "$p")"
                    found=true
                fi
            done
            $found || echo "  (none)"
            ;;
        set)
            local name="${2:-}"
            [[ -z "$name" ]] && { echo "Error: profile set requires a name." >&2; exit 1; }
            if [[ -d "$REPO_DIR/profiles/$name" ]]; then
                mkdir -p "$PROFILE_DIR"
                echo "$name" > "$PROFILE_FILE"
                ACTIVE_PROFILE="$name"
                echo "Switched to profile: $name"
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

case "${1:-}" in
    link)   shift; cmd_link "${@:-}" ;;
    unlink) shift; cmd_unlink "${@:-}" ;;
    check)  shift; cmd_check "${@:-}" ;;
    add)    shift; cmd_add "${@:-}" ;;
    ignore) shift; cmd_ignore "${@:-}" ;;
    profile) shift; cmd_profile "${@:-}" ;;
    diff)    shift; cmd_diff "$@" ;;
    status)  cmd_status ;;
    help|--help|-h) usage ;;
    *)     echo "Unknown command: $1"; usage ;;
esac
