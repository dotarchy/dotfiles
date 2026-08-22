#!/bin/bash

# Bootstrap script for dotfiles
# This script sets up everything needed after cloning the repo

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_BIN="$HOME/.local/bin"
DOTFILES_CMD="$LOCAL_BIN/dotfiles"   # the installed Rust CLI (absolute, PATH-independent)

echo -e "${BLUE}=== Dotfiles Bootstrap ===${NC}"
echo

# Step 1: Install the tooling (Rust `dotfiles` CLI).
# Honor the version pin so a fresh machine installs exactly the CLI release this
# store expects — a reproducible fleet, not whatever happens to be `latest`.
# Falls back to `latest` when the pin file is absent.
echo -e "${GREEN}Step 1: Installing dotfiles command...${NC}"
PIN_FILE="$DOTFILES_DIR/.dotfiles-cli.version"
if [[ -f "$PIN_FILE" ]]; then
    DOTFILES_VERSION="$(tr -d '[:space:]' < "$PIN_FILE")" "$DOTFILES_DIR/install.sh"
else
    "$DOTFILES_DIR/install.sh"
fi

# Check if ~/.local/bin is in PATH (affects how later steps invoke the command)
PATH_WARNING=false
if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
    PATH_WARNING=true
fi

echo

# Step 2: Show current status
echo -e "${GREEN}Step 2: Checking dotfiles status...${NC}"
if $PATH_WARNING; then
    # Run directly if not in PATH
    "$DOTFILES_CMD" status
else
    "$DOTFILES_CMD" status
fi

echo

# Step 3: Offer to deploy
echo -e "${GREEN}Step 3: Deploy configuration${NC}"
echo "Your dotfiles are ready to be deployed."
echo
echo "Options:"
echo "  1) Deploy with --dry-run (preview changes)"
echo "  2) Deploy with --force (backup existing files)"
echo "  3) Skip deployment for now"
echo

read -p "Choose an option [1-3]: " -n 1 -r choice
echo

case $choice in
    1)
        echo -e "${BLUE}Running deployment preview...${NC}"
        if $PATH_WARNING; then
            "$DOTFILES_CMD" deploy --dry-run
        else
            "$DOTFILES_CMD" deploy --dry-run
        fi
        echo
        read -p "Deploy for real? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if $PATH_WARNING; then
                "$DOTFILES_CMD" deploy --force
            else
                "$DOTFILES_CMD" deploy --force
            fi
        fi
        ;;
    2)
        echo -e "${BLUE}Deploying with backup...${NC}"
        if $PATH_WARNING; then
            "$DOTFILES_CMD" deploy --force
        else
            "$DOTFILES_CMD" deploy --force
        fi
        ;;
    3)
        echo "Skipping deployment."
        ;;
    *)
        echo "Invalid option. Skipping deployment."
        ;;
esac

echo

# Step 4: Final instructions
echo -e "${GREEN}Bootstrap complete!${NC}"
echo

if $PATH_WARNING; then
    echo -e "${YELLOW}IMPORTANT: Add this to your shell config to use 'dotfiles' command:${NC}"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo
    echo "Then reload your shell or run: source ~/.zshrc"
    echo
fi

echo "Next steps:"
echo "  - Review deployed files with: dotfiles status"
echo "  - See all commands with: dotfiles --help"
echo "  - Add new configs with: dotfiles add <app> <path>"
echo

# Offer to set up git remote if not already set
if ! git remote -v 2>/dev/null | grep -q origin; then
    echo -e "${YELLOW}No git remote detected. Don't forget to:${NC}"
    echo "  git remote add origin <your-repo-url>"
    echo "  git push -u origin main"
fi