#!/bin/bash
# Opens the most recently modified Ableton Live set (.als) in Ableton Live.
# Settings live in config.sh next to this script (see config.example.sh).
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---- defaults (override in config.sh) --------------------------------------
PROJECTS_DIR="$HOME/Music/Ableton" # Folder to search recursively
APP=""                             # "" to attempt to auto-detect the installed Live edition
STARTUP_DELAY=0                    # Seconds to wait before launching
SKIP_BACKUPS=1                     # 1 = ignore Ableton's Backup/ folders
# -----------------------------------------------------------------------------

if [[ -f "$SCRIPT_DIR/config.sh" ]]; then
  source "$SCRIPT_DIR/config.sh"
fi

PROJECTS_DIR="${PROJECTS_DIR/#\~/$HOME}" # Allow "~/..." in config

detect_app() {
  shopt -s nullglob
  local apps=(/Applications/Ableton\ Live\ *.app)
  shopt -u nullglob
  case ${#apps[@]} in
    0) echo "No Ableton Live app found in /Applications. Set APP in config.sh." >&2; return 1 ;;
    1) basename "${apps[0]}" .app ;;
    *) echo "Multiple Live editions installed; set APP in config.sh to one of:" >&2
       printf '  %s\n' "${apps[@]##*/}" | sed 's/\.app$//' >&2
       return 1 ;;
  esac
}

if [[ -z "$APP" ]]; then
  APP="$(detect_app)" || exit 1
fi

if [[ ! -d "$PROJECTS_DIR" ]]; then
  echo "PROJECTS_DIR does not exist: $PROJECTS_DIR" >&2
  exit 1
fi

(( STARTUP_DELAY > 0 )) && sleep "$STARTUP_DELAY"

FIND_ARGS=(-type f -name '*.als')
(( SKIP_BACKUPS )) && FIND_ARGS+=(-not -path '*/Backup/*')

# macOS/BSD stat: "%m %N" = mtime + path. Newest first, keep one.
LATEST=$(find "$PROJECTS_DIR" "${FIND_ARGS[@]}" -print0 \
  | xargs -0 stat -f '%m %N' 2>/dev/null \
  | sort -rn \
  | head -n 1 \
  | cut -d' ' -f2-)

if [[ -z "$LATEST" ]]; then
  echo "No .als files found under $PROJECTS_DIR" >&2
  exit 1
fi

echo "Opening: $LATEST"
exec open -a "$APP" "$LATEST"
