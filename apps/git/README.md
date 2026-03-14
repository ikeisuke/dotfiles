# Git Configuration

Modern, modular Git configuration with machine-specific settings.

## Quick Start

```bash
./setup.sh
# Enter your name and email when prompted
```

This creates:
- `~/.gitconfig` → symlink to `apps/git/gitconfig` (base settings)
- `~/.gitconfig.local` → your personal info (not tracked)
- `~/.gitconfig.local.example` → reference for advanced usage

## Philosophy

- **Base config** (`apps/git/gitconfig`): Shared settings across all machines (colors, aliases, etc.)
- **Local config** (`~/.gitconfig.local`): Machine-specific settings (name, email, directory overrides)

The base config includes the local config via:
```ini
[include]
  path = ~/.gitconfig.local
```

## Common Patterns

### Pattern 1: Simple Setup (Most Users)

Just run `./setup.sh` and you're done!

```ini
# ~/.gitconfig.local
[user]
  name = Your Name
  email = personal@example.com
```

### Pattern 2: Work Machine + Personal Projects

**Scenario**: You're on a work laptop but have some personal repos.

```bash
# During setup.sh, enter work email as default
Git user email: you@company.com
```

Then edit `~/.gitconfig.local`:
```ini
[user]
  name = Your Name
  email = you@company.com  # Default for work

# Override for personal projects
[includeIf "gitdir:~/personal/"]
  path = ~/.gitconfig.personal
```

Create `~/.gitconfig.personal`:
```ini
[user]
  email = personal@example.com
```

**Result**:
- `~/work/project/` → uses `you@company.com`
- `~/personal/my-blog/` → uses `personal@example.com`

### Pattern 3: Personal Machine + Work Projects

**Scenario**: You're on a personal laptop but do some work projects.

```bash
# During setup.sh, enter personal email as default
Git user email: personal@example.com
```

Then edit `~/.gitconfig.local`:
```ini
[user]
  name = Your Name
  email = personal@example.com  # Default

# Override for work projects
[includeIf "gitdir:~/work/"]
  path = ~/.gitconfig.work
```

Create `~/.gitconfig.work`:
```ini
[user]
  email = you@company.com
```

### Pattern 4: Multiple Organizations

**Scenario**: Contractor working with multiple clients.

Edit `~/.gitconfig.local`:
```ini
[user]
  name = Your Name
  email = personal@example.com  # Default

[includeIf "gitdir:~/repos/github.com/client-a*/"]
  path = ~/.gitconfig.clientA

[includeIf "gitdir:~/repos/github.com/client-b*/"]
  path = ~/.gitconfig.clientB
```

Then create separate configs for each client.

## Testing Your Configuration

Check which email is used in a specific repo:

```bash
cd ~/work/some-project
git config user.email
# → shows the effective email for this repo
```

## Features in Base Config

- **Modern defaults**: `init.defaultBranch = main`, `pull.rebase = true`
- **Better diffs**: `diff.colorMoved = default`, `merge.conflictStyle = zdiff3`
- **Auto-prune**: `fetch.prune = true`
- **Helpful aliases**: `git st`, `git lg` (pretty log graph)
- **Git LFS** support

## Customization

For more examples, see `~/.gitconfig.local.example`.

For AWS CodeCommit, GPG signing, or git-secrets, uncomment the relevant sections in your `~/.gitconfig.local`.
