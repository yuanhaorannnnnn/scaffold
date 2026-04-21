#!/usr/bin/env bash
# =============================================================================
# dotfiles/install.sh — Bootstrap symlinks
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BASHRC_SRC="$REPO_DIR/bash/bashrc"
BASHRC_DST="$HOME/.bashrc"
BACKUP_DIR="$HOME/.bashrc-backups"

echo "📦 Dotfiles installer"
echo "   Repo: $REPO_DIR"
echo ""

# Backup existing ~/.bashrc if it's a real file (not already a symlink)
if [ -f "$BASHRC_DST" ] && [ ! -L "$BASHRC_DST" ]; then
    mkdir -p "$BACKUP_DIR"
    BACKUP_NAME="bashrc-$(date +%Y%m%d-%H%M%S)"
    cp "$BASHRC_DST" "$BACKUP_DIR/$BACKUP_NAME"
    echo "✅ Backed up existing ~/.bashrc → $BACKUP_DIR/$BACKUP_NAME"
fi

# Create symlink
if [ -L "$BASHRC_DST" ]; then
    echo "🔄 Updating existing symlink ~/.bashrc"
    rm "$BASHRC_DST"
else
    echo "🔗 Creating symlink ~/.bashrc → $BASHRC_SRC"
fi
ln -s "$BASHRC_SRC" "$BASHRC_DST"

# Check secrets
echo ""
if [ ! -f "$REPO_DIR/bash/secrets" ]; then
    echo "⚠️  secrets file not found. Copy from template:"
    echo "   cp $REPO_DIR/bash/secrets.example $REPO_DIR/bash/secrets"
    echo "   Then edit $REPO_DIR/bash/secrets with your real keys."
else
    echo "✅ secrets file exists"
fi

echo ""
echo "🎉 Done."
echo ""

# If sourced ( . install.sh ), reload inline; if executed ( ./install.sh ), remind user
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Sourced into current shell — reload inline
    echo "🔄 Reloading ~/.bashrc in current shell..."
    source ~/.bashrc
    echo "✅ Ready. Try: src, alias ls, kj"
else
    # Executed in subshell — current shell won't inherit
    echo "⚠️  Current shell is NOT affected (install.sh ran in a subshell)."
    echo "   Run one of the following to apply:"
    echo ""
    echo "      source ~/.bashrc          # apply in current terminal"
    echo "      . ~/.bashrc               # same thing, short form"
    echo "      exec bash                 # replace current shell with a new one"
    echo "      # OR simply open a new terminal window/tab"
    echo ""
fi
