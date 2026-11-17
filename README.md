# Termux Init Setup

Automated bootstrap script for setting up a fresh **Termux** environment. Supports both `apt` and `pacman` package managers, offline package archives, and non-interactive unattended runs.

---

## Directory Structure

```text
.
├── init.sh             # Main bootstrap script
├── pkg-common.txt      # Packages shared by both apt and pacman
├── pkg-apt.txt         # APT-specific packages
├── pkg-pacman.txt      # Pacman-specific packages
├── repo.txt            # Extra Termux repositories (APT only, e.g., tur-repo)
├── tur.list            # Custom APT sources list (optional)
└── requirements.txt    # Python packages installed via pip
```

### Local Offline Archives (`~/.local/packages/`)
If installing offline packages or custom builds, place them in:
* **Python tarballs/wheels:** `~/.local/packages/python/`
* **Debian packages:** `~/.local/packages/debian/*.deb`
* **Pacman packages:** `~/.local/packages/pacman/*.pkg.tar.*`

---

## Usage

Make the script executable first:
```bash
chmod +x init.sh
```

### Common Commands
```bash
# Interactive setup (prompts at each step)
./init.sh

# Full unattended fresh install
./init.sh -y

# Unattended online-only setup (skip local offline archives)
./init.sh -y --skip-local

# Preview all commands without making changes
./init.sh -y -d
```

### CLI Options

| Flag | Description |
| :--- | :--- |
| `-y`, `--yes` | Run non-interactively (auto-accepts prompts; skips TUI/editor repo step) |
| `--skip-local` | Skip local Python (`requirements.txt`) and offline `.deb`/`.pkg.tar.*` steps |
| `-d`, `--dry-run` | Print commands without executing them |
| `-h`, `--help` | Display help message |

---

## Notes
* **Termux Guardrail:** Exits immediately if executed outside of Termux.
* **Wakelock Safety:** Automatically releases `termux-wake-lock` on exit or interruption (`Ctrl+C`).
* **Session Logs:** Every run saves a plain-text, ANSI-free log to `~/.cache/termux-init-YYYYMMDD-HHMMSS.log`.
* **Post-Cleanup:** If `~/bin/termux-junk-cleaner` is present, `init.sh` will offer to run it at the end while preserving the active setup log.
