# zoxide - A smarter cd command
# https://github.com/ajeetdsouza/zoxide

if command -v zoxide >/dev/null 2>&1; then
  # Initialize zoxide
  eval "$(zoxide init zsh)"

  # Aliases (optional, zoxide init already creates 'z' and 'zi')
  # z  <keyword>  - Jump to directory
  # zi <keyword>  - Interactive selection with fzf
fi
