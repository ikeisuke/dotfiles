#!/bin/bash
set -e  # Exit on error

# constants
DIR="$(cd "$(dirname "$0")" && pwd)"
STARTING_DATETIME="$(date "+%Y%m%d%H%M%S")"
BACKUP_DIR="$HOME/.dotfiles_backup/$STARTING_DATETIME"
MACOSX=0 LINUX=0
case ${OSTYPE} in
  darwin*)
    MACOSX=1
    ;;
  linux*)
    LINUX=1
    ;;
esac

# Install dependencies via Homebrew
if [ "$MACOSX" == 1 ]; then
  if command -v brew >/dev/null 2>&1; then
    if [ -f "$DIR/Brewfile" ]; then
      echo "Installing dependencies via Homebrew..."
      brew bundle --file="$DIR/Brewfile"
      echo "✓ Homebrew dependencies installed"
      echo ""
    fi
  else
    echo "================================================"
    echo "Warning: Homebrew not found"
    echo "Install from: https://brew.sh"
    echo "================================================"
    echo ""
  fi
fi

# Migrate legacy paths to XDG-compliant locations
migrate_if_exists() {
  local old="$1" new="$2"
  if [ -d "$old" ] && [ ! -L "$old" ] && [ ! -d "$new" ]; then
    echo "  Migrating $old → $new"
    mkdir -p "$(dirname "$new")"
    \mv "$old" "$new"
  elif [ -d "$old" ] && [ ! -L "$old" ] && [ -d "$new" ]; then
    echo "  ⚠ Both $old and $new exist. Please merge manually."
  fi
}

echo "Checking for legacy paths..."
_migrated=0
migrate_if_exists "$HOME/.cargo" "$HOME/.local/share/cargo" && _migrated=1
migrate_if_exists "$HOME/.rustup" "$HOME/.local/share/rustup" && _migrated=1

# Clean up legacy ~/.cargo remnant (empty dir or just env/ directory from old install)
if [ -d "$HOME/.cargo" ] && [ ! -L "$HOME/.cargo" ]; then
  # Remove if it only contains env/ directory (old rustup remnant)
  if [ -z "$(find "$HOME/.cargo" -mindepth 1 -not -path "$HOME/.cargo/env" -not -path "$HOME/.cargo/env/*" 2>/dev/null)" ]; then
    echo "  Removing legacy ~/.cargo remnant"
    rm -rf "$HOME/.cargo"
    _migrated=1
  fi
fi
[ "$_migrated" -eq 0 ] && echo "✓ No legacy paths to migrate"

# Install rustup (Rust toolchain) via official installer
# Homebrew版はビルド時にbrewのrustが必要で循環依存になるため公式インストーラーを使用
RUSTUP_HOME="${RUSTUP_HOME:-$HOME/.local/share/rustup}"
CARGO_HOME="${CARGO_HOME:-$HOME/.local/share/cargo}"
export RUSTUP_HOME CARGO_HOME
if ! command -v rustup >/dev/null 2>&1 && [ ! -f "$CARGO_HOME/bin/rustup" ]; then
  echo "Installing rustup (Rust toolchain)..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
  echo "✓ rustup installed"
  echo ""
elif [ -f "$CARGO_HOME/bin/rustup" ]; then
  echo "✓ rustup already installed"
fi

# Ensure cargo bin is in PATH for the rest of this script
if [ -f "$CARGO_HOME/env" ]; then
  . "$CARGO_HOME/env"
fi

# Set default toolchain if none is active
if command -v rustup >/dev/null 2>&1; then
  if ! rustup show active-toolchain >/dev/null 2>&1; then
    echo "Setting default Rust toolchain..."
    rustup default stable
    echo "✓ Default toolchain set to stable"
  fi
fi

# Install deno via official installer
# Homebrew版はLinuxbrewのlibffi/sqlite3とzeno FFIプラグインの不整合でSEGVする
DENO_INSTALL="${DENO_INSTALL:-$HOME/.deno}"
export DENO_INSTALL
if ! command -v deno >/dev/null 2>&1 && [ ! -f "$DENO_INSTALL/bin/deno" ]; then
  echo "Installing deno..."
  curl -fsSL https://deno.land/install.sh | sh
  echo "✓ deno installed"
  echo ""
elif command -v deno >/dev/null 2>&1 || [ -f "$DENO_INSTALL/bin/deno" ]; then
  echo "✓ deno already installed"
fi

# functions
link_and_backup() {
  local source="$1" dist="$2"

  # If destination exists and is not a symlink, back it up
  if [ -e "$dist" ] && [ ! -L "$dist" ]; then
    local backup_name
    backup_name="$(echo "$dist" | sed 's|/|__|g' | sed 's|^__||')"
    if mkdir -p "$BACKUP_DIR" && \cp -a "$dist" "$BACKUP_DIR/$backup_name"; then
      echo "  Backing up existing file: $dist → $BACKUP_DIR/"
    else
      echo "  ⚠ Failed to backup: $dist" >&2
      return 1
    fi
  fi

  # Create symlink
  # Shorten paths for display
  local short_dist="${dist/#$HOME/~}"
  local short_source="${source/#$DIR/<dotfiles>}"
  if ln -sf "$source" "$dist"; then
    echo "  ✓ Linked: $short_dist → $short_source"
  else
    echo "  ✗ Failed to link: $dist" >&2
    return 1
  fi
}
check_dependency() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "Please install $name before running setup.sh."
    return 1
  fi
  return 0
}

# .gitconfig
if check_dependency git; then
  link_and_backup "$DIR/apps/git/gitconfig" ~/.gitconfig
  mkdir -p ~/.config/git
  link_and_backup "$DIR/apps/git/gitignore" ~/.config/git/ignore

  # Create local config if it doesn't exist
  if [ ! -e ~/.gitconfig.local ]; then
    echo ""
    echo "================================================"
    echo "Git local configuration setup"
    echo "================================================"

    # Get current git config values if they exist
    current_name=$(git config --global user.name 2>/dev/null || echo "")
    current_email=$(git config --global user.email 2>/dev/null || echo "")

    # Prompt for user name
    if [ -n "$current_name" ]; then
      echo -n "Git user name [$current_name]: "
    else
      echo -n "Git user name: "
    fi
    read -r input_name
    username=${input_name:-$current_name}

    # Prompt for user email
    if [ -n "$current_email" ]; then
      echo -n "Git user email [$current_email]: "
    else
      echo -n "Git user email: "
    fi
    read -r input_email
    useremail=${input_email:-$current_email}

    # Create .gitconfig.local
    if [ -n "$username" ] && [ -n "$useremail" ]; then
      cat > ~/.gitconfig.local <<EOF
# Local Git Configuration
# This file is not tracked by dotfiles

[user]
  name = $username
  email = $useremail

# For directory-specific overrides, see ~/.gitconfig.local.example
EOF
      echo ""
      echo "✓ Created ~/.gitconfig.local"
      echo ""
      echo "For directory-specific settings (work/personal overrides),"
      echo "see examples in ~/.gitconfig.local.example"
      echo ""
    else
      echo ""
      echo "⚠ Skipped creating ~/.gitconfig.local (name or email not provided)"
      echo "You can create it manually later by copying ~/.gitconfig.local.example"
      echo ""
    fi
  fi
fi

# jj (jujutsu) configuration
if command -v jj >/dev/null 2>&1; then
  # Get user info from git config if available (without --global to respect includes)
  jj_name=$(git config user.name 2>/dev/null || echo "")
  jj_email=$(git config user.email 2>/dev/null || echo "")

  if [ -n "$jj_name" ] && [ -n "$jj_email" ]; then
    echo "Configuring jj (jujutsu) with git user info..."
    jj config set --user user.name "$jj_name"
    jj config set --user user.email "$jj_email"
    echo "✓ jj configured (from git config)"
  else
    echo "⚠ Skipping jj configuration (git user.name/email not set)"
  fi
fi

# .zshrc
if check_dependency zsh; then
  link_and_backup "$DIR/zsh/zshenv" ~/.zshenv
  link_and_backup "$DIR/zsh/zprofile" ~/.zprofile
  link_and_backup "$DIR/zsh/zshrc" ~/.zshrc

  # Compile zsh files for faster startup (non-critical, don't abort on failure)
  echo "Compiling zsh files for faster startup..."
  if zsh -c "
    mkdir -p ~/.cache/zsh
    zcompile ~/.zshenv
    zcompile ~/.zprofile
    zcompile ~/.zshrc
    for file in ${DIR}/zsh/**/*.zsh(N); do
      zcompile \"\$file\"
    done
  " 2>/dev/null; then
    echo "✓ Zsh files compiled"
  else
    echo "⚠ Warning: some zsh files failed to compile (non-critical)"
  fi
fi

# tmux (XDG: ~/.config/tmux/)
if check_dependency tmux; then
  mkdir -p ~/.config/tmux
  link_and_backup "$DIR/apps/tmux/tmux.conf" ~/.config/tmux/tmux.conf

  # Install TPM if not already installed
  if [ ! -d ~/.config/tmux/plugins/tpm ]; then
    echo "Installing TPM (Tmux Plugin Manager)..."
    git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
    echo "  → Install tmux plugins: start tmux, then press Ctrl+z I"
  fi

  # Clean up legacy ~/.tmux.conf symlink
  if [ -L ~/.tmux.conf ]; then
    echo "  Removing legacy ~/.tmux.conf symlink"
    \rm ~/.tmux.conf
  fi
fi

# Claude Code
if [ -d "$DIR/apps/claude" ]; then
  mkdir -p ~/.claude
  link_and_backup "$DIR/apps/claude/keybindings.json" ~/.claude/keybindings.json
fi

# GitHub CLI
if [ -d "$DIR/apps/gh" ]; then
  mkdir -p ~/.config/gh
  link_and_backup "$DIR/apps/gh/config.yml" ~/.config/gh/config.yml
fi

# zeno.zsh
if [ -d "$DIR/apps/zeno" ]; then
  mkdir -p ~/.config/zeno
  link_and_backup "$DIR/apps/zeno/config.yml" ~/.config/zeno/config.yml
fi

# Ghostty
if [ -d "$DIR/apps/ghostty" ]; then
  mkdir -p ~/.config/ghostty
  link_and_backup "$DIR/apps/ghostty/config" ~/.config/ghostty/config
fi

# .vimrc
if check_dependency vim; then
  link_and_backup "$DIR/apps/vim/vimrc" ~/.vimrc
  echo "Vim configuration linked. Run 'vim +PlugInstall +qall' to install plugins."
fi
