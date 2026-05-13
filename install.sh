#!/usr/bin/env bash
# =============================================================================
# dotfiles/install.sh — Bootstrap symlinks
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
BASHRC_SRC="$REPO_DIR/bash/bashrc"
BASHRC_DST="$HOME/.bashrc"
SWITCH_SRC="$REPO_DIR/bin/claude-switch"
SWITCH_DST="$HOME/.local/bin/claude-switch"
BACKUP_DIR="$HOME/.bashrc-backups"
OS="$(uname -s)"

echo "📦 Dotfiles installer"
echo "   Repo: $REPO_DIR"
echo "   OS:   $OS"
echo ""

# --- macOS: require Homebrew bash (system bash 3.2 is too old) ---------------
if [ "$OS" = "Darwin" ]; then
    BREW_BASH="/opt/homebrew/bin/bash"
    if [ ! -x "$BREW_BASH" ]; then
        BREW_BASH="/usr/local/bin/bash"
    fi
    if [ ! -x "$BREW_BASH" ]; then
        echo "⚠️  macOS system bash is too old (3.2). Install Homebrew bash:"
        echo "   brew install bash"
        echo "   sudo chsh -s /opt/homebrew/bin/bash \$USER"
        echo ""
        read -p "Continue without Homebrew bash? (y/N): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            exit 1
        fi
    else
        echo "✅ Homebrew bash: $BREW_BASH ($("$BREW_BASH" --version | head -1))"
        if [ "$SHELL" != "$BREW_BASH" ]; then
            echo "⚠️  Current shell is $SHELL, not $BREW_BASH"
            echo "   Run: sudo chsh -s $BREW_BASH \$USER"
            echo ""
        fi
    fi
    echo ""
fi

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

# Install local tools
if [ -f "$SWITCH_SRC" ]; then
    mkdir -p "$HOME/.local/bin"
    chmod +x "$SWITCH_SRC"

    if [ -e "$SWITCH_DST" ] && [ ! -L "$SWITCH_DST" ]; then
        mkdir -p "$BACKUP_DIR"
        BACKUP_NAME="claude-switch-$(date +%Y%m%d-%H%M%S)"
        cp "$SWITCH_DST" "$BACKUP_DIR/$BACKUP_NAME"
        echo "✅ Backed up existing claude-switch → $BACKUP_DIR/$BACKUP_NAME"
    fi

    ln -sfn "$SWITCH_SRC" "$SWITCH_DST"
    echo "🔗 Installed claude-switch → $SWITCH_SRC"
fi

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
