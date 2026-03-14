# Zsh plugins (installed via Homebrew)
if [[ -n "$HOMEBREW_PREFIX" ]]; then
  local brew_prefix="$HOMEBREW_PREFIX"

  # zsh-autosuggestions - Fish-like autosuggestions
  # https://github.com/zsh-users/zsh-autosuggestions
  if [[ -f "$brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  fi

  # zsh-fast-syntax-highlighting - Command syntax highlighting
  # https://github.com/zdharma-continuum/fast-syntax-highlighting
  if [[ -f "$brew_prefix/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]]; then
    source "$brew_prefix/share/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
  fi
fi
