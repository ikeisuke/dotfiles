# zeno.zsh - Fuzzy completion & snippet expansion powered by Deno
# https://github.com/yuki-yano/zeno.zsh

if ! command -v deno >/dev/null 2>&1; then
  return
fi

# XDG-compliant Deno cache
export DENO_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/deno"

# Install zeno.zsh if not present
_zeno_home="${XDG_DATA_HOME:-$HOME/.local/share}/zeno"
if [[ ! -d "$_zeno_home" ]]; then
  echo "Installing zeno.zsh..."
  git clone https://github.com/yuki-yano/zeno.zsh "$_zeno_home" 2>/dev/null || return
fi

export ZENO_ENABLE_SOCK=1

# Use bat/eza for previews if available
command -v bat >/dev/null 2>&1 && export ZENO_GIT_CAT="bat --color=always"
command -v eza >/dev/null 2>&1 && export ZENO_GIT_TREE="eza --tree --color=always"

# Config is at $XDG_CONFIG_HOME/zeno/config.yml (do not set ZENO_HOME to avoid override)

# Load zeno
source "$_zeno_home/zeno.zsh"
unset _zeno_home

# Keybindings
bindkey ' '       zeno-auto-snippet             # Space: expand snippet
bindkey '^m'      zeno-auto-snippet-and-accept-line  # Enter: expand & execute
bindkey '^i'      zeno-completion                # Tab: fuzzy completion
bindkey '^s'      zeno-insert-snippet            # Ctrl+s: insert snippet
bindkey '^r'      zeno-history-selection          # Ctrl+r: fuzzy history (replaces fzf)
bindkey '^g'      zeno-ghq-cd                    # Ctrl+g: ghq cd
