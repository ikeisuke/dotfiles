# Terminal tab title & iTerm2 badge - update on directory change
# Sets tab title to current directory name via OSC escape sequences
# Supported: iTerm2, WezTerm, Ghostty, and other OSC-compatible terminals

_set_tab_title() {
  local tab_title="${PWD##*/}"
  [[ -z "$tab_title" ]] && tab_title="/"

  # OSC 2: set window/tab title (directory name only)
  printf '\e]2;%s\a' "$tab_title"

  # iTerm2 badge (detailed path)
  if [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
    local badge
    local ghq_root="${GHQ_ROOT:-$HOME/repos}"

    if [[ "$PWD" == "$HOME" ]]; then
      badge="~"
    elif [[ "$PWD" == "$ghq_root"/* ]]; then
      badge="${PWD#$ghq_root/}"
    elif [[ "$PWD" == "$HOME"/* ]]; then
      badge="~/${PWD#$HOME/}"
    else
      badge="$PWD"
    fi
    printf '\e]1337;SetBadgeFormat=%s\a' "$(printf '%s' "$badge" | base64)"
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _set_tab_title
