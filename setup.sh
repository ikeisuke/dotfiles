#!/bin/bash
set -e  # Exit on error

# Run a command quietly; show ✓ on success, ✗ with output on failure
run_quiet() {
  local label="$1"
  shift
  local output
  if output=$("$@" 2>&1); then
    echo "  ✓ $label"
  else
    local rc=$?
    echo "  ✗ $label"
    echo "$output" | sed 's/^/    /'
    return $rc
  fi
}

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

# functions
link_and_backup() {
  local source="$1" dist="$2"

  # If destination exists and is not a symlink, back it up
  if [ -e "$dist" ] && [ ! -L "$dist" ]; then
    local backup_name
    backup_name="$(echo "$dist" | sed 's|/|__|g' | sed 's|^__||')"
    if mkdir -p "$BACKUP_DIR" && \cp -a "$dist" "$BACKUP_DIR/$backup_name"; then
      echo "  Backing up: $dist → $BACKUP_DIR/"
    else
      echo "  ⚠ Failed to backup: $dist" >&2
      return 1
    fi
  fi

  # Create symlink
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
    echo "  ⚠ $name not found. Skipping."
    return 1
  fi
  return 0
}

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

# ── Homebrew ──────────────────────────────────────────────
if [ "$MACOSX" == 1 ]; then
  echo "Homebrew"
  if command -v brew >/dev/null 2>&1; then
    if [ -f "$DIR/Brewfile" ]; then
      run_quiet "Dependencies installed" brew bundle --file="$DIR/Brewfile"
    fi
  else
    echo "  ⚠ Not found. Install from: https://brew.sh"
  fi
fi

# ── Legacy migration ─────────────────────────────────────
echo "Legacy migration"
_migrated=0
migrate_if_exists "$HOME/.cargo" "$HOME/.local/share/cargo" && _migrated=1
migrate_if_exists "$HOME/.rustup" "$HOME/.local/share/rustup" && _migrated=1

# Clean up legacy ~/.cargo remnant (empty dir or just env/ directory from old install)
if [ -d "$HOME/.cargo" ] && [ ! -L "$HOME/.cargo" ]; then
  if [ -z "$(find "$HOME/.cargo" -mindepth 1 -not -path "$HOME/.cargo/env" -not -path "$HOME/.cargo/env/*" 2>/dev/null)" ]; then
    echo "  Removing legacy ~/.cargo remnant"
    rm -rf "$HOME/.cargo"
    _migrated=1
  fi
fi
[ "$_migrated" -eq 0 ] && echo "  ✓ No legacy paths to migrate"

# ── rustup ────────────────────────────────────────────────
# Homebrew版はビルド時にbrewのrustが必要で循環依存になるため公式インストーラーを使用
echo "rustup"
RUSTUP_HOME="${RUSTUP_HOME:-$HOME/.local/share/rustup}"
CARGO_HOME="${CARGO_HOME:-$HOME/.local/share/cargo}"
export RUSTUP_HOME CARGO_HOME
if ! command -v rustup >/dev/null 2>&1 && [ ! -f "$CARGO_HOME/bin/rustup" ]; then
  run_quiet "Installed" sh -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path"
elif [ -f "$CARGO_HOME/bin/rustup" ]; then
  echo "  ✓ Already installed"
fi

# Ensure cargo bin is in PATH for the rest of this script
if [ -f "$CARGO_HOME/env" ]; then
  . "$CARGO_HOME/env"
fi

# Set default toolchain if none is active
if command -v rustup >/dev/null 2>&1; then
  if ! rustup show active-toolchain >/dev/null 2>&1; then
    run_quiet "Default toolchain set to stable" rustup default stable
  fi
fi

# ── deno ──────────────────────────────────────────────────
# Homebrew版はLinuxbrewのlibffi/sqlite3とzeno FFIプラグインの不整合でSEGVする
echo "deno"
DENO_INSTALL="${DENO_INSTALL:-$HOME/.deno}"
export DENO_INSTALL
if ! command -v deno >/dev/null 2>&1 && [ ! -f "$DENO_INSTALL/bin/deno" ]; then
  run_quiet "Installed" sh -c "curl -fsSL https://deno.land/install.sh | sh"
elif command -v deno >/dev/null 2>&1 || [ -f "$DENO_INSTALL/bin/deno" ]; then
  echo "  ✓ Already installed"
fi

# ── git ───────────────────────────────────────────────────
echo "git"
if check_dependency git; then
  link_and_backup "$DIR/apps/git/gitconfig" ~/.gitconfig
  mkdir -p ~/.config/git
  link_and_backup "$DIR/apps/git/gitignore" ~/.config/git/ignore

  # Create local config if it doesn't exist
  if [ ! -e ~/.gitconfig.local ]; then
    echo "  Local configuration setup:"

    # Get current git config values if they exist
    current_name=$(git config --global user.name 2>/dev/null || echo "")
    current_email=$(git config --global user.email 2>/dev/null || echo "")

    # Prompt for user name
    if [ -n "$current_name" ]; then
      echo -n "  Git user name [$current_name]: "
    else
      echo -n "  Git user name: "
    fi
    read -r input_name
    username=${input_name:-$current_name}

    # Prompt for user email
    if [ -n "$current_email" ]; then
      echo -n "  Git user email [$current_email]: "
    else
      echo -n "  Git user email: "
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
      echo "  ✓ Created ~/.gitconfig.local"
      echo "    → For directory-specific settings, see ~/.gitconfig.local.example"
    else
      echo "  ⚠ Skipped creating ~/.gitconfig.local (name or email not provided)"
    fi
  fi
fi

# ── jj (jujutsu) ─────────────────────────────────────────
if command -v jj >/dev/null 2>&1; then
  echo "jj"
  # Get user info from git config if available (without --global to respect includes)
  jj_name=$(git config user.name 2>/dev/null || echo "")
  jj_email=$(git config user.email 2>/dev/null || echo "")

  if [ -n "$jj_name" ] && [ -n "$jj_email" ]; then
    run_quiet "Configured (from git config)" sh -c "jj config set --user user.name '$jj_name' && jj config set --user user.email '$jj_email'"
  else
    echo "  ⚠ Skipping (git user.name/email not set)"
  fi
fi

# ── zsh ───────────────────────────────────────────────────
echo "zsh"
if check_dependency zsh; then
  link_and_backup "$DIR/zsh/zshenv" ~/.zshenv
  link_and_backup "$DIR/zsh/zprofile" ~/.zprofile
  link_and_backup "$DIR/zsh/zshrc" ~/.zshrc

  # Compile zsh files for faster startup (non-critical, don't abort on failure)
  if zsh -c "
    mkdir -p ~/.cache/zsh
    zcompile ~/.zshenv
    zcompile ~/.zprofile
    zcompile ~/.zshrc
    for file in ${DIR}/zsh/**/*.zsh(N); do
      zcompile \"\$file\"
    done
  " 2>/dev/null; then
    echo "  ✓ Zsh files compiled"
  else
    echo "  ⚠ Some files failed to compile (non-critical)"
  fi
fi

# ── tmux ──────────────────────────────────────────────────
echo "tmux"
if check_dependency tmux; then
  mkdir -p ~/.config/tmux
  link_and_backup "$DIR/apps/tmux/tmux.conf" ~/.config/tmux/tmux.conf

  # Install TPM if not already installed
  if [ ! -d ~/.config/tmux/plugins/tpm ]; then
    run_quiet "TPM installed" git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
    echo "  → Run: tmux, then Ctrl+z I to install plugins"
  fi

  # Clean up legacy ~/.tmux.conf symlink
  if [ -L ~/.tmux.conf ]; then
    echo "  Removing legacy ~/.tmux.conf symlink"
    \rm ~/.tmux.conf
  fi
fi

# ── bin ───────────────────────────────────────────────────
if [ -d "$DIR/bin" ]; then
  echo "bin"
  mkdir -p ~/.local/bin
  for f in "$DIR/bin/"*; do
    link_and_backup "$f" ~/.local/bin/"$(basename "$f")"
  done
fi

# ── WSL2 AppArmor ─────────────────────────────────────────
# jailrun のサンドボックスが AppArmor を一次プロファイルとして使うため、
# WSL2 側 .wslconfig に有効化パラメータをマージする。
# .wslconfig は WSL2 専用なので WSL1 は除外（kernel release/proc version の "WSL2" で判定）
if [ "$LINUX" = 1 ] && { uname -r 2>/dev/null | grep -qi WSL2 || grep -qi WSL2 /proc/version 2>/dev/null; }; then
  echo "WSL2 AppArmor"

  # Windows ユーザー名は cmd.exe interop 経由でのみ確定的に取得できる。
  # /mnt/c/Users の走査は複数アカウント環境で誤判定するため行わない。
  win_user=""
  if [ -x /mnt/c/Windows/System32/cmd.exe ]; then
    win_user=$(cd /mnt/c && /mnt/c/Windows/System32/cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n')
  fi

  if [ -z "$win_user" ]; then
    echo "  ⚠ Windows username not detected (cmd.exe interop unavailable). Skipping .wslconfig setup."
    echo "    → Manual: add 'apparmor=1 security=apparmor' to kernelCommandLine in C:\\Users\\<you>\\.wslconfig"
  else
    wslconfig="/mnt/c/Users/$win_user/.wslconfig"
    required_params="apparmor=1 security=apparmor"

    before_sum=""
    [ -f "$wslconfig" ] && before_sum=$(md5sum "$wslconfig" | awk '{print $1}')

    if [ ! -f "$wslconfig" ]; then
      cat > "$wslconfig" <<EOF
[wsl2]
kernelCommandLine = $required_params
EOF
      echo "  ✓ Created: $wslconfig"
      echo "    → Run 'wsl --shutdown' from Windows to apply"
    else
      tmp="${wslconfig}.tmp.$$"
      backup="${wslconfig}.bak.$STARTING_DATETIME"
      \cp "$wslconfig" "$backup"
      # INI のセクション名 / キー名は大小文字を区別しないので tolower で比較する
      awk -v required="$required_params" '
        BEGIN { section=""; wsl2_found=0; kcl_found=0 }
        /^\[.*\]/ {
          if (section == "wsl2" && !kcl_found) {
            print "kernelCommandLine = " required
            kcl_found = 1
          }
          section = tolower(substr($0, 2, length($0) - 2))
          if (section == "wsl2") wsl2_found = 1
          print
          next
        }
        section == "wsl2" && tolower($0) ~ /^[[:space:]]*kernelcommandline[[:space:]]*=/ {
          kcl_found = 1
          val = $0
          sub(/^[^=]*=[[:space:]]*/, "", val)
          n = split(required, req_arr, " ")
          for (i=1; i<=n; i++) {
            if (index(" " val " ", " " req_arr[i] " ") == 0) {
              val = val " " req_arr[i]
            }
          }
          sub(/^[[:space:]]+/, "", val)
          print "kernelCommandLine = " val
          next
        }
        { print }
        END {
          if (!wsl2_found) {
            print "[wsl2]"
            print "kernelCommandLine = " required
          } else if (!kcl_found) {
            print "kernelCommandLine = " required
          }
        }
      ' "$wslconfig" > "$tmp" && \mv "$tmp" "$wslconfig"

      after_sum=$(md5sum "$wslconfig" | awk '{print $1}')
      if [ "$before_sum" = "$after_sum" ]; then
        echo "  ✓ Already configured: $wslconfig"
        \rm -f "$backup"
      else
        echo "  ✓ Updated: $wslconfig"
        echo "    → Backup: $backup"
        echo "    → Run 'wsl --shutdown' from Windows to apply"
      fi
    fi

    # Runtime status
    if [ -r /sys/module/apparmor/parameters/enabled ]; then
      enabled=$(cat /sys/module/apparmor/parameters/enabled)
      case "$enabled" in
        Y) echo "  ✓ AppArmor enabled (kernel)" ;;
        *) echo "  ⚠ AppArmor disabled (kernel). Run 'wsl --shutdown' from Windows." ;;
      esac
    else
      echo "  ⚠ AppArmor kernel module not loaded. Run 'wsl --shutdown' from Windows."
    fi

    # Userspace tools
    missing=""
    command -v apparmor_parser >/dev/null 2>&1 || missing="$missing apparmor"
    command -v aa-status >/dev/null 2>&1 || missing="$missing apparmor-utils"
    if [ -n "$missing" ]; then
      echo "  ⚠ Missing packages:"
      echo "    sudo apt install$missing"
    fi
  fi
fi

# ── jailrun ───────────────────────────────────────────────
echo "jailrun"
if ! command -v ghq >/dev/null 2>&1; then
  echo "  ✗ ghq not found. Run 'brew bundle' first."
else
  # Linux: 依存パッケージを案内
  case "$(uname)" in
    Linux)
      missing=""
      if ! command -v secret-tool >/dev/null 2>&1; then
        missing="$missing libsecret-tools"
      fi
      if ! command -v gnome-keyring-daemon >/dev/null 2>&1; then
        missing="$missing gnome-keyring"
      fi
      if [ -n "$missing" ]; then
        echo "  ⚠ Linux 推奨パッケージが未インストールです:"
        echo "    sudo apt install$missing"
      fi
      ;;
  esac
  run_quiet "Fetched" ghq get -u ikeisuke/jailrun
  run_quiet "Installed" make -C "$(ghq root)/github.com/ikeisuke/jailrun" install
fi

# ── Claude Code ───────────────────────────────────────────
if [ -d "$DIR/apps/claude" ]; then
  echo "Claude Code"
  mkdir -p ~/.claude
  link_and_backup "$DIR/apps/claude/CLAUDE.md" ~/.claude/CLAUDE.md
  link_and_backup "$DIR/apps/claude/settings.json" ~/.claude/settings.json
  link_and_backup "$DIR/apps/claude/keybindings.json" ~/.claude/keybindings.json
  link_and_backup "$DIR/apps/claude/statusline.py" ~/.claude/statusline.py
  chmod +x ~/.claude/statusline.py

  # Install/update Claude Code via npm (official method)
  if command -v npm >/dev/null 2>&1; then
    run_quiet "Claude Code installed/updated" npm install -g @anthropic-ai/claude-code
  fi

  # Install/update plugins at user scope
  if command -v claude >/dev/null 2>&1; then
    if claude plugins update tools@ikeisuke-skills >/dev/null 2>&1; then
      echo "  ✓ Plugins updated"
    else
      claude plugins marketplace add \
        https://raw.githubusercontent.com/ikeisuke/claude-skills/main/.claude-plugin/marketplace.json 2>/dev/null || true
      run_quiet "Plugins installed" claude plugins install --scope user tools@ikeisuke-skills
    fi
  fi
fi

# ── GitHub CLI ────────────────────────────────────────────
if [ -d "$DIR/apps/gh" ]; then
  echo "GitHub CLI"
  mkdir -p ~/.config/gh
  link_and_backup "$DIR/apps/gh/config.yml" ~/.config/gh/config.yml
fi

# ── zeno.zsh ──────────────────────────────────────────────
if [ -d "$DIR/apps/zeno" ]; then
  echo "zeno"
  mkdir -p ~/.config/zeno
  link_and_backup "$DIR/apps/zeno/config.yml" ~/.config/zeno/config.yml
fi

# ── fzf ───────────────────────────────────────────────────
if [ -d "$DIR/apps/fzf" ]; then
  echo "fzf"
  mkdir -p ~/.config/fzf
  link_and_backup "$DIR/apps/fzf/fzfrc" ~/.config/fzf/fzfrc
fi

# ── Ghostty ───────────────────────────────────────────────
if [ -d "$DIR/apps/ghostty" ]; then
  echo "Ghostty"
  mkdir -p ~/.config/ghostty
  link_and_backup "$DIR/apps/ghostty/config" ~/.config/ghostty/config
fi

# ── vim ───────────────────────────────────────────────────
echo "vim"
if check_dependency vim; then
  link_and_backup "$DIR/apps/vim/vimrc" ~/.vimrc
  echo "  → Run 'vim +PlugInstall +qall' to install plugins"
fi
