# Ableton Live Autostart

Opens the most recently modified Ableton Live set (`.als`) automatically when you log in to macOS.

This script searches a configured directory recursively, and opens the newest set with a specific Ableton Live edition. The LaunchAgent runs at user login.

## Configure

Create a local config:

```zsh
cd live-autostart
cp config.example.sh config.sh
```

Edit `config.sh`:

```zsh
PROJECTS_DIR="/Users/you/Library/your/full/path/to/your/Ableton/projects"
APP="Ableton Live 12 Suite" # Your specific edition of Live
STARTUP_DELAY=5
SKIP_BACKUPS=1
```

Settings:

- `PROJECTS_DIR`: Directory searched recursively for `.als` files.
- `APP`: Application name as it appears in `/Applications`, without `.app`.
- `STARTUP_DELAY`: Seconds to wait after login before opening the set.
- `SKIP_BACKUPS`: Set to `1` to ignore `.als` files in Ableton `Backup` directories, or `0` to include them.

When a path is enclosed in double quotes, do not escape its spaces:

```zsh
# Correct
PROJECTS_DIR="/Users/you/Library/Mobile Documents/com~apple~CloudDocs/Sound/ABLETON/projects"

# Incorrect: the backslashes become part of the configured path
PROJECTS_DIR="/Users/you/Library/Mobile\ Documents/com\~apple\~CloudDocs/Sound/ABLETON/projects"
```

`config.sh` is ignored by Git so each machine can have its own settings.

Confirm the Ableton application name:

```zsh
test -d "/Applications/Ableton Live 12 Suite.app" && echo "Ableton found"
```

## Test the script manually

Make the scripts executable and run the opener directly:

```zsh
chmod +x open-latest-als.sh install.sh
./open-latest-als.sh
```

After `STARTUP_DELAY`, the command should report the selected set:

```text
Opening: /path/to/most-recent-set.als
```

The script uses `open -a "$APP"`, so the set is explicitly opened with Ableton Live 12 Suite regardless of its Finder file association.

## Install the LaunchAgent

```zsh
./install.sh
```

The installer creates the log directory, generates and validates the installed property list, and loads the LaunchAgent for the current user.

Installed property list and logs:

```text
~/Library/LaunchAgents/com.github.open-latest-als.plist
~/Library/Logs/open-latest-als/stdout.log
~/Library/Logs/open-latest-als/stderr.log
```

Run the installer again after changing the script or LaunchAgent template. Changes to `config.sh` are read on each run and do not require reinstallation.

## Test the LaunchAgent

Trigger the installed agent without logging out:

```zsh
./install.sh --run
```

Inspect its registration:

```zsh
launchctl print "gui/$(id -u)/com.github.open-latest-als"
```

Read recent output and errors:

```zsh
tail -n 50 ~/Library/Logs/open-latest-als/stdout.log
tail -n 50 ~/Library/Logs/open-latest-als/stderr.log
```

The log files are appended to, so earlier errors can remain after a successful run. Check the newest lines.

For a complete startup test, log out and back in or restart the Mac. The newest set should open after `STARTUP_DELAY` seconds.

## iCloud Drive permissions

A manual Terminal test can succeed while the LaunchAgent fails with:

```text
find: /Users/jaime/Library/Mobile Documents/...: Operation not permitted
No .als files found under /Users/jaime/Library/Mobile Documents/...
```

This is a macOS privacy restriction. LaunchAgents do not inherit Terminal's privacy permissions.

To allow the installed agent to search iCloud Drive:

1. Open **System Settings → Privacy & Security → Full Disk Access**.
2. Click **+**.
3. Press **Command-Shift-G** in the file chooser.
4. Enter `/bin/bash` and add it.
5. Ensure access is enabled for `bash`.
6. Reinstall and test the agent:

   ```zsh
   ./install.sh
   ./install.sh --run
   ```

Granting Full Disk Access to `/bin/bash` allows scripts executed by that shell to access protected locations. A more restrictive alternative is to keep the Ableton projects in a local, non-protected directory such as:

```text
/Users/jaime/Music/Ableton/projects
```

Do not use `chmod`, `sudo`, or plist ownership changes to address `Operation not permitted`; macOS privacy controls are separate from Unix file permissions.

## Troubleshooting

### `PROJECTS_DIR does not exist`

- Confirm the directory exists.
- Keep paths containing spaces inside double quotes.
- Do not add backslashes before spaces inside those quotes.

### `No .als files found`

- Confirm `.als` files exist below `PROJECTS_DIR`.
- Check `stderr.log` for a preceding `Operation not permitted` message.
- If all sets are in `Backup` directories, temporarily set `SKIP_BACKUPS=0`.

### Ableton cannot be found

Set `APP` to the exact application name from `/Applications`, without `.app`:

```zsh
APP="Ableton Live 12 Suite"
```

If `APP` is empty, automatic detection only succeeds when exactly one matching Ableton Live application is installed.

## Uninstall

Unload the LaunchAgent and remove its installed property list:

```zsh
./install.sh --uninstall
```

The repository, configuration, and log files are left in place.