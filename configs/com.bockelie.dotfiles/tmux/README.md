# tmux — CUA menu bar, self-teaching keys, persistent, remote-friendly

A tmux config built around one goal: **a familiar, discoverable interface so I
actually _use_ persistent shells** — especially on remote machines. DOS / Turbo
Vision muscle memory, in plain tmux, everywhere.

## Design intent (the "why")

- **tmux, not zellij.** zellij was evaluated seriously — its WASM plugin system
  can render an integrated top menu bar and ships a session-manager for free.
  But the whole driver here is _familiarity_, and zellij's different paradigm
  fights that. tmux is where the muscle memory lives, it's installed everywhere,
  and it's deeply scriptable. **Familiarity beat the nicer tech.**
- **Native `display-menu`, not a custom popup.** A Python/curses popup menu bar
  was prototyped — it could do live Left/Right cycling between menus. Rejected:
  ~75–100 ms launch latency per open, and it painted over the screen. Native
  `display-menu` is instant and only covers its own dropdown. Trade-off: no
  arrow-cycling between open menus — **accepted**. (Prototype shelved at
  `~/Projects/apps/tmux-menu`.)
- **Discoverability _is_ the feature.** The menu bar, the clickable status
  buttons, the live `Mouse:on/off` indicator, and the `Ctrl-B` chip all exist so
  the keyboard/persistence layer is _visible_ — not a command you must recall.
  That visibility is what gets it used. It's a human thing.
- **One key per action, shown the same everywhere.** Each action has exactly one
  key, and that key appears identically in the status bar, the dropdown menu, and
  the prefix table. `Ctrl-B p` = the `Prev` button = Window → Previous. Learn it
  once, anywhere.
- **The accelerator convention.** Status-bar buttons spell the action as a
  **word with the key-letter underlined+bold** — the underlined letter _is_ the
  key (DOS/CUA menus, nano's bottom bar). The label can't lie about the key the
  way a bare glyph can (an earlier `‹ ›` design implied `<`/`>` but was bound
  `p`/`n` — exactly the mismatch this fixes).
- **Destructive actions are fenced off.** "Quit tmux" (kill-server) lives in a
  separate red **Admin** menu behind a confirm prompt — never one slip away from
  the everyday "Detach" on the File menu.

## What's here

### The status bar

- **Menu bar** (left): File / Edit / View / Window / Session / **Admin**.
  Click a label, or **F12 / Shift-F10** then the mnemonic
  (`f e v w s a`, plus `m` = direct mouse toggle).
- **`Ctrl-B` chip** (right): spells out the prefix key; **gray when idle,
  orange while the prefix is held**. Replaces the old jumpy `PREFIX` badge —
  fixed width, so nothing in the bar shifts when you tap the prefix.
- **Action buttons** (right) — each is clickable _and_ shows its key:

  | Button | Key (`Ctrl-B` +) | Action |
  |---|---|---|
  | `Split ║` | `)` | split side-by-side |
  | `Split ═` | `(` | split stacked |
  | `[T]ab` | `t` | new window |
  | `[P]rev` | `p` | previous window |
  | `[N]ext` | `n` | next window |
  | `[R]esize` | `r` | resize mode |
  | `[M]ouse:on` | `m` | toggle mouse (green=on / red=off) |

  Letters stay underlined always (passive teaching); the two split **symbol**
  keys appear in a padded slot only while the prefix is held. Every
  prefix-conditional segment is equal-width, so holding `Ctrl-B` causes **zero
  reflow**.

### Menus (same keys as the bar)

- **File** — New **T**ab (t) · Split side-by-side (`)`) · Split stacked (`(`) ·
  Close Pane (x) · Close Window (w, confirmed) · **D**etach (D).
- **Edit** — Copy Mode (c) · Paste (p) · Search (/).
- **View** — Layouts (h/v/t) · Zoom (z) · **M**ouse toggle (m).
- **Window** — **N**ext (n) · **P**revious (p) · Rename (r).
- **Session** — **A**ttach / List = `choose-tree -Zs` (the visual resume picker)
  · New (s) · Rename (r).
- **Admin** (red) — Reload Config (R) · Quit tmux / kill ALL sessions
  (Q, confirmed). System & destructive actions, kept off the everyday menus.

### Everything else

- **Mouse** unified on **`m`**: `prefix m`, **F12 → m**, or click the
  `Mouse:on` button. When off, re-enable from the keyboard via F12 → m or
  F12 → View → Mouse toggle. Off = native terminal copy/paste; on = clickable UI.
- **New window/tab** also on `prefix t` (matches the `[T]ab` button; default
  `prefix c` still works — only `prefix t` = clock is given up, and the clock is
  always on the bar anyway).
- **Truecolor**: `default-terminal tmux-256color` + `RGB` passthrough, so 24-bit
  colors render verbatim instead of being quantized to 256 (which looked dim).
- **Persistence**: tmux-resurrect + tmux-continuum (auto-save every 15 min,
  auto-restore on server start → survives reboot). `prefix Ctrl-s` save,
  `prefix Ctrl-r` restore. Requires TPM:
  `git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm` then `prefix I`.
- **Remote resume**: `smux user@host` (zsh function — see
  `zsh/.zsh/conf.d/70-aliases`) = ssh + attach/create a persistent session, with
  a UTF-8 `LANG` so nerd glyphs render.

## Gotchas (hard-won — don't rediscover these)

- **Reload vs restart are different.** Most edits apply on **reload** — Admin →
  Reload Config or `prefix R`. But `default-terminal` (truecolor) is read only
  when the **server starts**, so changing it needs a full **`tmux kill-server`**,
  not a reload. A running tmux otherwise keeps OLD bindings until reloaded — this
  cost hours of "but I changed it." (Same for the `smux` zsh function: open a
  fresh terminal or re-`source` it.)
- **Remote nerd glyphs need a UTF-8 locale on the tmux _server_.** ssh doesn't
  forward `$LANG` and command-exec skips `/etc/locale.conf`, so tmux starts in
  C/POSIX and mangles Private-Use glyphs into `_`. `smux` prefixes
  `LANG=en_US.UTF-8`. The server locks its charset at _startup_ — so to change it
  you must restart the remote server (reattaching keeps the old mode).
- **`set` doesn't expand `#{...}` in an option value — use `set -gF`.** Plain
  `set -g mouse "#{?mouse,off,on}"` sets the literal string → "Bad Value". The
  `-F` flag expands the format. (This is how all three mouse toggles work.)
- **Quote `#{...}` formats inside `{ }` blocks.** tmux's block parser counts the
  `{` in a bare `#{?...}` as a block brace → "unclosed block / syntax error at
  EOF". Always `"#{?mouse,off,on}"`, never bare, inside `if … { … }`.
- **Commas inside `#{?a,b,c}` are branch delimiters.** A literal comma in a
  branch (e.g. `#[bg=colour22,fg=colour231]`) breaks the conditional — split the
  style into `#[bg=colour22]#[fg=colour231]`. This bites hardest in the
  status-bar conditionals.
- **`#[none]` clears attributes but keeps colors.** It's how an underlined
  accelerator letter returns to normal weight mid-word. The bar re-asserts
  `bg`/`fg` right after each `#[none]` anyway — cheap insurance so a button's
  background can never leak.
- **Each menu is defined _twice_** — once in the `menubar` key-table (keyboard,
  fixed `-x` under its label) and once in the `MouseDown1Status` dispatcher
  (mouse, `-x M` at the cursor). tmux can't share one definition between them, so
  **edit both in lockstep** or the click and the key will disagree.
- **Block separator is `;`, not `\;`.** `\;` is for _outside_ blocks
  (`bind k a \; b`); inside `{ … }` use a plain `;`.

## Related

- `zsh/.zsh/conf.d/70-aliases` — `smux` / `sshmux` remote-resume functions.
- `~/Projects/apps/tmux-menu` — shelved Python/curses popup-menu prototype with
  declarative TOML menus; revisit if a Rust (cursive) port is ever wanted.
