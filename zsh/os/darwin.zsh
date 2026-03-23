# macOS specific settings

# Colors and terminal
export CLICOLOR=1
export LSCOLORS=ExgxcxdxBxegedabagacad

# Plain ls alias (only if eza is not available; eza alias is set in aliases.zsh)
if ! command -v eza >/dev/null 2>&1; then
  alias ls='ls -G -F'
fi

# Prompt
DEFAULT_COLOR=white
PROMPT="%B%{$fg_bold[$DEFAULT_COLOR]%}$%{$reset_color%}%b "
PROMPT2="%{$fg_bold[$DEFAULT_COLOR]%}%_>%{$reset_color%} "
SPROMPT="%R -> %U%r%u ? [ no %R(n),yes %r(y),abort(a),edit(e) ]: "

# AWS CLI completion
if [[ -n "$HOMEBREW_PREFIX" && -f "$HOMEBREW_PREFIX/share/zsh/site-functions/_aws" ]]; then
  source "$HOMEBREW_PREFIX/share/zsh/site-functions/_aws"
fi

# Homebrew paths
path_prepend /opt/homebrew/opt/openjdk/bin
