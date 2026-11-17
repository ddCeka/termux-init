#!/usr/bin/env bash
set -euo pipefail

# Guardrail: Ensure script is running inside Termux
if [[ -z "${TERMUX_VERSION:-}" && "${PREFIX:-}" != *"/com.termux/"* ]]; then
    echo "Error: Run this script only in Termux." >&2
    exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE}")" && pwd)"
LOCAL_REPO="$HOME/.local/packages"
CLEANER="$HOME/bin/termux-junk-cleaner"
LOG_DIR="$HOME/.cache"
LOG_FILE="$LOG_DIR/termux-init-$(date +%Y%m%d-%H%M%S).log"

WAKELOCK_ACTIVE=false
AUTO_YES=false
SKIP_LOCAL=false
DRY_RUN=false

display_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -y, --yes      Auto-accept all prompts
  --skip-local   Skip local python & pkg files
  -d, --dry-run  Preview commands without running
  -h, --help     Show this help message

Examples:
  $(basename "$0") -y
  $(basename "$0") -y -d --skip-local
EOF
}

# Parse CLI flags
for arg in "$@"; do
    case "$arg" in
        -y | --yes)
            AUTO_YES=true
            ;;
        --skip-local)
            SKIP_LOCAL=true
            ;;
        -d | --dry-run)
            DRY_RUN=true
            ;;
        -h | --help)
            display_help
            exit 0
            ;;
        *)
            echo "Unknown option: $arg" >&2
            echo "Use -h or --help for usage." >&2
            exit 1
            ;;
    esac
done

# Ensure ~/.cache exists and mirror stdout/stderr without ANSI codes
mkdir -p "$LOG_DIR"
exec > >(tee >(sed -u -r 's/\x1B\[[0-9;]*[mK]//g' >>"$LOG_FILE")) 2>&1

# Colours helper
cecho() {
    local code="\033[" color=""
    case "$1" in
        black | bk) color="${code}0;30m" ;;
        red | r) color="${code}1;31m" ;;
        green | g) color="${code}1;32m" ;;
        yellow | y) color="${code}0;33m" ;;
        blue | b) color="${code}0;34m" ;;
        purple | p) color="${code}0;35m" ;;
        cyan | c) color="${code}0;36m" ;;
        gray | gr) color="${code}0;37m" ;;
        *)
            echo -e "$1"
            return
            ;;
    esac
    echo -e "${color}${2}${code}0m"
}

# Execute command or print compact preview in dry-run mode
run() {
    if [[ "$DRY_RUN" == true ]]; then
        cecho y "  [dry] $*"
    else
        "$@"
    fi
}

# Reusable Y/N prompt (auto-approves if -y/--yes is passed)
ask() {
    local prompt="$1"
    local color="${2:-g}"
    if [[ "$AUTO_YES" == true ]]; then
        cecho "$color" "\n► ${prompt} [yes]"
        return 0
    fi
    local reply
    cecho "$color" "\n► ${prompt} [y/N]: "
    read -r -n 1 reply
    echo
    [[ "$reply" =~ ^[Yy]$ ]]
}

# Read non-comment, non-empty lines from one or more files safely
read_pkg_lists() {
    local file
    for file in "$@"; do
        [[ -f "$file" ]] || continue
        grep -Ev '^\s*(#|$)' "$file" || true
    done
}

# Ensure wakelock is released if script exits unexpectedly
cleanup_on_exit() {
    if [[ "$WAKELOCK_ACTIVE" == true ]]; then
        run termux-wake-unlock || true
    fi
    cecho c "\n► Log saved:\n  $LOG_FILE"
}
trap cleanup_on_exit EXIT

# Detect package manager (Termux uses either apt or pacman)
if command -v apt >/dev/null 2>&1; then
    PKG_MANAGER="apt"
else
    PKG_MANAGER="pacman"
fi

cecho c "► Log file:\n  $LOG_FILE"
[[ "$DRY_RUN" == true ]] && cecho c "► DRY-RUN mode active (preview only)\n"

# 1. Storage & Wakelock
if ask "Give storage access?"; then
    run termux-setup-storage
fi

if ask "Turn on wakelock?"; then
    run termux-wake-lock
    WAKELOCK_ACTIVE=true
fi

# 2. Repository configuration (skipped in --yes mode since it opens a TUI/editor)
if [[ "$AUTO_YES" == false ]] && ask "Change repo?"; then
    if [[ "$PKG_MANAGER" == "apt" ]]; then
        run termux-change-repo
    else
        run "${EDITOR:-nano}" "$PREFIX/etc/pacman.conf"
    fi
fi

# 3. System update
if ask "Start full system update?"; then
    run pkg update && run pkg upgrade -y
fi

# 4. APT-specific additional repos
if [[ "$PKG_MANAGER" == "apt" ]]; then
    if [[ -f "$SCRIPT_DIR/repo.txt" ]] && ask "Add extra repos from repo.txt?"; then
        mapfile -t repos < <(read_pkg_lists "$SCRIPT_DIR/repo.txt")
        if ((${#repos[@]} > 0)); then
            run pkg install -y "${repos[@]}"
        else
            cecho y "► No active repos in repo.txt."
        fi
    fi

    if [[ -f "$SCRIPT_DIR/tur.list" ]] && ask "Copy tur.list to sources.list.d?" "r"; then
        run cp "$SCRIPT_DIR/tur.list" "$PREFIX/etc/apt/sources.list.d/"
        run pkg update && run pkg upgrade -y
    fi
fi

# 5. Merged package installation (pkg-common.txt + pkg-<manager>.txt)
COMMON_FILE="$SCRIPT_DIR/pkg-common.txt"
SPECIFIC_FILE="$SCRIPT_DIR/pkg-${PKG_MANAGER}.txt"

if { [[ -f "$COMMON_FILE" ]] || [[ -f "$SPECIFIC_FILE" ]]; } && ask "Install necessary packages?"; then
    mapfile -t pkgs < <(read_pkg_lists "$COMMON_FILE" "$SPECIFIC_FILE")
    if ((${#pkgs[@]} > 0)); then
        if [[ "$PKG_MANAGER" == "apt" ]]; then
            run pkg install -y "${pkgs[@]}"
        else
            run pacman -S --noconfirm --needed "${pkgs[@]}"
        fi
    else
        cecho y "► Package lists are empty."
    fi
fi

if [[ "$PKG_MANAGER" == "pacman" ]] && ask "Install base-devel package?"; then
    run pacman -S --noconfirm --needed base-devel
fi

# 6. Local Python & Offline Packages (skipped if --skip-local is passed)
if [[ "$SKIP_LOCAL" == false ]]; then
    if ask "Install local python packages?"; then
        if [[ -f "$SCRIPT_DIR/requirements.txt" ]]; then
            pip_args=(--no-cache-dir -r "$SCRIPT_DIR/requirements.txt")
            [[ -d "$LOCAL_REPO/python" ]] && pip_args=(--find-links="$LOCAL_REPO/python" "${pip_args[@]}")
            run pip install "${pip_args[@]}"
        fi
        if [[ -f "$LOCAL_REPO/python/unrpyc-1.3.2.tar.gz" ]] && command -v pip2 >/dev/null 2>&1; then
            run pip2 install "$LOCAL_REPO/python/unrpyc-1.3.2.tar.gz"
        fi
    fi

    if ask "Install local packages?"; then
        shopt -s nullglob
        if [[ "$PKG_MANAGER" == "apt" ]]; then
            debs=("$LOCAL_REPO/debian/"*.deb)
            if ((${#debs[@]} > 0)); then
                run dpkg -i "${debs[@]}" || run apt-get install -f -y
            else
                cecho y "► No .deb files in:\n  $LOCAL_REPO/debian/"
            fi
        else
            zst_pkgs=("$LOCAL_REPO/pacman/"*.pkg.tar.*)
            if ((${#zst_pkgs[@]} > 0)); then
                run pacman -U --noconfirm "${zst_pkgs[@]}"
            else
                cecho y "► No packages in:\n  $LOCAL_REPO/pacman/"
            fi
        fi
        shopt -u nullglob
    fi
fi

# 7. Cache & junk cleanup
if ask "Clean package caches?"; then
    if [[ "$PKG_MANAGER" == "apt" ]]; then
        run pkg autoclean && run pkg clean
    else
        if [[ "$DRY_RUN" == true ]]; then
            cecho y "  [dry] yes | pacman -Scc"
        else
            yes | pacman -Scc || true
        fi
    fi
    command -v pip >/dev/null 2>&1 && run pip cache purge || true
fi

if [[ -f "$CLEANER" ]] && ask "Run termux-junk-cleaner?"; then
    run bash "$CLEANER" -y
fi

# 8. Release wakelock
if [[ "$WAKELOCK_ACTIVE" == true ]] && ask "Turn off wakelock?"; then
    run termux-wake-unlock
    WAKELOCK_ACTIVE=false
fi

cecho c "\n► Init completed.\n"
