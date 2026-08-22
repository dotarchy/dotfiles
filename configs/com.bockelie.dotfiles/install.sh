#!/bin/bash

# Install the dotfiles tooling: the Rust `dotfiles` CLI (prebuilt binary) as the
# sole command. It reads the TOML manifest (.dotfiles-manifest.toml).
#
# The store pins the CLI it expects in .dotfiles-cli.version, and this installs
# that version so every machine runs the same binary (ADR-200). Pass --latest to
# install the newest release instead — that is how a new pin gets chosen, after
# which commit the pin so other machines follow.

set -euo pipefail

# Resolve the pin next to this script, not next to wherever it was invoked from.
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIN_FILE="$REPO_DIR/.dotfiles-cli.version"

LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"

VERSION="latest"
case "${1:-}" in
    --latest) ;;
    "")
        # An unpinned store predates ADR-200 and keeps tracking latest.
        if [[ -f "$PIN_FILE" ]]; then
            pin="$(tr -d '[:space:]' < "$PIN_FILE")"
            if [[ -n "$pin" ]]; then
                # Validate before the pin reaches a URL. It is one line in a
                # file reviewers skim, and curl collapses `..` before the
                # request — so an unchecked pin can redirect the download to
                # another repo and land it on $PATH.
                if [[ ! "$pin" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.]+)?$ ]]; then
                    echo "install.sh: $PIN_FILE is not a version: '$pin'" >&2
                    echo "  expected something like v0.5.0 — refusing to fetch it" >&2
                    exit 65
                fi
                VERSION="v${pin#v}"   # releases are tagged vX.Y.Z
            fi
        fi
        ;;
    *)
        echo "usage: install.sh [--latest]" >&2
        exit 64
        ;;
esac

# Pin the delivery mechanism too, not just the payload: for a pinned install,
# fetch the installer from that tag rather than tip-of-main, so the whole
# install is reproducible. --latest has no tag to pin to and tracks main.
if [[ "$VERSION" == "latest" ]]; then
    echo "Installing the Rust 'dotfiles' CLI (latest release)..."
    INSTALLER_REF="main"
else
    echo "Installing the Rust 'dotfiles' CLI ($VERSION, pinned by this store)..."
    INSTALLER_REF="$VERSION"
fi

curl -fsSL "https://raw.githubusercontent.com/aaronsb/dotfiles-cli/$INSTALLER_REF/install.sh" \
    | DOTFILES_VERSION="$VERSION" bash

echo
echo "Done: 'dotfiles' installed."
if [[ "$VERSION" == "latest" ]]; then
    resolved="$(dotfiles --version 2>/dev/null | awk '{print $2}')"
    echo "Installed ${resolved:-?}. To make other machines follow:"
    echo "  echo v${resolved:-X.Y.Z} > $PIN_FILE && git commit -am 'dotfiles: Pin CLI to v${resolved:-X.Y.Z}'"
else
    echo "Next: 'dotfiles deploy' to symlink your configs."
fi
