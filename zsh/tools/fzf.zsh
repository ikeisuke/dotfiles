# fzf - Fuzzy finder
# https://github.com/junegunn/fzf

if command -v fzf >/dev/null 2>&1; then
  # Use fd for faster file search if available
  if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  fi

  # Enable shell key bindings (Ctrl+T, Ctrl+R, Alt+C)
  if [[ -n "$HOMEBREW_PREFIX" && -f "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh" ]]; then
    source "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh"
  fi

  # Enable completion
  if [[ -n "$HOMEBREW_PREFIX" && -f "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh" ]]; then
    source "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh"
  fi

  # Enhanced preview with bat and eza (with binary file protection)
  if command -v bat >/dev/null 2>&1 && command -v eza >/dev/null 2>&1; then
    export FZF_CTRL_T_OPTS="
      --preview 'f={};
      if [ -d \"\$f\" ]; then
        eza -lah --color=always --icons --git -- \"\$f\";
      elif command -v file >/dev/null && file --mime \"\$f\" | grep -q binary; then
        file --brief \"\$f\";
      else
        bat --color=always --style=numbers --line-range=:500 -- \"\$f\";
      fi'
      --preview-window=right:60%:wrap
    "
  elif command -v bat >/dev/null 2>&1; then
    export FZF_CTRL_T_OPTS="
      --preview 'f={};
      if command -v file >/dev/null && file --mime \"\$f\" | grep -q binary; then
        file --brief \"\$f\";
      else
        bat --color=always --style=numbers --line-range=:500 -- \"\$f\";
      fi'
      --preview-window=right:60%:wrap
    "
  fi

  # Directory preview for Alt+C
  if command -v eza >/dev/null 2>&1; then
    export FZF_ALT_C_OPTS="
      --preview 'eza -lah --color=always --icons --git {}'
      --preview-window=right:60%
    "
  fi

  # History preview for Ctrl+R
  export FZF_CTRL_R_OPTS="
    --preview 'echo {}'
    --preview-window=down:3:wrap
  "
fi
