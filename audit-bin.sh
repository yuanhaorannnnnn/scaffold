#!/usr/bin/env bash
# =============================================================================
# audit-bin.sh — Audit ~/.local/bin to find who installed what
# =============================================================================

BINDIR="${1:-$HOME/.local/bin}"

echo "═══════════════════════════════════════════════════════════════════"
echo "  AUDIT: $BINDIR"
echo "═══════════════════════════════════════════════════════════════════"

# Pre-fetch pip-installed console_scripts for quick lookup
declare -A PIP_SCRIPTS
while IFS= read -r line; do
    # pip show -f outputs 'Location:' and 'Files:' sections
    # This is a lightweight heuristic: check if script name appears in pip metadata
    :
done < /dev/null

# Better approach: for each file, try to trace its origin
for f in "$BINDIR"/*; do
    [ -f "$f" ] || continue
    [ -x "$f" ] || continue

    name=$(basename "$f")
    size=$(stat -c%s "$f" 2>/dev/null || stat -f%z "$f" 2>/dev/null || echo "?")
    shebang=$(head -1 "$f" 2>/dev/null)

    # ── Determine source ──
    source="UNKNOWN"
    detail=""

    # 1. Check if managed by dpkg (Debian/Ubuntu package)
    if command -v dpkg >/dev/null 2>&1; then
        pkg=$(dpkg -S "$f" 2>/dev/null | cut -d: -f1)
        if [ -n "$pkg" ]; then
            source="📦 APT"
            detail="$pkg"
        fi
    fi

    # 2. Check shebang for Python → likely pip/conda
    if [ "$source" = "UNKNOWN" ]; then
        if [[ "$shebang" == *python* ]] || [[ "$shebang" == *Python* ]]; then
            # Try to find which pip package owns it
            # Heuristic: check if the script references a known package name
            content=$(cat "$f" 2>/dev/null)

            # pip-installed scripts typically call load_entry_point or import pkg_resources
            if [[ "$content" == *"pkg_resources"* ]] || [[ "$content" == *"importlib.metadata"* ]] || [[ "$content" == *"load_entry_point"* ]]; then
                source="🐍 PIP"
                # Try to extract package name from the script
                pkg_name=$(echo "$content" | grep -oE "[a-zA-Z0-9_-]+==[0-9]" | head -1 | sed 's/==.*//')
                [ -z "$pkg_name" ] && pkg_name=$(echo "$content" | grep -oE "'[a-zA-Z0-9_-]+'" | head -1 | tr -d "'")
                detail="${pkg_name:-(entry-point wrapper)}"
            elif [[ "$content" == *"pip"* ]] || [[ "$content" == *"setuptools"* ]]; then
                source="🐍 PIP"
                detail="(setuptools wrapper)"
            else
                # Pure Python script without pkg_resources → probably handwritten
                source="✏️  PYTHON"
                detail="(custom script)"
            fi
        fi
    fi

    # 3. Node / npm
    if [ "$source" = "UNKNOWN" ]; then
        if [[ "$shebang" == *node* ]] || [[ "$shebang" == *nodejs* ]]; then
            source="📦 NPM"
            detail="(node wrapper)"
        fi
    fi

    # 4. Shell scripts
    if [ "$source" = "UNKNOWN" ]; then
        if [[ "$shebang" == *bash* ]] || [[ "$shebang" == *sh* ]] || [[ "$shebang" == *zsh* ]]; then
            # Small scripts are likely custom; large ones might be installed
            if [ "$size" -lt 2048 ]; then
                source="✏️  SHELL"
                detail="(custom script, ${size}B)"
            else
                source="📦 SYS"
                detail="(shell wrapper, ${size}B)"
            fi
        fi
    fi

    # 5. Binary / compiled
    if [ "$source" = "UNKNOWN" ]; then
        if [[ "$shebang" == \#\!* ]]; then
            source="📦 OTHER"
            detail="($shebang)"
        else
            # No shebang = binary
            source="⚙️  BINARY"
            filetype=$(file -b "$f" 2>/dev/null | cut -d, -f1)
            detail="(${filetype:-compiled binary})"
        fi
    fi

    # ── Output ──
    printf "%-24s %s %s\n" "$name" "$source" "$detail"
done

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "  LEGEND"
echo "═══════════════════════════════════════════════════════════════════"
echo "  ✏️  SHELL / ✏️  PYTHON  → 大概率是你自己写的"
echo "  🐍 PIP                   → pip install --user 安装的包"
echo "  📦 NPM                  → npm install -g 安装的包"
echo "  📦 APT / 📦 SYS         → 系统/包管理器安装的"
echo "  ⚙️  BINARY              → 编译好的二进制文件"
echo ""
echo "  建议：把 ✏️ 标记的脚本移到 ~/scripts/ 集中管理"
echo "═══════════════════════════════════════════════════════════════════"
