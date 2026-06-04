# dotfiles

My personal macOS dotfiles. Shell, editor, window manager, and a Brewfile.

## What's in here

```
home/                       # everything here gets symlinked into $HOME
  .zshrc .zprofile .zshenv
  .gitconfig
  .vimrc .tmux.conf
  .yabairc .skhdrc          # window manager + hotkeys
  .bash_profile .profile
  .config/
    nvim/ alacritty/ ghostty/
    sketchybar/ skhd/ htop/
    gh/ zed/
Brewfile                    # `brew bundle` to reinstall apps + CLIs
install.sh                  # symlink installer
```

Secrets are deliberately excluded: no `.ssh`, `.aws`, `.env`, `.npmrc`, `.gemini`, `.copilot`, `.claude.json`, `gh/hosts.yml`, etc.

## Quick start on a new Mac

```bash
# 1. Install Xcode CLT + Homebrew (Homebrew bootstraps git)
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Clone
git clone --recurse-submodules https://github.com/anishthite/dotfiles.git ~/workspace/dotfiles
cd ~/workspace/dotfiles

# 3. Symlink dotfiles + install Brewfile
./install.sh --brew
```

That's it. Open a new shell.

## Other useful commands

```bash
./install.sh --dry-run    # preview what would link
./install.sh              # symlink only, skip brew
brew bundle dump --force  # regenerate Brewfile from what's currently installed

# If you forgot --recurse-submodules at clone time:
git submodule update --init --recursive
```

Existing files in `$HOME` are moved to `~/.dotfiles-backup-<timestamp>/` before symlinking — nothing is overwritten silently.

## After install — manual bits

- Sign in to `gh` again: `gh auth login`
- Sign in to apps that store creds outside the dotfile tree (1Password, Raycast, etc.)
- Configure `~/.ssh/` keys (intentionally not in repo)
