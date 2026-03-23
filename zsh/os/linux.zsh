# Linux specific settings

# Colors
alias ls='ls -F --color=auto'

# WSL specific settings
if grep -qi microsoft /proc/version 2>/dev/null; then
  # Use Windows Chrome from WSL
  export BROWSER="/mnt/c/Program Files (x86)/Google/Chrome/Application/chrome.exe"

  # Add Windows PowerShell to PATH for notifications
  export PATH="$PATH:/mnt/c/Windows/System32/WindowsPowerShell/v1.0"

  # gnome-keyring-daemon 自動起動（secret-tool / セキュリティラッパー用）
  if command -v gnome-keyring-daemon >/dev/null 2>&1; then
    if [[ ! -S "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/keyring/control" ]]; then
      eval "$(gnome-keyring-daemon --start --components=secrets 2>/dev/null)"
      export GNOME_KEYRING_CONTROL
    fi
  fi
fi

# Prompt with hostname
DEFAULT_COLOR=white
PROMPT="%B%{$fg_bold[$DEFAULT_COLOR]%}%n@${INSTANCE_NAME:-${$(hostname)%%.*}} [%D{%Y-%m-%d %T}]%#%{$reset_color%}%b "
PROMPT2="%{$fg_bold[$DEFAULT_COLOR]%}%_>%{$reset_color%} "
SPROMPT="%R -> %U%r%u ? [ no %R(n),yes %r(y),abort(a),edit(e) ]: "
