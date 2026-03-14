# Tmux Configuration

Modern, modular tmux configuration with session persistence and iTerm2 integration.

## Features

- ✅ **Session Persistence**: Auto-save and restore sessions (survives reboots)
- ✅ **Cross-Platform**: macOS + Linux support
- ✅ **iTerm2 Integration**: Native macOS experience when needed
- ✅ **Mouse Support**: Click to select panes, resize, scroll
- ✅ **Vi Mode**: Vim-style key bindings
- ✅ **System Clipboard**: Seamless copy/paste

## Quick Start

```bash
./setup.sh  # Links tmux.conf and installs TPM

# Start tmux
tmux new -s main

# Or use iTerm2 integration (macOS only)
tmux -CC new -s main
```

## Installation

### 1. Install TPM (Tmux Plugin Manager)

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

### 2. Run setup.sh

```bash
./setup.sh
```

### 3. Install plugins

Start tmux and press `Ctrl+z` then `I` (capital i) to install plugins.

## Key Bindings

**Prefix**: `Ctrl+z` (instead of default `Ctrl+b`)

### Essential Commands

| Keys | Action |
|------|--------|
| `Ctrl+z` then `c` | New window |
| `Ctrl+z` then `-` | Split horizontally |
| `Ctrl+z` then `\` | Split vertically |
| `Ctrl+z` then `s` | Choose session |
| `Ctrl+z` then `w` | Choose window |
| `Ctrl+z` then `r` | Reload config |

### Navigation (No prefix needed)

| Keys | Action |
|------|--------|
| `Alt+h/j/k/l` | Navigate panes |
| `Alt+n/p` | Next/Previous window |

### Pane Resizing

| Keys | Action |
|------|--------|
| `Ctrl+z` then `H/J/K/L` | Resize pane (repeatable) |

### Copy Mode

| Keys | Action |
|------|--------|
| `Ctrl+z` then `Escape` | Enter copy mode |
| `v` | Begin selection (in copy mode) |
| `y` | Copy selection |
| `Escape` | Exit copy mode |

## Session Persistence

Sessions are **automatically saved every 15 minutes** and **restored on tmux start**.

```bash
# Create a session
tmux new -s work

# Do your work, close terminal, reboot...

# Next time you start tmux:
tmux
# → Your 'work' session is automatically restored!
```

### Manual Control

```bash
# Save session manually
Ctrl+z then Ctrl+s

# Restore session manually
Ctrl+z then Ctrl+r
```

## iTerm2 Integration (macOS)

### What is it?

iTerm2 can display tmux sessions using **native macOS windows/tabs** instead of the tmux interface.

### Benefits

- ✅ Native macOS look and feel
- ✅ Use Cmd+T for new tabs (tmux windows)
- ✅ Use Cmd+D for splits (tmux panes)
- ✅ No tmux prefix needed for many operations
- ✅ Still get tmux session persistence

### How to Use

**Standard mode** (works everywhere, including SSH):
```bash
tmux new -s main
```

**iTerm2 integration mode** (macOS only):
```bash
tmux -CC new -s main
```

**Or attach to existing**:
```bash
tmux -CC attach -t main
```

### Switching Between Modes

You can attach to the same session in different modes:

```bash
# Terminal 1: iTerm2 native mode
tmux -CC attach -t work

# Terminal 2 (or SSH): Standard tmux mode
tmux attach -t work

# Both see the same session!
```

### Recommended Workflow

1. **Local work (macOS)**: Use `-CC` for native experience
2. **SSH/Remote**: Use standard tmux
3. **Cross-platform scripts**: Use standard tmux for consistency

### Aliases for Easy Switching

Add to `~/.zshrc.local`:

```bash
# Standard tmux
alias tm='tmux attach -t main || tmux new -s main'

# iTerm2 integration (auto-detect)
alias tmi='tmux -CC attach -t main || tmux -CC new -s main'

# Smart: Use -CC in iTerm2, standard elsewhere
if [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
  alias tmux='tmux -CC'
fi
```

## File Structure

```
apps/tmux/
├── tmux.conf       # Main entry point
├── base.conf       # Base settings
├── keys.conf       # Key bindings
├── theme.conf      # Status bar theme
├── plugins.conf    # TPM plugins
├── macos.conf      # macOS-specific
└── linux.conf      # Linux-specific
```

## Plugins

Managed by [TPM](https://github.com/tmux-plugins/tpm):

- **tmux-sensible**: Sane defaults
- **tmux-yank**: System clipboard integration
- **tmux-resurrect**: Save/restore sessions
- **tmux-continuum**: Auto-save sessions

## Customization

Edit individual config files in `apps/tmux/`:

- `keys.conf` → Change key bindings
- `theme.conf` → Customize status bar
- `plugins.conf` → Add/remove plugins

Then reload:
```bash
Ctrl+z then r
```

## Troubleshooting

### Plugins not working

1. Install TPM: `git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`
2. Inside tmux: `Ctrl+z` then `I` (capital i)

### Colors look wrong

Make sure your terminal supports 256 colors:
```bash
echo $TERM
# Should be: screen-256color or tmux-256color
```

### iTerm2 integration not working

- Update iTerm2 to latest version
- Use `tmux -CC` (with `-CC` flag)
- Check iTerm2 Preferences → General → tmux Integration

### Session not restoring

- Check `~/.tmux/resurrect/` directory exists
- Wait 15 minutes for first auto-save, or manually save with `Ctrl+z` `Ctrl+s`

## Resources

- [tmux documentation](https://github.com/tmux/tmux/wiki)
- [iTerm2 tmux integration](https://iterm2.com/documentation-tmux-integration.html)
- [TPM plugins](https://github.com/tmux-plugins)
