# Copy to config.sh and edit. config.sh is sourced by open-latest-als.sh.

# Folder to search recursively for .als files. "~" is expanded.
PROJECTS_DIR="~/Music/Ableton"

# Ableton app name as it appears in /Applications, without ".app".
# Leave empty to auto-detect (works when only one edition is installed).
# Options: "Ableton Live 12 Suite", "Ableton Live 12 Standard", "Ableton Live 12 Intro", etc.
APP=""

# Seconds to wait after login before launching (lets audio devices load).
STARTUP_DELAY=5

# 1 = ignore .als files inside Ableton's auto-generated Backup/ folders.
SKIP_BACKUPS=1
