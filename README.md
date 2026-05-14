# battery-tray

A small GTK3 / AyatanaAppIndicator3 system-tray app for managing the battery
charge limit on Intel MacBooks running Linux. Reads battery state from sysfs
and writes the charge threshold to the SMC `BCLM` key via `pkexec`. No daemon,
no background service — the limit is stored in SMC NVRAM and survives reboots.

Designed to be the GUI companion to
[`netlinux-ai/applesmc-next`](https://github.com/netlinux-ai/applesmc-next),
which provides the `charge_control_end_threshold` sysfs file this tool writes.

## What you get

* A tray icon that shows battery percentage and charge state.
* A **Settings...** dialog with a slider for the charge limit (20–100%).
* Critical notifications when the SMC BCLM key changes unexpectedly (e.g. SMC
  reset or another tool changed it), logged to
  `~/.local/share/battery-tray/bclm.log`.
* Standard low-battery and "charge complete" notifications.

## Requirements

| Package | Purpose |
|---|---|
| `applesmc-next` (kernel module) | Provides `charge_control_end_threshold` in sysfs |
| `python3-gi` | Python GObject bindings |
| `gir1.2-gtk-3.0` | GTK3 typelib |
| `gir1.2-ayatanaappindicator3-0.1` | Tray indicator typelib |
| `libnotify-bin` | `notify-send` for desktop notifications |
| `policykit-1` (or compatible) | `pkexec` for privilege elevation |

On Debian / Ubuntu:

```sh
sudo apt install python3-gi gir1.2-gtk-3.0 \
                 gir1.2-ayatanaappindicator3-0.1 \
                 libnotify-bin policykit-1
```

You also need the kernel-side BCLM support. Install
[`applesmc-next-dkms`](https://github.com/netlinux-ai/applesmc-next) first —
without it, `/sys/class/power_supply/BAT0/charge_control_end_threshold`
doesn't exist and the **Apply** button silently no-ops (the GUI still opens
and shows battery status).

## Install

### From the `.deb` (Debian / Ubuntu)

Grab the latest `.deb` from the
[releases page](https://github.com/netlinux-ai/battery-tray/releases):

```sh
sudo apt install ./battery-tray_*.deb
```

This installs the binary at `/usr/local/bin/battery-tray`, registers a menu
entry under **Settings → Hardware**, and adds an autostart entry so the tray
launches on login.

### From source

```sh
git clone https://github.com/netlinux-ai/battery-tray
cd battery-tray
sudo make install
```

`sudo make install` does everything in one shot:

1. Installs the script to `$(PREFIX)/bin/battery-tray` (default
   `/usr/local/bin/battery-tray`).
2. Installs the `.desktop` to **both** `$(PREFIX)/share/applications/` (menu
   entry) and `/etc/xdg/autostart/` (autostart on login).
3. Runs `update-desktop-database`.
4. Kills any running instance owned by `$SUDO_USER` and relaunches it as the
   invoking user (so you don't end up with the tray running as root).

To remove:

```sh
sudo make uninstall
```

## Use

* Open **Battery Charge Manager** from your application menu (under
  Settings → Hardware on most desktops), or just run `battery-tray` from a
  terminal. After login the autostart entry runs it for you.
* Click the tray icon → **Settings...** to open the dialog.
* Drag the slider to your desired limit (recommended: 80% for daily use, 100%
  before a trip), or untick **Enable charge limit** to remove it.
* Click **Apply** — `pkexec` prompts for your password, the new value is
  written to `charge_control_end_threshold`, and the SMC immediately picks it
  up.

The setting persists in SMC NVRAM across reboots and operating systems unless
the SMC is reset. The tray detects external changes to the limit (e.g. an SMC
reset wiping BCLM back to 100) and notifies you.

## How it works

```
GUI slider
   │
   ▼
pkexec bash -c "echo N > /sys/class/.../charge_control_end_threshold"
   │                                  │
   │                                  ▼
   │                          patched sbs / applesmc kernel modules
   │                                  │
   ▼                                  ▼
~/.local/share/battery-tray/bclm.log  SMC `BCLM` key (NVRAM)
```

The tray polls battery state every 5 seconds. When the BCLM value changes
from what the tray last saw, it logs the change and raises a critical
notification — useful for catching cases where the SMC was reset (e.g. battery
disconnect, NVRAM reset) and the limit was lost.

## Configuration

There's nothing to configure. State is read from sysfs each tick. The only
persistent file the tray writes is the BCLM change log at
`~/.local/share/battery-tray/bclm.log`.

## Troubleshooting

* **No tray icon visible** — your panel's system tray may not handle
  StatusNotifierItem (SNI). On xfce4-panel 4.20+, the `systray` plugin handles
  SNI natively; if Telegram and similar apps also have invisible icons,
  restart the panel: `xfce4-panel --restart`. If you're on xfce4-panel < 4.20,
  install `xfce4-statusnotifier-plugin`.

* **Apply button does nothing** — likely one of:
  * `pkexec` denied the request (cancelled the password prompt).
  * The kernel module isn't loaded — verify
    `cat /sys/class/power_supply/BAT0/charge_control_end_threshold` works.
  * `pkexec` policy doesn't permit `bash` invocation — check
    `journalctl -u polkit` for denials.

* **Settings dialog never opens** — if you previously saw it open but it
  stopped working, check for a stale tray process: `pgrep -af battery-tray`.
  A common cause is two confined instances trying to D-Bus-handshake; kill
  all and relaunch from the menu.

* **Limit keeps resetting to 100** — SMC reset by something (firmware update,
  battery disconnect, NVRAM reset). The tray logs each change to
  `bclm.log` — check there for timestamps.

## License

[MIT](LICENSE) — do whatever you want with it, as long as you preserve the
copyright notice and license text in copies or substantial portions of the
work. The kernel-side dependency
[`applesmc-next`](https://github.com/netlinux-ai/applesmc-next) is GPL-2.0,
but this tray app only talks to it through the sysfs interface, so the two
licenses don't conflict.
