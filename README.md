# scrv

[![Platform](https://img.shields.io/badge/platform-Linux-0078D4?logo=linux&logoColor=white)](https://www.linux.org/)
[![Language](https://img.shields.io/badge/language-bash-4EAA25?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![license](https://img.shields.io/badge/license-MIT-yellow)](https://opensource.org/licenses/MIT)
[![GitHub Stars](https://img.shields.io/github/stars/Luquas95/scrv?style=social)](https://github.com/Luquas95/scrv)

A simple bash script that toggles the screensaver and screen lock on Linux.
Run it once to disable, run it again to re-enable.

## Installation

**Step 1** — Make the script executable:
```bash
chmod +x scrv
```

**Step 2** — Copy it to a system-wide location so it can be run from anywhere:
```bash
sudo cp scrv /usr/local/bin/
```

## Usage

```bash
scrv          # disable screensaver
scrv          # enable screensaver again
```

Tip: assign it to a keyboard shortcut in your DE settings for quick toggling.

---

## Dependencies

| Tool | Package (Debian/Ubuntu) | Notes |
|---|---|---|
| `bash` | pre-installed | version 4+ |
| `xset` | `x11-xserver-utils` | X11 only, silently skipped on Wayland |
| `dbus-send` | `dbus` | usually pre-installed |
| `gsettings` | `libglib2.0-bin` | GNOME/Cinnamon/MATE only |
| `systemd-inhibit` | `systemd` | available on most modern distros |

---

## Supported environments

### X11

| Desktop | Mechanism |
|---|---|
| **Cinnamon** | gsettings + DBus + xset + polling |
| **GNOME** | gsettings + DBus + xset + polling |
| **MATE** | gsettings + DBus + xset + polling |
| **KDE Plasma** | systemd-inhibit + DBus + xset |
| **XFCE** | systemd-inhibit + DBus + xset + polling |
| **Openbox / i3 / dwm** and other WMs | xset + systemd-inhibit |

### Wayland

| Compositor / DE | Mechanism |
|---|---|
| **Hyprland** (hypridle) | systemd-inhibit (natively respected by hypridle via logind) |
| **Sway** (swayidle) | systemd-inhibit (natively respected by swayidle via logind) |
| **GNOME Wayland** | systemd-inhibit + DBus |
| **KDE Plasma Wayland** | systemd-inhibit + DBus |
| **labwc, river, niri** and other wlroots WMs | systemd-inhibit (when using swayidle) |
| **Omarchy 4 "Quattro"** | `omarchy toggle idle` (its own Quickshell `IdleMonitor`, not systemd-inhibit) |

---

## How it works

The script applies multiple inhibition layers simultaneously, each covering a different environment:

1. **gsettings** — disables the screensaver and lock at the DE settings level (Cinnamon, GNOME, MATE)
2. **xset s off -dpms** — disables the X screensaver and DPMS blanking (X11)
3. **systemd-inhibit** — idle inhibit at the logind level, works independently of the DE, including Wayland (natively respected by `hypridle` and `swayidle`)
4. **Polling loop (every 20 s)** — fallback that sends `SimulateUserActivity` over DBus and resets the X idle timer
5. **`omarchy toggle idle`** — called directly when the `omarchy` CLI is present (silently skipped otherwise)

The on/off state is tracked via a PID file at `/tmp/scrv-inhibit.pid`.

> **Note:** earlier versions of this script tried to pause `hypridle`/`swayidle` directly by sending them `SIGUSR1`/`SIGUSR2`. Neither daemon actually implements handlers for those signals — `hypridle` ignores them entirely, and `swayidle` only handles `SIGUSR1` (to force pending timeouts, not to pause). An unhandled signal's default action is to **terminate the process**, so this used to kill the idle daemon outright: the screensaver would then never reactivate after re-enabling it, since the daemon was no longer running. This has been removed; idle inhibition on Wayland now relies solely on `systemd-inhibit`, which both daemons support natively.

> **Note on Omarchy 4 "Quattro":** Omarchy 4 dropped `hypridle` entirely — idle/screensaver/lock is now handled by its own `IdleMonitor` inside the Omarchy Quickshell shell, which does **not** observe `systemd-inhibit` at all (Quattro's `respectInhibitors` setting only covers the Wayland idle-inhibit protocol from apps like mpv or browsers, not logind locks). The only supported way to disable idling is the "Stay Awake" toggle via `omarchy toggle idle`, which just creates/removes a marker file at `~/.local/state/omarchy/indicators/stay-awake`. scrv calls this directly (`command -v omarchy` gates it, so it's a no-op on every other distro/DE) since none of the other four layers above have any effect on Quattro.

---

## Known issues

- **Multiple instances of hypridle/swayidle** — not applicable anymore now that signals aren't used; systemd-inhibit is a single shared logind-level lock
- **XWayland apps** — `xset` only affects the XWayland context and has no impact on the Wayland compositor itself
- **Race condition on startup** — if the screensaver activates just before the script runs, it may briefly flash before the polling loop deactivates it (only affects DEs where gsettings/inhibit don't take effect immediately)
- **Up to ~20 s delay releasing the inhibit** — re-enabling the screensaver kills the PID-tracked background subshell, but its trap (which stops the `systemd-inhibit` process) only runs once the subshell's current `sleep` finishes, so the logind inhibit can outlive the toggle by up to `INTERVAL` seconds

## When it won't work

- **Non-systemd distros** (Alpine with OpenRC, Void with runit, Artix with s6...) — `systemd-inhibit` is unavailable; the script still works via xset + DBus + gsettings, but with weaker coverage on Wayland
- **Custom idle daemons** (e.g. `xss-lock`, `swaylock` launched directly without swayidle) — the script has no way to pause them
- **Hyprland with `general:ignore_systemd_inhibit = true` in hypridle.conf** — hypridle explicitly ignores logind idle inhibitors; scrv has no remaining way to pause it
- **Wayland without swayidle or hypridle** (e.g. custom solution via `wlr-idle` or another daemon) — depends on whether that daemon honors logind's systemd-inhibit
- **Remote sessions (SSH, VNC without a DE)** — the DBus session bus may not be available

---

## Contributors

- [Luquas95](https://github.com/Luquas95) — creator & maintainer

## License

MIT
