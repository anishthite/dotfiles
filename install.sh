#!/usr/bin/env bash
# Dotfiles installer — symlinks files from this repo into $HOME.
# Usage:
#   ./install.sh           # symlink everything (backs up existing files to ~/.dotfiles-backup-<ts>)
#   ./install.sh --dry-run # show what would happen
#   ./install.sh --brew    # also run `brew bundle` after linking
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$DOTFILES_DIR/home"
DEST="$HOME"
BACKUP="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

DRY_RUN=0
DO_BREW=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --brew)    DO_BREW=1 ;;
    -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
  esac
done

log() { printf '\033[1;34m[dotfiles]\033[0m %s\n' "$*"; }

# Ensure submodules are initialized — Vundle and alacritty themes live there.
if [ -f "$DOTFILES_DIR/.gitmodules" ] && [ "$DRY_RUN" -eq 0 ]; then
  if command -v git >/dev/null 2>&1; then
    (cd "$DOTFILES_DIR" && git submodule update --init --recursive --quiet) && log "submodules ready"
  fi
fi

link_one() {
  local src="$1" rel="$2"
  local dst="$DEST/$rel"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    log "ok    $rel"
    return
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      log "would back up + link $rel"
      return
    fi
    mkdir -p "$BACKUP/$(dirname "$rel")"
    mv "$dst" "$BACKUP/$rel"
    log "backed up $rel -> $BACKUP/$rel"
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    log "would link $rel"
  else
    ln -s "$src" "$dst"
    log "linked $rel"
  fi
}

# Top-level dotfiles in home/
while IFS= read -r -d '' f; do
  rel="${f#$SRC/}"
  link_one "$f" "$rel"
done < <(find "$SRC" -mindepth 1 -maxdepth 1 ! -name '.config' -print0)

# .config subdirs — link each subdir individually so existing ~/.config stays usable
if [ -d "$SRC/.config" ]; then
  while IFS= read -r -d '' d; do
    rel=".config/$(basename "$d")"
    link_one "$d" "$rel"
  done < <(find "$SRC/.config" -mindepth 1 -maxdepth 1 -print0)
fi

if [ "$DO_BREW" -eq 1 ] && [ "$DRY_RUN" -eq 0 ]; then
  if ! command -v brew >/dev/null 2>&1; then
    log "installing Homebrew…"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  log "running brew bundle…"
  brew bundle --file="$DOTFILES_DIR/Brewfile"
fi

log "done. backups (if any) in $BACKUP"
