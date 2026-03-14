# starship - Modern, fast, cross-shell prompt
# https://starship.rs/

if command -v starship >/dev/null 2>&1; then
  export STARSHIP_CONFIG="${DOTFILES_DIR:h}/apps/starship/starship.toml"
  eval "$(starship init zsh)"
fi
