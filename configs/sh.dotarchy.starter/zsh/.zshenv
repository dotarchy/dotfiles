#!/usr/bin/env zsh
# ~/.zshenv — sourced by EVERY zsh: interactive, login, non-interactive, scripts.
#
# PATH is composed here, NOT in .zshrc/conf.d, because .zshrc is interactive-only.
# Shells from `ssh host cmd`, cron, systemd units, and agent tool runners are
# login-but-non-interactive: they never load conf.d, so a PATH composed there can
# only be inherited from a parent — correct by luck of ancestry, and absent the
# moment nothing interactive is upstream.
#
# Keep this lean and side-effect-free: env only. No output, no prompts, no tool
# hooks (direnv stays in conf.d/90-tools) — this runs for every script too, and
# anything that prints here corrupts `ssh host cmd` stdout.
#
# ORDERING: on Arch, /etc/zsh/zprofile sources /etc/profile AFTER this file. That
# only ever appends to PATH (append_path), never assigns it, so these prepends
# survive and distro dirs land behind them. Check that assumption before trusting
# this file on a non-Arch host.

typeset -U path PATH

path=(
  "$HOME/.local/bin"
  "$HOME/.npm-global/bin"
  "$HOME/go/bin"
  "$HOME/.cargo/bin"
  $path
)

export GOPATH="$HOME/go"
