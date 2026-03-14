# Linux specific settings

# Colors
alias ls='ls -F --color=auto'

# WSL specific settings
if grep -qi microsoft /proc/version 2>/dev/null; then
  # Use Windows Chrome from WSL
  export BROWSER="/mnt/c/Program Files (x86)/Google/Chrome/Application/chrome.exe"

  # Add Windows PowerShell to PATH for notifications
  export PATH="$PATH:/mnt/c/Windows/System32/WindowsPowerShell/v1.0"
fi

# Prompt with hostname
DEFAULT_COLOR=white
PROMPT="%B%{$fg_bold[$DEFAULT_COLOR]%}%n@${INSTANCE_NAME:-${$(hostname)%%.*}} [%D{%Y-%m-%d %T}]%#%{$reset_color%}%b "
PROMPT2="%{$fg_bold[$DEFAULT_COLOR]%}%_>%{$reset_color%} "
SPROMPT="%R -> %U%r%u ? [ no %R(n),yes %r(y),abort(a),edit(e) ]: "
