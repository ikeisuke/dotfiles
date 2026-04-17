# Brewfile - Dependency management for dotfiles
# Install all dependencies: brew bundle
# Check status: brew bundle check

# Taps
tap "ozankasikci/tap"

# Core tools (required)
brew "git"      # Newer than system git (needed for zdiff3, push.autoSetupRemote etc.)
brew "bash"
brew "zsh"
brew "tmux"
brew "vim"
brew "starship"  # Modern, fast prompt

# Navigation tools
brew "fzf"      # Fuzzy finder (vim plugin, zeno)
brew "ghq"      # Repository management
brew "zoxide"   # Smart cd

# Version managers & runtimes
brew "mise"     # Polyglot runtime manager
brew "uv"       # Python package & version manager
brew "python@3.14"  # Latest Python
brew "go"       # Go language
# rustup for Rust (install via: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh)
# Homebrew版rustupはビルド時にbrewのrustが必要で循環依存になるため公式インストーラーを使用
# deno: installed via official installer (~/.deno/bin), not Homebrew
# Homebrew版はLinuxbrewのlibffi/sqlite3とzeno FFIプラグインの不整合でSEGVする

# Testing
brew "bats-core"  # Bash Automated Testing System

# Utilities (optional but recommended)
brew "ripgrep"  # Fast grep (used by fzf preview, vim plugins)
brew "bat"      # Better cat with syntax highlighting (fzf preview)
brew "eza"      # Modern ls replacement
brew "fd"       # Fast find alternative (used by fzf)
brew "git-delta"  # Better git diff viewer
brew "git-secret" # Git secret management
brew "direnv"   # Per-directory environment variables
brew "jq"       # JSON processor
brew "dasel"    # JSON/YAML/TOML/XML processor
brew "gh"       # GitHub CLI
brew "jj"       # Git-compatible VCS (jujutsu)
brew "lazygit"  # Terminal UI for git
brew "awscli"   # AWS CLI
brew "aws-cdk"  # AWS CDK
brew "pulumi"   # Infrastructure as Code tool
# zsh-autosuggestions / zsh-fast-syntax-highlighting are managed via git clone
# (see zsh/tools/zsh-plugins.zsh) for cross-platform portability

# AI tools (cross-platform)
brew "opencode"       # OpenCode AI coding agent
cask "codex"          # OpenAI Codex CLI

# Linux-specific tools (WSL)
if OS.linux?
  brew "k9s"                    # Kubernetes TUI
  brew "kubernetes-cli"         # kubectl
  brew "aws-iam-authenticator"  # EKS authentication
  brew "cloudformation-guard"   # CloudFormation policy validation
  brew "yq"                     # YAML processor
  brew "remarshal"              # Format converter (JSON/YAML/TOML)
end

# macOS-specific tools and apps
if OS.mac?
  brew "trash"  # Safe rm alternative (macOS only)

  # Fonts
  cask "font-jetbrains-mono-nerd-font"

  # AI tools
  brew "gemini-cli"     # Gemini CLI
  cask "claude"         # Anthropic Claude desktop app
  cask "chatgpt"        # OpenAI ChatGPT desktop app
  cask "chatgpt-atlas"  # OpenAI ChatGPT Atlas (research preview)
  cask "kiro-cli"          # Kiro CLI (Amazon)
  cask "agent-sessions"    # Agent Sessions

  # Password management
  cask "1password"      # 1Password desktop app
  cask "1password-cli"  # 1Password CLI (op command)

  # Utilities
  cask "scroll-reverser"  # Reverse mouse scroll independently from trackpad
  cask "adguard"          # Ad blocker
  cask "google-drive"     # Google Drive sync client
  cask "logi-options+"    # Logitech mouse/keyboard settings

  # Development
  cask "docker-desktop"       # Docker Desktop
  cask "visual-studio-code"   # VS Code

  # Security
  cask "eset-cyber-security"  # ESET antivirus

  # Communication
  cask "discord"

  # Terminal
  cask "ghostty"  # GPU-accelerated terminal emulator
  cask "iterm2"
end
