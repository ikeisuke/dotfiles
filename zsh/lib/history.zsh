# History settings
# Store history in XDG state directory for clean $HOME
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
HISTSIZE=1000000
SAVEHIST=1000000

# Create history directory if it doesn't exist
[[ -d "${HISTFILE:h}" ]] || mkdir -p "${HISTFILE:h}"

# History search keybinding
bindkey '^R' history-incremental-pattern-search-backward
