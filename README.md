# dotfiles registry

Published dotfiles configurations for the [`dotfiles`](https://github.com/aaronsb/dotfiles-cli) CLI.

Each `configs/<id>/` is a complete configuration: a self-documenting manifest
plus the files it names. `registry.toml` indexes them. A host picks one with
`dotfiles init --config <id>`; the store it creates descends from that entry and
pulls updates with `dotfiles store upstream pull`.

## Contributing a configuration

Ids are reverse-DNS — `com.example.dotfiles`, `com.example.minimal` — and the
domain half is yours. Open a pull request that adds `configs/<id>/` and a row in
`registry.toml`. An entry carries no profiles, variants, package lists, or
engine scripts; those belong to the store.

Design: dotfiles-cli ADR-013.
