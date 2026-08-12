# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a dotfiles repository for managing configuration files across machines. It includes a custom `dotfiles` management tool (a Rust CLI; source in `dotfiles-tui/`) that handles deployment via symlinks and tracks what's managed in a self-documenting TOML manifest.

## Directory Structure

- `dotfiles-tui/` - Rust CLI source (its own repo): `crates/` (cli + core) and `docs/architecture/` (ADRs)
- `bootstrap.sh` - Initial setup script for new machines
- `install.sh` - Installs the pinned `dotfiles` CLI into `~/.local/bin` (`--latest` to move ahead of the pin)
- `.dotfiles-cli.version` - Pinned CLI release for reproducible installs
- `.dotfiles-manifest.toml` - The manifest: what's managed, why, and optional spec
- `tmux/` - Tmux terminal multiplexer configuration
- `zsh/` - Z shell configuration

## Dotfiles Management Commands

- `dotfiles status` - Check deployment state
- `dotfiles deploy [--dry-run] [--force]` - Deploy configs via symlinks
- `dotfiles add <app> <path>` - Add new config to management
- `dotfiles enable/disable <app>` - Toggle specific configs
- `dotfiles list` - Show all managed configs
- `dotfiles pull` - Fast-forward the store, then self-update the CLI to `.dotfiles-cli.version`
- `dotfiles push -m "<message>"` - Commit and push the store to origin

### Committing: use `dotfiles push`, not raw git

**Commit this repo with `dotfiles push -m "<message>"`.** It is the tool's own
surface for the operation and it pushes to origin in the same step, so the
store and its remote never drift. Don't hand-roll `git add && git commit &&
git push` here.

The message follows the Git Commit Guidelines below — `dotfiles push` does not
relax them, it just carries them.

**It stages the entire working tree** (`git add -A` internally), so there is no
way to commit a subset of the changes. Two consequences worth checking before
every push:

- **Run `git status` first.** Anything uncommitted rides along in the commit.
  If unrelated work is in flight, either fold it in deliberately and write a
  message that covers it, or land it separately first.
- **Untracked cruft must be gitignored, not just left alone.** A stray backup
  directory sitting in the tree will be committed on the next push. Add it to
  `.gitignore` the moment it appears.

`dotfiles diff` previews local state against origin (uncommitted changes plus
ahead/behind) and is the cheap way to see what a push would carry.

### Keeping the CLI in step with the store

The store and the CLI version independently, so a store update can carry data
whose meaning depends on a CLI capability (e.g. `claude/settings.d/` needs
`dotfiles claude`). `.dotfiles-cli.version` is the authoritative statement of
which CLI this store expects; `install.sh` installs it and `dotfiles pull`
converges on it (dotfiles-cli ADR-200).

To move the pin forward: cut a release in `dotfiles-tui/`, then
`./install.sh --latest`, write the new version into `.dotfiles-cli.version`,
and commit. Other machines pick it up on their next `pull`.

A merged feature that is never tagged is invisible to the pin — releases are
load-bearing here.

Because managed configs deploy as symlinks, edits to the system file and
the repo file are the same bytes. Use `git status` / `git diff` in this
repo as the source of truth for "what changed".

## Git Commit Guidelines

When committing changes to dotfiles, use descriptive messages that explain:
1. **What changed** - Which config file(s) were modified
2. **Why it changed** - The reason or problem being solved
3. **Impact** - How it affects usage or behavior

### Good Commit Examples:
```
tmux: Add vim-style pane navigation with Ctrl+hjkl

- Enables seamless navigation between tmux panes using vim keys
- Maintains consistency with vim muscle memory
- Preserves existing arrow key bindings as fallback

zsh: Configure oh-my-posh with atomic theme

- Adds modern prompt with git status indicators
- Shows execution time for long-running commands
- Includes Python virtual env detection

dotfiles: Add --dry-run mode to deploy for safety

- Allows previewing which symlinks would be created
- Prevents accidental overwrites in the home directory
```

### Bad Commit Examples:
```
update tmux config
fix stuff
changes
```

## Adding New Configurations

When adding a new tool's configuration:

1. Use `dotfiles add` command:
   ```bash
   # For simple files (symlink mode - default)
   dotfiles add nvim .config/nvim

   # For directories that need full copy (like nested git repos)
   dotfiles add some-tool .config/some-tool some-tool --mode copy
   ```

2. This will:
   - Add entry to manifest
   - Create appropriate directory structure
   (drop existing config files into the repo path yourself before
   deploying — the tool no longer captures from the system)

3. Commit with clear message:
   ```
   nvim: Add Neovim configuration with LSP support

   - Includes language servers for Python, JS, and Go
   - Sets up telescope for fuzzy finding
   - Configures gruvbox colorscheme
   ```

## Deployment Modes

The dotfiles system supports two deployment modes:

### Symlink Mode (Default)
- Creates symbolic links from `~/.config` to the dotfiles repo
- Changes in either location are immediately reflected
- Best for: individual config files, most dotfiles

### Copy Mode
- Recursively copies entire directories to `~/.config`
- Preserves `.git` directories for git repositories
- Automatically updates via `git pull` if target is a git repo
- Sets executable permissions on shell scripts
- Best for: git repositories, complex directory structures

## Testing Changes

Before committing configuration changes:

1. Test the actual application with the new config
2. Run `dotfiles status` to ensure proper deployment
3. Review changes with `git diff` in this repo
4. Consider impacts on other systems/platforms

## Platform Considerations

- Note platform-specific settings in commit messages
- Use conditional logic in configs when possible
- Document any OS-specific requirements

## Backup and Recovery

The dotfiles tool automatically backs up existing configs when deploying with `--force`. Backups are stored in `~/.dotfiles-backup/` with timestamps.

To recover from a bad config:
1. Check backups in `~/.dotfiles-backup/`
2. Manually restore or use `dotfiles disable <app>` then copy back
3. Re-deploy when ready

## Evolution Tracking

Since dotfiles evolve over time, good commit messages help track:
- When features were added/removed
- Why certain decisions were made  
- What problems were being solved
- Which tools influenced changes

Use `git log --grep` to search history, e.g.:
```bash
git log --grep="tmux" --oneline  # All tmux-related changes
git log --grep="vim.*navigation"  # Vim navigation updates
```