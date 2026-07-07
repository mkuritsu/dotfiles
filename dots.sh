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
)

# Linux-only directories (relative to repo root)
LINUX_ONLY_PATHS=(
    "config/hypr"
    "config/uwsm"
    "config/vicinae"
)

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME <command> [options]

Commands:
  link              Create symlinks for all tracked files in \$HOME
  unlink            Remove symlinks created by link (restores .bak files)
  check             List files in linked directories not tracked in the repo
  add <file>        Copy a file into the repo and replace it with a symlink
  ignore <path>     Resolve path and add it to .dotsignore
  help              Show this help message

Options:
  --dry-run         For link/unlink: show what would be done without doing it
  --restore         For unlink: restore .bak files when removing symlinks
  --interactive, -i For check: prompt before adding each untracked file
EOF
    exit 1
}

# ─── Dotsignore ───────────────────────────────────────────────

DOTSIGNORE_FILE="$REPO_DIR/.dotsignore"
DOTSIGNORE_PATHS=()

load_dotsignore() {
    DOTSIGNORE_PATHS=()
    if [[ -f "$DOTSIGNORE_FILE" ]]; then
        local line
        while IFS= read -r line || [[ -n "$line" ]]; do
            line="${line%%#*}"        # strip comments
            line="${line#"${line%%[![:space:]]*}"}"  # trim leading
            line="${line%"${line##*[![:space:]]}"}"  # trim trailing
            [[ -z "$line" ]] && continue
            DOTSIGNORE_PATHS+=("$line")
        done < "$DOTSIGNORE_FILE"
    fi
}

is_ignored() {
    local target_path="$1"   # absolute target path
    local repo_rel="$2"      # repo-relative path
    local home_rel="${target_path#$HOME/}"  # $HOME-relative path
    local pattern
    for pattern in "${DOTSIGNORE_PATHS[@]}"; do
        local pat="${pattern%/}"
        # Match against repo-relative, $HOME-relative, or absolute
        if [[ "$repo_rel" == "$pat" || "$repo_rel" == "$pat"/* ]] || \
           [[ "$home_rel" == "$pat" || "$home_rel" == "$pat"/* ]] || \
           [[ "$target_path" == "$pat" ]]; then
            return 0
        fi
    done
    return 1
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

# Repo-relative path → $HOME-absolute target path
to_target_path() {
    local repo_rel="$1"
    local first="${repo_rel%%/*}"
    local rest=""
    [[ "$first" != "$repo_rel" ]] && rest="${repo_rel#*/}"

    # Map first component using DIR_MAPPINGS
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

# Process path components: strip prefixes, apply dot_ → .
process_path_components() {
    local path="$1"
    local result="" part
    IFS='/' read -ra parts <<< "$path"
    for part in "${parts[@]}"; do
        result="${result}/${part}"
    done
    echo "${result#/}"
}

# $HOME-absolute target path → repo-relative path
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
    local dry_run=false
    [[ "${1:-}" == "--dry-run" ]] && dry_run=true

    local count=0 file rel tgt tgt_dir cur
    while IFS= read -r -d '' file; do
        rel="${file#$REPO_DIR/}"
        ! should_include "$rel" && continue

        tgt=$(to_target_path "$rel")
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
            echo "Warning: $tgt links to $cur (expected $file). Skipping."
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
    done < <(find "$REPO_DIR" -type f ! -path '*/.git/*' ! -name "$SCRIPT_NAME" ! -name '.dotsignore' ! -name 'README.md' -print0)

    # Symlink this script into ~/.local/bin/dots
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
}

cmd_check() {
    local interactive=false
    [[ "${1:-}" == "--interactive" || "${1:-}" == "-i" ]] && interactive=true

    load_dotsignore

    local file rel tgt tgt_dir entry lt rp
    local unlinked=()
    local untracked=()

    # ── List 1: non-linked files (tracked in repo but not symlinked) ──
    while IFS= read -r -d '' file; do
        rel="${file#$REPO_DIR/}"
        ! should_include "$rel" && continue
        tgt=$(to_target_path "$rel")

        if [[ -L "$tgt" ]]; then
            lt=$(readlink "$tgt")
            [[ "$lt" == "$file" ]] && continue
        fi
        unlinked+=("$rel")
    done < <(find "$REPO_DIR" -type f ! -path '*/.git/*' ! -name "$SCRIPT_NAME" ! -name '.dotsignore' ! -name 'README.md' -print0)

    # ── List 2: untracked files (in target dirs, not in repo) ──
    local -A top_targets
    local mapping tn
    for mapping in "${DIR_MAPPINGS[@]}"; do
        tn="${mapping#*:}"
        top_targets["$HOME/$tn"]=1
    done

    # Collect subdirectories that contain tracked files (skip top-level dirs)
    declare -A target_dirs
    while IFS= read -r -d '' file; do
        rel="${file#$REPO_DIR/}"
        ! should_include "$rel" && continue
        tgt=$(to_target_path "$rel")
        tgt_dir=$(dirname "$tgt")
        [[ -n "${top_targets[$tgt_dir]:-}" ]] && continue
        target_dirs["$tgt_dir"]=1
    done < <(find "$REPO_DIR" -type f ! -path '*/.git/*' ! -name "$SCRIPT_NAME" ! -name '.dotsignore' ! -name 'README.md' -print0)

    local -A seen
    local dir d
    for dir in "${!target_dirs[@]}"; do
        [[ -d "$dir" ]] || continue
        while IFS= read -r -d '' d; do
            [[ -n "${seen[$d]:-}" ]] && continue
            [[ -n "${top_targets[$d]:-}" ]] && continue
            seen[$d]=1

            while IFS= read -r -d '' entry; do
                [[ -f "$entry" || -L "$entry" ]] || continue

                # Symlink into the repo ➜ tracked
                if [[ -L "$entry" ]]; then
                    lt=$(readlink "$entry")
                    [[ "$lt" == "$REPO_DIR"* ]] && continue
                fi

                # Corresponding repo file exists ➜ tracked
                rp=$(to_repo_path "$entry")
                [[ -f "$REPO_DIR/$rp" ]] && continue

                # Check if ignored via .dotsignore
                is_ignored "$entry" "$rp" && continue

                untracked+=("$entry")
            done < <(find "$d" -maxdepth 1 \( -type f -o -type l \) -print0 2>/dev/null)
        done < <(find "$dir" -type d -print0 2>/dev/null)
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
    local target_file="$1"
    [[ -f "$target_file" || -L "$target_file" ]] || {
        echo "Error: $target_file does not exist." >&2
        exit 1
    }

    # Bail if already managed
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
    repo_full="$REPO_DIR/$repo_rel"

    if [[ -e "$repo_full" ]]; then
        echo "Error: $repo_full already exists." >&2
        exit 1
    fi

    mkdir -p "$(dirname "$repo_full")"

    # Copy content (follow symlinks to get the actual file)
    cp "$target_file" "$repo_full"
    [[ -x "$target_file" ]] && chmod +x "$repo_full"

    rm -f "$target_file"
    ln -s "$repo_full" "$target_file"
    echo "Added: $target_file -> $repo_full"
}

cmd_ignore() {
    local raw_path="${1:-}"
    [[ -z "$raw_path" ]] && { echo "Error: ignore requires a file path." >&2; exit 1; }

    # Expand ~ explicitly, resolve directory but not the final component
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

    load_dotsignore

    local pattern
    for pattern in "${DOTSIGNORE_PATHS[@]}"; do
        [[ "$pattern" == "$home_rel" ]] && {
            echo "Already ignored: $home_rel"
            return 0
        }
    done

    if [[ -f "$DOTSIGNORE_FILE" ]]; then
        local last_char
        last_char="$(tail -c 1 "$DOTSIGNORE_FILE")"
        [[ "$last_char" != $'\n' ]] && printf '\n' >> "$DOTSIGNORE_FILE"
    fi
    echo "$home_rel" >> "$DOTSIGNORE_FILE"
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
    while IFS= read -r -d '' file; do
        rel="${file#$REPO_DIR/}"
        ! should_include "$rel" && continue

        tgt=$(to_target_path "$rel")

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
    done < <(find "$REPO_DIR" -type f ! -path '*/.git/*' ! -name "$SCRIPT_NAME" ! -name '.dotsignore' ! -name 'README.md' -print0)

    $dry_run && echo "[DRY RUN] Would remove $count symlinks."
}

# ─── Main ───────────────────────────────────────────────────

[[ $# -lt 1 ]] && usage

case "${1:-}" in
    link)   shift; cmd_link "${@:-}" ;;
    unlink) shift; cmd_unlink "${@:-}" ;;
    check)  shift; cmd_check "${@:-}" ;;
    add)   shift; [[ $# -lt 1 ]] && { echo "Error: add requires a file path." >&2; exit 1; }; cmd_add "$@" ;;
    ignore) shift; [[ $# -lt 1 ]] && { echo "Error: ignore requires a file path." >&2; exit 1; }; cmd_ignore "$@" ;;
    help|--help|-h) usage ;;
    *)     echo "Unknown command: $1"; usage ;;
esac
