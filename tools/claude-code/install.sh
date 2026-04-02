#!/usr/bin/env bash
# Claude Code — Statusline installer
# Copies the statusline script and configures settings.json
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
TARGET="$CLAUDE_DIR/statusline-command.sh"
SETTINGS="$CLAUDE_DIR/settings.json"

echo "╔══════════════════════════════════════════╗"
echo "║  Claude Code — Statusline Installer      ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ── Prerequisites check ──────────────────────────
check_cmd() {
  if ! command -v "$1" &>/dev/null; then
    echo "  ✗ $1 — NOT FOUND"
    return 1
  else
    echo "  ✓ $1"
    return 0
  fi
}

echo "Checking dependencies..."
missing=0
check_cmd jq    || missing=1
check_cmd git   || missing=1
check_cmd awk   || missing=1
check_cmd perl  || missing=1
echo ""

if [ "$missing" -eq 1 ]; then
  echo "⚠ Missing dependencies. Install them before continuing:"
  echo "  brew install jq     (macOS)"
  echo "  scoop install jq    (Windows)"
  echo "  apt install jq      (Linux)"
  echo ""
  read -p "Continue anyway? [y/N] " -n 1 -r
  echo ""
  [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

# ── Nerd Font check ──────────────────────────────
echo "Checking for Nerd Font..."
nerd_found=false
if command -v fc-list &>/dev/null; then
  fc-list | grep -qi "nerd" && nerd_found=true
fi
# Windows fallback
if [ "$nerd_found" = false ] && [ -d "/c/Windows/Fonts" ]; then
  ls /c/Windows/Fonts/*erd* &>/dev/null 2>&1 && nerd_found=true
fi
if [ "$nerd_found" = true ]; then
  echo "  ✓ Nerd Font detected"
else
  echo "  ⚠ Nerd Font not detected — icons may not render"
  echo "  Install: https://www.nerdfonts.com/font-downloads"
  echo "  Recommended: FiraCode Nerd Font"
fi
echo ""

# ── Create ~/.claude if needed ───────────────────
mkdir -p "$CLAUDE_DIR"

# ── Copy statusline script ───────────────────────
echo "Installing statusline script..."
cp "$SCRIPT_DIR/statusline-command.sh" "$TARGET"
chmod +x "$TARGET"
echo "  ✓ Copied to $TARGET"
echo ""

# ── Configure settings.json ──────────────────────
echo "Configuring settings.json..."

# Detect shell and build command path
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "mingw"* || "$OSTYPE" == "cygwin" ]]; then
  # Windows — use bash -l with /c/ path
  win_path=$(cygpath -m "$TARGET" 2>/dev/null || echo "$TARGET")
  sl_command="bash -l $win_path"
else
  # macOS / Linux
  sl_command="bash $TARGET"
fi

if [ -f "$SETTINGS" ]; then
  # Backup existing settings
  cp "$SETTINGS" "$SETTINGS.bak"
  echo "  ✓ Backed up existing settings to settings.json.bak"

  # Update or add statusLine config
  tmp=$(mktemp)
  jq --arg cmd "$sl_command" '.statusLine = {"type": "command", "command": $cmd}' "$SETTINGS" > "$tmp"
  mv "$tmp" "$SETTINGS"
  echo "  ✓ Updated statusLine in settings.json"
else
  # Create minimal settings.json
  cat > "$SETTINGS" << JSONEOF
{
  "statusLine": {
    "type": "command",
    "command": "$sl_command"
  }
}
JSONEOF
  echo "  ✓ Created settings.json with statusLine config"
fi
echo ""

# ── Verify ───────────────────────────────────────
echo "Verifying installation..."
test_json='{"model":{"display_name":"Test","id":"claude-opus-4-6"},"context_window":{"used_percentage":50},"workspace":{"current_dir":"'$HOME'"},"rate_limits":{},"cost":{}}'
output=$(echo "$test_json" | bash "$TARGET" 2>/dev/null)
if [ -n "$output" ]; then
  echo "  ✓ Statusline script works!"
  echo ""
  echo "Preview:"
  echo "$output"
else
  echo "  ✗ Statusline script failed — check dependencies"
fi

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  Done! Restart Claude Code to see it.    ║"
echo "╚══════════════════════════════════════════╝"
