source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-history-substring-search/zsh-history-substring-search.zsh

zmodload zsh/terminfo
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down
bindkey '^[[A' history-substring-search-up			
bindkey '^[[B' history-substring-search-down


setopt appendhistory
setopt autocd

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'       # Case insensitive tab completion
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"         # Colored completion (different colors for dirs/files/etc)
zstyle ':completion:*' rehash true                              # automatically find new executables in path 
# Speed up completions
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

export EDITOR=/opt/homebrew/bin/nvim
export VISUAL=/opt/homebrew/bin/nvim

setopt autocd 
alias ..="cd .."
alias ...="cd ../.."

alias ll="ls -la --color=auto"
alias grep='grep --color=auto'
alias ip='ip -color=auto'
alias k='kubectl'
alias kd='kubectl describe'
alias kgp='kubectl get pods '

64d() {
  echo -n "$1" | base64 -d ;
}

64e() {
  echo -n "$1" | base64 ;
}


export less='less --use-color'

alias stack="./.screenlayout/stack.sh"
alias trips="./.screenlayout/trips.sh"
alias norm="xrandr -auto"
alias gtvm="sudo vmware-modconfig --console --install-all && vmware"
alias kvpn="sudo killall -SIGINT openconnect"
alias vim="nvim"
alias cunt="git"
alias v="vim"

eval "$(scmpuff init -s)"

function fuck() {
    n 
    git commit -m "$1"
}

alias nrd="npm run dev"
alias gits="git status"
alias cum="git push "


PS1='%n@%m %F{blue}% %~ %(?.%F{green}.%F{red})>>%f '

export NVM_DIR="$HOME/.nvm"
source /opt/homebrew/opt/nvm/nvm.sh

conda() {
  unfunction conda
  source /Users/anishthite/miniconda3/etc/profile.d/conda.sh
  conda "$@"
}

_load_emsdk() {
  unfunction _load_emsdk emcc em++ emar emranlib emmake emconfigure emcmake emsdk
  source /Users/anishthite/Documents/playscape/emsdk/emsdk_env.sh
}
emcc() { _load_emsdk; emcc "$@"; }
em++() { _load_emsdk; em++ "$@"; }
emar() { _load_emsdk; emar "$@"; }
emranlib() { _load_emsdk; emranlib "$@"; }
emmake() { _load_emsdk; emmake "$@"; }
emconfigure() { _load_emsdk; emconfigure "$@"; }
emcmake() { _load_emsdk; emcmake "$@"; }
emsdk() { _load_emsdk; emsdk "$@"; }

source $HOME/.cargo/env 
# Removed: node@18 was overriding nvm. Use `nvm use <version>` instead.
# export PATH="/opt/homebrew/opt/node@18/bin:$PATH"

# opencode
export PATH=/Users/anishthite/.opencode/bin:$PATH


# --- git worktree helpers (single-file .zshrc) ---

export W_BASE=staging


# Default parent folder for new worktrees:
#   - If W_ROOT is set, use it.
#   - Else, use the parent dir of the repo.
__w_default_root() {
  local top; top="$(git rev-parse --show-toplevel 2>/dev/null)" || return 1
  dirname "$top"
}

# Sanitize branch for folder names (feature/foo -> feature-foo)
__w_sanitize_branch() {
  echo "${1//\//-}"
}

# Build a directory for a branch using pattern:
#   W_PATTERN can override (ex: "wt/${repo}/${branch}")
__w_dir_for() {
  local br="$1"; local root="${2:-${W_ROOT:-$(__w_default_root)}}"
  local repo; repo="$(basename "$(git rev-parse --show-toplevel)")"
  local safe; safe="$(__w_sanitize_branch "$br")"
  local pattern="${W_PATTERN:-${repo}-${safe}}"
  echo "${root%/}/${pattern}"
}

# Detect default base branch (origin/HEAD -> main/master)


__w_default_base() {
  # 1) env override
  [[ -n "$W_BASE" ]] && { echo "$W_BASE"; return; }

  # 2) optional per-repo override (run: git config --local w.base staging)
  local cfg
  cfg="$(git config --get w.base 2>/dev/null)"
  [[ -n "$cfg" ]] && { echo "$cfg"; return; }

  # 3) fallback: origin/HEAD or main
  local def
  def="$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null | sed 's#^origin/##')"
  [[ -z "$def" ]] && def="main"
  echo "$def"
}

# Pretty list of worktrees
wls() {
  git worktree list --porcelain | /opt/homebrew/bin/awk '
    BEGIN {
      fmt="%-48s  %-18s  %s\n"
      printf fmt,"PATH","BRANCH","HEAD"
      printf "%s\n", gensub(/./,"-","g",sprintf("%*s",86,""))
    }
    /^worktree /{ path=$2 }
    /^branch /{ br=$2; gsub("^refs/heads/","",br) }
    /^HEAD /{ printf fmt, path, br, $2 }
  '
}

# cd into a worktree by branch or path
wcd() {
  local t="$1"
  [[ -z "$t" ]] && { echo "usage: wcd <branch|path>"; return 1; }
  if [[ -d "$t" ]]; then cd "$t" && pwd; return; fi
  local p
  p="$(git worktree list --porcelain | /opt/homebrew/bin/awk -v b="refs/heads/$t" '
       /^worktree /{p=$2} /^branch /{if($2==b){print p; exit}}')"
  [[ -n "$p" ]] && { cd "$p" && pwd; } || { echo "No worktree for '$t'"; return 1; }
}

# Add worktree for an EXISTING branch (fetch if only on origin)
wadd() {
  local br="$1"; local root="${2:-${W_ROOT:-$(__w_default_root)}}"
  [[ -z "$br" ]] && { echo "usage: wadd <branch> [root-dir]"; return 1; }
  if ! git show-ref --verify --quiet "refs/heads/$br"; then
    git fetch origin "$br:$br" || { echo "could not fetch '$br' from origin"; return 1; }
  fi
  local dir; dir="$(__w_dir_for "$br" "$root")"
  git worktree add "$dir" "$br" && echo "Created: $dir"
}

# Create NEW branch worktree off base (default: origin/<default head> or main)
wnew() {
  local newbr="$1"; local base="${2:-$(__w_default_base)}"; local root="${3:-${W_ROOT:-$(__w_default_root)}}"
  [[ -z "$newbr" ]] && { echo "usage: wnew <new-branch> [base-branch] [root-dir]"; return 1; }
  local dir; dir="$(__w_dir_for "$newbr" "$root")"
  git fetch origin "$base" >/dev/null 2>&1 || true
  git worktree add -b "$newbr" "$dir" "origin/$base" 2>/dev/null || \
  git worktree add -b "$newbr" "$dir" "$base" || return 1
  echo "Created new branch '$newbr' at: $dir"
  cd "$dir"
}


wrm() {
  local del_branch=0 force=""
  local args=()

  for a in "$@"; do
    case "$a" in
      -D) del_branch=1 ;;
      --force|-f) force="--force" ;;
      *) args+=("$a") ;;
    esac
  done

  if (( ${#args[@]} == 0 )); then
    echo "usage: wrm [-D] [--force] <branch|path>"; return 1
  fi

  local t="${args[1]}"

  # Resolve path if a branch name was given
  local path="$t"
  if [[ ! -d "$t" ]]; then
    if git show-ref --verify --quiet "refs/heads/$t"; then
      path="$(git worktree list --porcelain | /opt/homebrew/bin/awk -v b="refs/heads/$t" '
        /^worktree /{p=$2} /^branch /{if($2==b){print p; exit}}')"
      [[ -z "$path" ]] && { echo "No worktree for '$t'"; return 1; }
    else
      echo "Not a directory or branch: $t"; return 1
    fi
  fi

  # You can't remove the worktree you’re in
  local here; here="$(pwd -P)"
  if [[ "$here" == "$path"* ]]; then
    echo "You're inside $path. cd elsewhere and re-run."; return 1
  fi

  git worktree remove $force "$path" || return $?

  if (( del_branch )); then
    # If a branch name was provided, delete that; otherwise try to infer
    local br="$t"
    if [[ -d "$t" ]]; then
      br="$(git worktree list --porcelain | /opt/homebrew/bin/awk -v p="$path" '
        /^worktree /{w=$2} /^branch /{b=$2; sub("^refs/heads/","",b)} 
        w==p && /^branch /{print b; exit}')"
    fi
    [[ -n "$br" ]] && git branch -D "$br"
  fi
}

# Prune stale entries
wprune() { git worktree prune; }

# Open a worktree in VS Code by branch or path
wcode() {
  local t="$1"; [[ -z "$t" ]] && { echo "usage: wcode <branch|path>"; return 1; }
  command -v code >/dev/null || { echo "VS Code 'code' not found"; return 1; }
  if [[ -d "$t" ]]; then (cd "$t" && code .); else wcd "$t" && code .; fi
}

# Optional: fzf picker to cd into a worktree
wpick() {
  command -v fzf >/dev/null || { echo "fzf not installed"; return 1; }
  local p; p="$(git worktree list --porcelain | /opt/homebrew/bin/awk '/^worktree /{print $2}' | fzf)"
  [[ -n "$p" ]] && cd "$p" && pwd
}

# Convenience: show current worktree info
wcur() {
  local top; top="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "not in a git repo"; return 1; }
  echo "path:  $top"
  echo "branch: $(git rev-parse --abbrev-ref HEAD)"
  echo "head:   $(git rev-parse --short HEAD)"
}

# --- zsh completion (branches for wcd/wrm/wcode) ---
_w_worktree_branches() {
  local -a brs
  brs=("${(@f)$(git worktree list --porcelain 2>/dev/null | /opt/homebrew/bin/awk '/^branch /{sub("^refs/heads/","",$2); print $2}')}") 
  _describe -t branches 'worktree branches' brs
}
autoload -Uz compinit
compinit -C
compdef _w_worktree_branches wcd wrm wcode


# Create a worktree from a remote branch (supports namespaced branches like terragon/foo/bar)
wremote() {
  setopt localoptions noshwordsplit

  local remote="origin" localbr="" root="" path_override=""
  # ---- flags ----
  while [[ "$1" == -* ]]; do
    case "$1" in
      -r) remote="$2"; shift 2 ;;
      -b) localbr="$2"; shift 2 ;;
      -p|--root) root="$2"; shift 2 ;;
      --path) path_override="$2"; shift 2 ;;
      -h|--help)
        cat <<'EOF'
wremote - create a worktree from a remote branch

Usage:
  wremote <branch>                 # branch may contain slashes (e.g., terragon/feature/x)
  wremote origin/<branch>          # explicit remote
  wremote -r upstream <branch>     # choose remote
  wremote -b local-name <branch>   # local branch name
  wremote -p ROOT <branch>         # place under ROOT (uses __w_dir_for)
  wremote --path /abs/path <branch># exact path
EOF
        return 0 ;;
      *) echo "wremote: unknown flag $1"; return 1 ;;
    esac
  done

  local ref="$1"
  [[ -z "$ref" ]] && { echo "usage: wremote [options] <branch>"; return 1; }

  # If ref starts with <existing-remote>/..., treat that as the remote; otherwise it's a namespaced branch on $remote
  if [[ "$ref" == */* ]]; then
    local maybe_remote="${ref%%/*}"
    if git remote | grep -qx "$maybe_remote"; then
      remote="$maybe_remote"
      ref="${ref#*/}"
    fi
  fi

  # Default local branch name mirrors remote branch
  [[ -z "$localbr" ]] && localbr="${ref##refs/heads/}"

  # Verify remote branch exists
  if ! git ls-remote --heads "$remote" "$ref" | grep -q .; then
    if ! git ls-remote --heads "$remote" "refs/heads/$ref" | grep -q .; then
      echo "No such remote branch on $remote: $ref"
      echo "Tip: git branch -r | grep -- '$remote/$ref$'"
      return 1
    fi
  fi

  # Ensure we have the remote-tracking ref locally (avoid colon refspec; fetch the branch name)
  if ! git show-ref --verify --quiet "refs/remotes/$remote/$ref"; then
    git fetch "$remote" "$ref" || { echo "Fetch failed."; return 1; }
  fi

  # Create local tracking branch if missing (no checkout)
  if ! git show-ref --verify --quiet "refs/heads/$localbr"; then
    git branch --track "$localbr" "$remote/$ref" 2>/dev/null || git branch "$localbr" "$remote/$ref" || {
      echo "Could not create local branch '$localbr' from '$remote/$ref'"; return 1;
    }
  fi

  # Prevent double-checkout
  if git worktree list --porcelain | awk -v b="refs/heads/$localbr" '/^branch / && $2==b {found=1} END{exit(found?0:1)}'
  then
    echo "Branch '$localbr' is already checked out in a worktree."; return 1
  fi

  # Decide target dir
  local base_root="${W_ROOT:-$(__w_default_root)}"
  local dir
  if [[ -n "$path_override" ]]; then
    dir="$path_override"
  else
    dir="$(__w_dir_for "$localbr" "${root:-$base_root}")"
  fi

  git worktree add "$dir" "$localbr" || return $?
  git branch --quiet --set-upstream-to="$remote/$ref" "$localbr" 2>/dev/null || true
  echo "Created worktree: $dir  (tracking $remote/$ref)"
  cd "$dir"
}



# Added by Antigravity
export PATH="/Users/anishthite/.antigravity/antigravity/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"



alias gdi="node /Users/anishthite/workspace/better-git-commit/bin/gd.js"

# pnpm
export PNPM_HOME="/Users/anishthite/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
#
#
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"


eval "$(direnv hook zsh)"   # or bash



# bun completions
[ -s "/Users/anishthite/.bun/_bun" ] && source "/Users/anishthite/.bun/_bun"

source /Users/anishthite/.daytona.completion_script.zsh

# Added by jcode installer
export PATH="/Users/anishthite/.local/bin:$PATH"

# bun
export PATH="/Users/anishthite/.bun/bin:$PATH"

# Go binaries (go install / task install)
export PATH="$HOME/go/bin:$PATH"

# Whip shortcut
alias wh="whip"
alias whc="whipcode -yolo"
