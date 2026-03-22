# Aliases
# Note: Abbreviation-style shortcuts (ll, lt, gs, ga, etc.) are handled by
# zeno.zsh snippets (apps/zeno/config.yml) for visible expansion.
# Keep only transparent replacements and safety wrappers here.

# Modern replacements (transparent - behave like the original command)
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --git'
  alias la='eza --icons --git -a'
  alias ll='eza --icons --git -l'
  alias lla='eza --icons --git -la'
  alias lt='eza --icons --git --tree'
else
  alias la='ls -a'
  alias ll='ls -l'
fi

if command -v bat >/dev/null 2>&1; then
  alias cat='bat --style=plain'
fi

# Safety aliases（インタラクティブシェルのみ、AIエージェントの子プロセスに影響させない）
if [[ -o interactive ]]; then
  alias rm='rm -i'
  alias cp='cp -i'
  alias mv='mv -i'
fi

# Convenience
alias mkdir='mkdir -p'
alias sudo='sudo '

# Fallback for when zeno is not available (zeno snippet also defines q → kiro-cli-chat)
alias q='kiro-cli-chat'
