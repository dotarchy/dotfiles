# dotfiles registry

Published dotfiles configurations for the [`dotfiles`](https://github.com/dotarchy/dotfiles-cli)
CLI — the library half of [dotarchy](https://dotarchy.sh).

Start here:

```bash
curl -fsSL https://raw.githubusercontent.com/dotarchy/dotfiles-cli/main/bootstrap.sh | bash
```

Read it before you run it — the CLI's README says why and how.

Each `configs/<id>/` is a complete configuration: a self-documenting manifest
plus the files it names. `registry.toml` indexes them. A host picks one with
`dotfiles init --config <id>`; the store it creates descends from that entry and
pulls updates with `dotfiles store upstream pull`.

## What's here

| Id | What |
|---|---|
| `sh.dotarchy.starter` | A working, unremarkable, nobody's setup: tmux, zsh. The default for a fresh host. |
| `com.bockelie.dotfiles` | The founder's configuration: zsh + oh-my-posh, tmux, nvim, an mlterm console, Claude Code settings. |

`dotfiles store registry` lists the same table from the CLI.

## Contributing a configuration

Ids are reverse-DNS — `com.example.dotfiles`, `com.example.minimal` — and the
domain half is yours. Open a pull request that adds `configs/<id>/` and a row in
`registry.toml`. An entry carries no profiles, variants, package lists, or
engine scripts; those belong to the store. Every entry keeps a `why` on each
manifest row, and where it builds on someone else's work the `why` names the
upstream.

Design: [ADR-013](https://github.com/dotarchy/dotfiles-cli/blob/main/docs/architecture/foundation/) in dotfiles-cli.
