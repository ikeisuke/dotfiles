# Homebrew
# Package manager for macOS/Linux

if [[ -x /opt/homebrew/bin/brew ]]; then
  # Apple Silicon Mac
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  # Intel Mac or Linux
  eval "$(/usr/local/bin/brew shellenv)"
fi
