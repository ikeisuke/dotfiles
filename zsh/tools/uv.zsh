# uv - Fast Python package and project manager
# https://github.com/astral-sh/uv

if command -v uv >/dev/null 2>&1; then
  # Cache shell completion (regenerate when uv binary changes)
  local _uv_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/uv-completion.zsh"
  local _uv_bin="$(command -v uv)"

  if [[ ! -f "$_uv_cache" || "$_uv_bin" -nt "$_uv_cache" ]]; then
    mkdir -p "${_uv_cache:h}"
    uv generate-shell-completion zsh > "$_uv_cache" 2>/dev/null
  fi

  [[ -f "$_uv_cache" ]] && source "$_uv_cache"
fi
