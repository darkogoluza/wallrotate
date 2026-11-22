#!/usr/bin/env bash
# Install (or update) wallrotate to ~/.local/bin, offering to install missing dependencies.
#   curl -fsSL <raw-url>/install.sh | bash              ask before installing packages
#   curl -fsSL <raw-url>/install.sh | bash -s -- --yes  install missing packages without asking
# Also works as ./install.sh from a checkout. Only the program is installed.
set -euo pipefail

RAW_URL="${WALLROTATE_URL:-https://raw.githubusercontent.com/darkogoluza/wallrotate/main}"
BIN="$HOME/.local/bin"
# run from a checkout: use the file next to this script; piped from curl: download it
LOCAL=""; [[ -n "${BASH_SOURCE[0]:-}" && -f "$(dirname "${BASH_SOURCE[0]}")/wallrotate" ]] &&
  LOCAL="$(dirname "${BASH_SOURCE[0]}")/wallrotate"
# piped from curl, stdin is this script: questions and package managers must read the terminal
if [[ -t 0 ]]; then TTY=/dev/stdin
elif (exec </dev/tty) 2>/dev/null; then TTY=/dev/tty
else TTY=""; fi  # no terminal at all: don't ask (packages only with --yes)
YES=false; [[ "${1:-}" == "--yes" ]] && YES=true
OS_RELEASE="${OS_RELEASE:-/etc/os-release}"  # overridable for testing
DRY_RUN="${DRY_RUN:-}"                        # set to print package commands instead of running them

say() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
run() { if [[ -n "$DRY_RUN" ]]; then echo "would run: $*"; else "$@" <"${TTY:-/dev/null}"; fi; }

# ---------- which distro family ----------
family=unknown
if [[ -r "$OS_RELEASE" ]]; then
  ids=$(. "$OS_RELEASE"; echo " ${ID:-} ${ID_LIKE:-} ")
  case "$ids" in
    *" arch "*) family=arch ;;
    *" debian "* | *" ubuntu "*) family=debian ;;
    *" fedora "* | *" rhel "*) family=fedora ;;
    *" suse "* | *" opensuse "*) family=suse ;;
  esac
fi

# package names to try for each command, per family (first available wins)
candidates() {  # $1 = command
  case "$family:$1" in
    arch:python3) echo python ;;
    fedora:ffmpeg) echo "ffmpeg ffmpeg-free" ;;  # full ffmpeg needs RPM Fusion; ffmpeg-free is in Fedora
    *) echo "$1" ;;
  esac
}

available() {  # is package $1 in the distro's repositories?
  case "$family" in
    arch) pacman -Si "$1" &>/dev/null ;;
    debian) [[ -n "$(apt-cache policy "$1" 2>/dev/null | awk '/Candidate:/ && $2 != "(none)"')" ]] ;;
    fedora) dnf -q info "$1" &>/dev/null ;;
    suse) zypper -q info "$1" 2>/dev/null | grep -q "^Name" ;;
    *) return 1 ;;
  esac
}

install_pkgs() {
  case "$family" in
    arch) run sudo pacman -S --needed "${YESFLAG[@]}" "$@" ;;
    debian) run sudo apt-get install "${YESFLAG[@]}" "$@" ;;
    fedora) run sudo dnf install "${YESFLAG[@]}" "$@" ;;
    suse) run sudo zypper install "${YESFLAG[@]}" "$@" ;;
  esac
}

aur_helper() { for h in paru yay; do command -v "$h" >/dev/null && { echo "$h"; return; }; done; }

# ---------- dependencies ----------
missing=()
for cmd in python3 awww mpvpaper ffmpeg; do
  command -v "$cmd" >/dev/null || missing+=("$cmd")
done

if ((${#missing[@]})); then
  say "missing: ${missing[*]}  (distro: $family)"
  repo_pkgs=() aur_pkgs=() manual=()
  for cmd in "${missing[@]}"; do
    pkg=""
    for c in $(candidates "$cmd"); do available "$c" && { pkg=$c; break; }; done
    if [[ -n "$pkg" ]]; then repo_pkgs+=("$pkg")
    elif [[ $family == arch && -n "$(aur_helper)" ]]; then aur_pkgs+=("$cmd")
    else manual+=("$cmd"); fi
  done

  todo="${repo_pkgs[*]} ${aur_pkgs[*]}"
  if [[ -n "${todo// }" ]]; then
    answer=y
    if ! $YES; then
      if [[ -n "$TTY" ]]; then read -rp ":: install ${todo## } now? [Y/n] " answer <"$TTY" || answer=n
      else answer=n; fi
    fi
    if [[ "${answer:-y}" =~ ^[Yy]?$ ]]; then
      YESFLAG=(); $YES && case "$family" in arch) YESFLAG=(--noconfirm) ;; suse) YESFLAG=(-n) ;; *) YESFLAG=(-y) ;; esac
      ((${#repo_pkgs[@]})) && install_pkgs "${repo_pkgs[@]}"
      ((${#aur_pkgs[@]})) && run "$(aur_helper)" -S --needed "${YESFLAG[@]}" "${aur_pkgs[@]}"
    else
      DRY_RUN=1 YESFLAG=()  # print the commands so they can be run later
      warn "skipped; to install later:"
      ((${#repo_pkgs[@]})) && install_pkgs "${repo_pkgs[@]}" | sed 's/^would run: /   /'
      ((${#aur_pkgs[@]})) && run "$(aur_helper)" -S --needed "${aur_pkgs[@]}" | sed 's/^would run: /   /'
      DRY_RUN=""
    fi
  fi

  for cmd in "${manual[@]}"; do
    case "$cmd" in
      awww) warn "awww: not packaged here; build it from https://codeberg.org/LGFae/awww" ;;
      mpvpaper) warn "mpvpaper: not packaged here; build it from https://github.com/GhostNaN/mpvpaper" ;;
      *) warn "$cmd: install it with your package manager" ;;
    esac
  done
  if [[ -z "$DRY_RUN" ]] && ! command -v python3 >/dev/null; then
    warn "python3 is required, aborting"; exit 1
  fi
fi

# ---------- program ----------
mkdir -p "$BIN"
if [[ -n "$LOCAL" ]]; then
  install -m 755 "$LOCAL" "$BIN/wallrotate"
else
  tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
  curl -fsSL "$RAW_URL/wallrotate" -o "$tmp" || { warn "download failed: $RAW_URL/wallrotate"; exit 1; }
  head -1 "$tmp" | grep -q python3 || { warn "download is not the wallrotate script: $RAW_URL"; exit 1; }
  install -m 755 "$tmp" "$BIN/wallrotate"
fi
say "installed $BIN/wallrotate"
case ":$PATH:" in *":$BIN:"*) ;; *) warn "$BIN is not in your PATH" ;; esac
