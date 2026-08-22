# Dotfiles

Personal configuration files managed with a custom `dotfiles` tool.

Yes I know it's silly that it's called dotfiles, with a .

The `dotfiles` command is a small Rust CLI (source lives in [`dotfiles-tui/`](dotfiles-tui/),
its own repo). It reads a single self-documenting manifest, `.dotfiles-manifest.toml`,
and deploys each managed config as a symlink into `$HOME`. Design decisions are
recorded as ADRs under `dotfiles-tui/docs/architecture/`.

## 🚀 Bootstrap on a New Machine

One-liner — works on a fresh machine *or* when re-enrolling one that already has `~/.dotfiles`:

```bash
git clone https://github.com/aaronsb/dotfiles.git ~/.dotfiles 2>/dev/null || git -C ~/.dotfiles pull --ff-only
~/.dotfiles/bootstrap.sh
```

> Not `curl | bash`: bootstrap **must** run from inside the clone — it reads the
> repo (the manifest and the pinned CLI version) and deploys from it. Cloning
> first also gives you a repo you can inspect. The line clones if `~/.dotfiles`
> is absent and fast-forwards it if it's already there, so it's safe to re-run
> for re-enrollment. (A `--ff-only` that can't fast-forward means the local
> checkout has diverged; reconcile it by hand rather than clobbering it.)

Or step by step:

```bash
# clone if new, or fast-forward an existing checkout
git clone https://github.com/aaronsb/dotfiles.git ~/.dotfiles 2>/dev/null || git -C ~/.dotfiles pull --ff-only
~/.dotfiles/bootstrap.sh   # interactive setup
source ~/.zshrc            # reload your shell
```

The bootstrap script will:
- Install the `dotfiles` command — runs `install.sh`, which downloads the
  prebuilt Rust CLI to `~/.local/bin`, honoring the release pinned in
  `.dotfiles-cli.version` for a reproducible install
- Show current status
- Offer to deploy configs (with a preview option)

Already cloned and just need the command on a new shell? Run
`~/.dotfiles/install.sh` directly.

## 📋 Daily Commands

```bash
dotfiles status     # What's deployed?
dotfiles list       # What's managed?
dotfiles show <app> # One config in full: rationale, spec, deploy state
```

Since everything deploys as symlinks, editing either `~/.tmux.conf` or
`~/.dotfiles/tmux/.tmux.conf` edits the same file — `git status` in
`~/.dotfiles` is your source of truth for "what changed".

## 🛠️ All Commands

**Configs (symlink layer)**

| Command | Description | Example |
|---------|-------------|---------|
| `status` | Show what's deployed vs available | `dotfiles status` |
| `deploy` | Create symlinks to activate configs | `dotfiles deploy --dry-run` |
| `add` | Add a new app to the manifest | `dotfiles add nvim .config/nvim` |
| `enable` | Enable a disabled config | `dotfiles enable vim` |
| `disable` | Disable a config (removes its symlink) | `dotfiles disable tmux` |
| `remove` | Drop an entry from the manifest (leaves deployed files) | `dotfiles remove vim` |
| `list` | Show all managed configs | `dotfiles list` |
| `show` | One config in full: `why`, structured spec, deploy state | `dotfiles show waydesk` |

**Sync (git layer)**

| Command | Description | Example |
|---------|-------------|---------|
| `diff` | Preview local state vs origin | `dotfiles diff --details` |
| `pull` | Fast-forward pull from origin | `dotfiles pull` |
| `push` | Commit + push to origin | `dotfiles push -m "tmux: ..."` |

**Profiles (named scopes per machine/role)**

| Command | Description | Example |
|---------|-------------|---------|
| `profile list` | List declared profiles, active one marked | `dotfiles profile list` |
| `profile use` | Record the active profile for this host | `dotfiles profile use slab` |
| `profile add` | Declare a profile and create its package dir | `dotfiles profile add cube` |
| `profile copy` | Copy memberships / package lists between profiles | `dotfiles profile copy slab cube` |
| `profile remove` | Drop a profile from the registry | `dotfiles profile remove cube` |

**Packages (system layer, Arch family)**

| Command | Description | Example |
|---------|-------------|---------|
| `pkg capture` | Write this host's live package lists to disk | `dotfiles pkg capture` |
| `pkg status` | Per-source drift (tracked vs installed) | `dotfiles pkg status` |
| `pkg sync` | Install tracked-but-missing (`--prune` removes extras) | `dotfiles pkg sync` |
| `pkg diff` | Compare tracked lists across hosts | `dotfiles pkg diff north slab` |

Run `dotfiles help` (or `dotfiles --help`) for the full command reference.

### Updating the tool

The CLI is a prebuilt binary, not a symlink into the repo, so it doesn't
self-update. To move to a newer release, bump `.dotfiles-cli.version` (or remove
it to track latest) and re-run `~/.dotfiles/install.sh`.

## 📁 Directory Structure

```
~/.dotfiles/
├── dotfiles-tui/            # Rust CLI source (its own repo)
│   ├── crates/             #   dotfiles-cli (surface) + dotfiles-core (manifest, deploy, pkg)
│   └── docs/architecture/  #   ADRs — the recorded design decisions
├── bootstrap.sh            # New-machine entry point: install the CLI, then deploy
├── install.sh              # Downloads the prebuilt `dotfiles` CLI → ~/.local/bin
├── .dotfiles-cli.version   # Pinned CLI release, for reproducible installs
├── .dotfiles-manifest.toml # The manifest: what's managed, why, and optional spec
├── CLAUDE.md               # AI assistant instructions
├── readme.md               # This file
│
├── tmux/         # → ~/.tmux.conf
├── zsh/          # → ~/.zshrc, ~/.zprofile, ~/.zsh (conf.d fragments + host.d/)
├── oh-my-posh/   # → ~/.config/oh-my-posh/* and ~/.local/bin/posh-theme
├── nvim/         # → ~/.config/nvim
├── mlterm/       # → ~/.mlterm/* and framebuffer-terminal launchers on PATH
├── tmux-menu/    # → ~/.config/tmux-menu/menus.toml
├── polkit/       # polkitctl + inert polkit rule fragments (applied manually)
├── waydesk/      # remote Wayland desktop launcher (waypipe + ssh)
└── packages/     # Per-host package lists (pkg subsystem, not symlinked)
    └── <hostname>/   #   native.txt · aur.txt · flatpak.txt
```

The manifest (`.dotfiles-manifest.toml`) is self-documenting: each `[[entry]]`
carries a `why` rationale and an optional structured `spec` (requirements,
platform, tags). `dotfiles show <app>` renders it. See the file header and ADR-002
/ ADR-003 / ADR-006 for the schema.

## 💡 Helpful Reminders

### Making Changes
1. **Edit in either location** — changes to `~/.tmux.conf` or `~/.dotfiles/tmux/.tmux.conf` affect both
2. **Test before committing** — make sure your changes work!
3. **Use descriptive commits** — future you will thank present you

### Good Git Commit Messages
```bash
# Format: <app>: <what changed and why>

git add tmux/.tmux.conf
git commit -m "tmux: Add weather widget to status bar

- Shows current temperature and conditions
- Updates every 30 minutes
- Only active when online"
```

### Adding New Tools
```bash
# Example: add a neovim config
dotfiles add nvim .config/nvim --why "Editor config carried whole"

# Drop the actual config files into nvim/ before deploying, then:
dotfiles deploy
git add nvim/ .dotfiles-manifest.toml
git commit -m "nvim: Add initial neovim configuration"
```

### Syncing Changes

The tool wraps git so you don't drop to raw commands:

```bash
# Push your changes (prompts for a commit message)
dotfiles push
dotfiles push -m "tmux: add weather widget"   # one-shot, no prompt

# On another machine — pull, then re-deploy
dotfiles diff --details    # what would pull/push do?
dotfiles pull              # fast-forward only
dotfiles deploy            # symlink any new configs
```

### Tracking Packages (Arch family)

Record what's explicitly installed per host, so a rebuild is reproducible:

```bash
dotfiles pkg status        # drift: tracked vs actually installed
dotfiles pkg capture       # write live state → packages/<host>/*.txt
dotfiles push              # commit the lists

# On a new machine, after pulling:
dotfiles pkg sync          # install tracked-but-missing (additive)
dotfiles pkg sync --prune  # also remove untracked (sharper edge)
```

Sources (native/AUR/flatpak) absent on a host are skipped, not errored.

## 🔧 How It Works

Managed configs are deployed as **symbolic links**:
- Real files live in `~/.dotfiles/<app>/`
- System locations hold symlinks pointing back to them
- Git tracks the real files in the repo
- An edit in either place changes the same bytes

```
~/.tmux.conf → ~/.dotfiles/tmux/.tmux.conf
     ↑                      ↑
  symlink              real file
```

(A few entries deploy in *copy* mode instead — for directories that need a full
copy. The manifest's `mode` field records which.)

## 🆘 Troubleshooting

### Command not found
```bash
# Make sure ~/.local/bin is in PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Deployment conflicts
```bash
dotfiles status            # see what's blocking
dotfiles deploy --force    # back up existing files, then overwrite
ls ~/.dotfiles-backup/     # check the backups
```

### Accidental changes
```bash
# Configs are symlinks, so git in the repo tells you what changed
cd ~/.dotfiles && git status && git diff

git checkout -- <file>     # restore from repo
# or restore from a deploy backup:
cp ~/.dotfiles-backup/.tmux.conf.20240315_142035 ~/.tmux.conf
```

## 📝 Notes for Future Me

- **Commit often** — small, focused changes are easier to understand
- **Document weird configs** — use the manifest `why`/`spec` and inline comments
- **Test on fresh systems** — spin up a VM occasionally to test bootstrap
- **Review old configs** — `git log --grep="tmux"` to see evolution
- **Keep it simple** — resist the urge to over-engineer
