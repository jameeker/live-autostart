#!/bin/bash
# Installs the open-latest-als LaunchAgent so it runs at login.
#
#   ./install.sh              install (or reinstall after editing files)
#   ./install.sh --run        trigger script now without logging out
#   ./install.sh --uninstall  remove the agent
set -euo pipefail

LABEL="com.github.open-latest-als" # any reverse-DNS style name is fine
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$REPO_DIR/open-latest-als.sh"
TEMPLATE="$REPO_DIR/launchagent.plist"
CONFIG="$REPO_DIR/config.sh"
AGENTS_DIR="$HOME/Library/LaunchAgents"
TARGET="$AGENTS_DIR/$LABEL.plist"
LOG_DIR="$HOME/Library/Logs/open-latest-als"
DOMAIN="gui/$(id -u)"

unload() { launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true; }

case "${1:-}" in
  --uninstall)
    unload
    rm -f "$TARGET"
    echo "Uninstalled $LABEL"
    exit 0 ;;
  --run)
    launchctl kickstart "$DOMAIN/$LABEL"
    echo "Triggered. Logs: $LOG_DIR"
    exit 0 ;;
  "") ;;
  *) echo "Usage: $0 [--run|--uninstall]" >&2; exit 2 ;;
esac

[[ "$(uname)" == "Darwin" ]] || { echo "macOS only." >&2; exit 1; }
[[ -f "$SCRIPT" ]]   || { echo "Missing $SCRIPT" >&2; exit 1; }
[[ -f "$TEMPLATE" ]] || { echo "Missing $TEMPLATE" >&2; exit 1; }

if [[ ! -f "$CONFIG" ]]; then
  cp "$REPO_DIR/config.example.sh" "$CONFIG"
  echo "Created $CONFIG from the example — edit it if the defaults aren't right."
fi

chmod +x "$SCRIPT"
mkdir -p "$AGENTS_DIR" "$LOG_DIR"

sed -e "s|__LABEL__|$LABEL|g" \
    -e "s|__SCRIPT_PATH__|$SCRIPT|g" \
    -e "s|__LOG_PATH__|$LOG_DIR/stdout.log|g" \
    -e "s|__ERR_PATH__|$LOG_DIR/stderr.log|g" \
    "$TEMPLATE" > "$TARGET"

plutil -lint "$TARGET" >/dev/null

unload
launchctl bootstrap "$DOMAIN" "$TARGET"

echo "Installed $LABEL"
echo "  script: $SCRIPT"
echo "  config: $CONFIG"
echo "  plist:  $TARGET"
echo "  logs:   $LOG_DIR"
echo "Test by running: ./install.sh --run"
