# uv - Fast Python package and project manager
# https://github.com/astral-sh/uv

if command -v uv >/dev/null 2>&1; then
  # Enable shell completion
  eval "$(uv generate-shell-completion zsh)"

  # Optional: Set cache directory
  # export UV_CACHE_DIR="$HOME/.cache/uv"
fi
