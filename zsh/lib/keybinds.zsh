# Keybindings
bindkey -e

# Navigation shortcuts
# Ctrl+]: zoxide interactive jump (zi)
if command -v zoxide >/dev/null 2>&1; then
  function _widget_zi() {
    zi
    zle reset-prompt
  }
  zle -N _widget_zi
  bindkey '^]' _widget_zi
fi
