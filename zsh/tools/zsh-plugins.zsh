# Zsh plugins
# Installed via git clone (XDG-compliant, works without Homebrew)
# Update all: update-zsh-plugins

local _plugins_dir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"

# Clone plugin if not present
_ensure_zsh_plugin() {
  local name="$1" repo="$2"
  if [[ ! -d "$_plugins_dir/$name" ]]; then
    echo "Installing $name..."
    git clone --depth 1 "https://github.com/$repo" "$_plugins_dir/$name" 2>/dev/null || return 1
  fi
}

# zsh-autosuggestions - Fish-like autosuggestions
# https://github.com/zsh-users/zsh-autosuggestions
_ensure_zsh_plugin "zsh-autosuggestions" "zsh-users/zsh-autosuggestions"
if [[ -f "$_plugins_dir/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$_plugins_dir/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# zsh-fast-syntax-highlighting - Command syntax highlighting
# https://github.com/zdharma-continuum/fast-syntax-highlighting
_ensure_zsh_plugin "zsh-fast-syntax-highlighting" "zdharma-continuum/fast-syntax-highlighting"
if [[ -f "$_plugins_dir/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]]; then
  source "$_plugins_dir/zsh-fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
fi

# Update all plugins
update-zsh-plugins() {
  local plugin_dir
  for plugin_dir in "$_plugins_dir"/*(N/); do
    echo "Updating ${plugin_dir:t}..."
    git -C "$plugin_dir" pull --ff-only 2>/dev/null || echo "  Failed to update ${plugin_dir:t}"
  done
  echo "Done."
}
