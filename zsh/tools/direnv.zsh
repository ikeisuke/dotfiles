# direnv - Per-directory environment variables
# https://direnv.net/

if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi
