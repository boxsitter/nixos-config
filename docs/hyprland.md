# Hyprland alongside GNOME

Hyprland is a second, fully separate session on `desktop` and `laptop`. GDM stays
the login screen and offers **GNOME** and **Hyprland**; GNOME is the reliable
fallback and is not changed by any of this.

The goals, in order: **robust and consistent first, pretty second.** A look that
only survives a screenshot is not the point.

- [Using it](#using-it)
- [How it is built](#how-it-is-built)
- [GNOME isolation](#gnome-isolation)
- [Theming and the theme switcher](#theming-and-the-theme-switcher)
- [Wallpapers](#wallpapers)
- [Per-host notes](#per-host-notes)
- [First login checklist](#first-login-checklist)
- [Verifying changes](#verifying-changes)
- [Troubleshooting](#troubleshooting)
- [Design notes](#design-notes)

## Using it

Pick **Hyprland** from the gear icon on the GDM login screen. To go back, log out
and pick **GNOME**. If Hyprland ever fails to start, GDM simply returns to the
login screen; GNOME is one click away.

`Super` is the modifier. **`Super + /` shows every keybind**, generated from the
running config, so it cannot go stale. This table is a snapshot:

| Keys | Action |
|---|---|
| `Super + Return` | Terminal (kitty) |
| `Super + Space` | Launcher |
| `Super + E` / `B` | Files / Browser |
| `Super + Shift + Esc` | System monitor (btop) |
| `Super + Q` | Close window |
| `Super + F` / `Shift + F` | Fullscreen / Maximize |
| `Super + V` | Toggle floating |
| `Super + \` | Toggle split direction |
| `Super + ←↓↑→` or `H J K L` | Focus (`+Shift` move window, `+Ctrl` resize) |
| `Super + mouse` | Drag to move, right-drag to resize |
| `Super + 1 … 0` | Workspace 1-10 (`+Shift` sends the window there) |
| `Super + Tab` | Previous workspace |
| `Super + [` / `]` | Workspace left / right (also scroll wheel, 3-finger swipe) |
| `Super + `` ` `` | Scratchpad (`+Shift` sends the window to it) |
| `Super + , / .` | Focus previous / next monitor (`+Shift` moves the window) |
| `Super + C` | Clipboard history |
| `Super + N` | Notification center (`+Shift` toggles Do Not Disturb) |
| `Super + W` | Wallpaper picker (`+Shift` random) |
| `Super + Shift + B` | Night light |
| `Super + L` | Lock |
| `Super + Shift + E` | Power menu (log out / reboot / shut down ask first) |
| `Print` / `Shift + Print` / `Ctrl + Print` | Screenshot region / window / screen (saved to `~/Pictures/Screenshots` and copied) |
| `Super + Shift + S` | Screenshot a region and annotate it |
| Volume / brightness / media keys | Work everywhere, including the lock screen, with an on-screen display |

Idle: dim at 4 min, lock at 5, screen off at 10 (laptop also suspends at 20).
Anything fullscreen, or holding an idle inhibitor (the coffee icon in the bar,
browsers playing video), keeps the session awake.

## How it is built

Everything is declarative. The Hyprland-specific parts live in two places:

```
modules/nixos/services/hyprland.nix        session entry, portals, hyprlock PAM, fonts, assertions
modules/home-manager/hyprland/
  default.nix           single import point for a host
  theme/                palette → every color in the session (see below)
  hyprland.nix          compositor: environment, look, input, session target
  binds.nix             keybinds (each with a description for Super + /)
  rules.nix             window rules and layer (blur) rules
  waybar.nix            the bar
  rofi.nix              launcher + the shared popup style (menu, wallpaper grid)
  notifications.nix     swaync: popups + notification center / quick settings
  osd.nix               volume and brightness on-screen display (swayosd)
  lock.nix              hyprlock (lock screen) + hypridle (idle policy)
  wallpaper.nix         awww daemon + restore at login / monitor hotplug
  appearance.nix        GTK, Qt and cursor theming, session-scoped
  session-services.nix  polkit agent, clipboard history, network/bluetooth/automount
  scripts.nix + scripts/*.sh   power-menu, screenshot, wallpaper, ...
hosts/*/leyton.nix                         per-host Lua (monitors, GPU, lid)
resources/wallpapers/<theme>/              the wallpapers (+ tools/generate.py)
tests/vm/hyprland-session.nix              end-to-end test (two VMs)
tests/eval/assertions.nix                  isolation guarantees, checked at eval time
```

**Config format.** Hyprland has been configured in Lua since 0.55; the old
`hyprland.conf` format is deprecated. Home Manager writes `~/.config/hypr/hyprland.lua`
and requires the numbered files in order (`10-env`, `20-look`, `30-input`,
`40-binds`, `50-rules`, `60-wallpaper`, `90-host`). Each module contributes its own
file through `wayland.windowManager.hyprland.extraLuaFiles`.

**Stack.** Waybar, rofi, swaync, swayosd, hyprlock/hypridle, awww, hyprshot and
satty, cliphist, hyprpolkitagent. Small, individually replaceable, all packaged
in nixpkgs; no extra flake inputs.

## GNOME isolation

The two sessions share the machine, so the rule is: **nothing the Hyprland session
needs may run, or be configured, inside GNOME.**

- Every Home Manager user unit is wanted by `hyprland-session.target` and nothing
  else. That target only exists while a Hyprland session runs.
- Some Home Manager service modules do *not* honour that scoping (`udiskie` is
  hard-wired to `graphical-session.target`, `playerctld` to `default.target`,
  `nm-applet` to `graphical-session.target` + `tray.target`, and Waybar is also
  wanted by `tray.target`). Those are defined by hand in `session-services.nix` /
  forced in `waybar.nix`.
- Environment variables (`GTK_THEME`, `QT_*`, cursor) are set through Hyprland's
  own `hl.env`, never globally. Hyprland's `sync_gsettings_theme` is off so it
  does not write the cursor theme into dconf, which GNOME shares.
- No system-level `programs.hyprlock` / `services.hypridle` (their unit would be
  wired to `graphical-session.target`); only the PAM service hyprlock needs.
- The GDM session list is exactly GNOME + Hyprland. nixpkgs also ships a
  "uwsm-managed" entry that cannot work here; it is hidden.

All of that is enforced, not just intended: `tests/eval/assertions.nix` fails the
build if any home-manager unit becomes wanted outside the Hyprland target, and
`tests/vm/hyprland-session.nix` logs into GNOME in a VM and asserts none of the
session's services start and gnome-shell still owns notifications.

## Theming and the theme switcher

`theme/default.nix` is the single source of truth. A palette
(`theme/palettes/*.nix`) is plain data: surfaces, text, ten hues. The module turns
it into every format the components need (GTK CSS named colors for Waybar, swaync
and the OSD; rasi variables for rofi; Hyprland and hyprlock colors; a GTK theme;
a Qt color scheme), so **no module contains a hex value.**

Currently: Catppuccin Macchiato, accent blue. Change the accent with
`theme.accent = "purple";` (any of red, orange, yellow, green, teal, sky, blue,
lavender, purple, pink).

**Adding a theme** is three steps:

1. Copy `theme/palettes/catppuccin-macchiato.nix` to `<name>.nix`, change the
   colors (same role names), and point `wallpapers` at a new folder.
2. Add it to the `palettes` set in `theme/default.nix`.
3. Set `theme.name = "<name>";` and rebuild.

Colors, wallpapers, GTK/Qt themes, lock screen, bar, launcher, notifications all
follow. A *runtime* switch without a rebuild is deliberately not built yet; the
palette module is the part that makes it possible later (e.g. Home Manager
specialisations).

kitty and fish keep their Catppuccin ports from `catppuccin/nix` (see
`core.nix`); both sessions share those.

GTK apps get a theme derived from `adw-gtk3` (the theme GNOME already uses) with
the palette's colors appended; it is selected with `GTK_THEME`, which only
Hyprland sets, and reaches GTK3 and GTK4/libadwaita apps alike. Qt apps use
qt6ct + Fusion with a generated color scheme.

## Wallpapers

Eight Macchiato wallpapers are committed in
`resources/wallpapers/catppuccin-macchiato/` (about 6 MB total). They are
procedural and drawn from the palette itself, so they are exactly on-palette and
carry no licensing question. `resources/wallpapers/tools/generate.py` reproduces
them (seeds are fixed) and can render a set for a new palette.

- `Super + W` opens the picker (thumbnails), `Super + Shift + W` picks a random
  one. Switching animates.
- Drop any extra `.jpg/.png/.webp` into the theme's folder and rebuild; it shows
  up in the picker. Thumbnails are generated at build time.
- Only the *chosen name* is runtime state (`~/.local/state/wallpaper`). It is
  re-applied at login and whenever a monitor is plugged in. The lock screen uses
  the same wallpaper, blurred.

## Per-host notes

**Both hosts** put their Hyprland specifics in
`wayland.windowManager.hyprland.extraLuaFiles."90-host"` in `hosts/*/leyton.nix`
(plain Lua, loaded last).

**Laptop (XPS 15 9530, Intel + NVIDIA).** By default Hyprland picks the GPU that
drives the built-in panel (the Intel iGPU) and keeps NVIDIA available, so every
output works. The NVIDIA card is then opened and may not reach its deep-sleep
state while Hyprland runs. For best battery, set `iGpuOnly = true` in
`hosts/laptop/leyton.nix`: Hyprland then uses only the iGPU through the
`/dev/dri/igpu` udev symlink (`hosts/laptop/configuration.nix`). If the symlink
is missing it falls back to auto-detect rather than failing. The catch: a display
wired to the NVIDIA GPU stops working in that mode. Measure with

```
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status   # "suspended" at idle is the goal
```

Lid: with an external monitor attached, closing the lid turns the internal panel
off (logind treats that as docked and does not suspend); with none, the laptop
suspends as usual. Touchpad clicks use bottom-zone buttons, like the rest of the
laptop config. The panel scale is set to 1.5, which suits the 3.5K OLED; check
with `hyprctl monitors` and edit the `scale` if it is the 1080p panel.

**Desktop (RTX 5080).** NVIDIA environment variables, software cursor (trial
removing `no_hardware_cursors` once it is stable), and flat pointer acceleration
to match GNOME. Scale 1.5 is a placeholder for a 4K panel; set the real monitor
after the first login.

## First login checklist

Everything below was verified in a VM with software rendering (real GDM login,
real keypresses, lock/unlock through PAM). What a VM cannot cover is hardware, so
on first login check, in this order:

```
hyprctl configerrors                 # should print nothing
systemctl --user --failed            # should list nothing
hyprctl monitors                     # scale and refresh as expected?
```

Then, laptop-specific: volume/brightness keys and the on-screen display, Wi-Fi
and Bluetooth from the bar (click the icons), screenshot (`Print`), suspend and
resume (lock appears?), closing the lid with and without an external monitor,
three-finger swipe, and a screen share from a browser.

## Verifying changes

```
nix build .#checks.x86_64-linux.hyprland-config    # ~10 s: asks Hyprland itself to validate each host's config
nix build .#checks.x86_64-linux.eval-assertions    # seconds: the GNOME-isolation rules
nix build .#checks.x86_64-linux.hyprland-session   # ~2 min: boots Hyprland and GNOME in VMs and exercises them
nix flake check                                    # everything
```

The VM test logs in through GDM, drives the real keybinds (workspaces, float,
fullscreen, scratchpad, launcher, lock/unlock through PAM, screenshots, clipboard
history, night light), checks the session theme reaches apps, and then logs into
GNOME in a second VM and asserts none of it leaked. It also fails if systemd
reports an ordering cycle, which silently deletes a job and can make a service
randomly not start. Building a host config also runs `shellcheck` on every helper
script.

To *see* a change without rebooting into it, drive the VM test's driver with your
own script. This is how the screenshots during development were taken:

```
nix build .#checks.x86_64-linux.hyprland-session.driver
$(readlink result)/bin/nixos-test-driver -o shots --test-script my-script.py
```

where the script does e.g. `hyprland.start()`, `hyprland.wait_for_file("/run/user/1000/wayland-1")`,
`hyprland.send_key("meta_l-ret")`, `hyprland.screenshot("name")`. The `hyprland`
machine is the Hyprland-session VM; `gnome` is the GNOME-session one.

## Troubleshooting

| Symptom | Look at |
|---|---|
| Bar / notifications / wallpaper missing | `systemctl --user status waybar swaync awww` and `journalctl --user -u <unit>` |
| Whole session fails to start | GDM returns to the login screen: pick GNOME, then `journalctl -b \| grep -i hypr` and `~/.local/share/hyprland` / `$XDG_RUNTIME_DIR/hypr/*/hyprland.log` |
| Config error banner at the top | `hyprctl configerrors` |
| A keybind does nothing | `Super + /` to see what is bound; run the command in a terminal |
| Wi-Fi does not auto-connect | `nm-applet` is the secret agent for networks saved "for this user only"; `systemctl --user status nm-applet` |
| Wrong wallpaper after login | `wallpaper restore`; state in `~/.local/state/wallpaper/name` |
| Locked out of the lock screen | switch to a TTY (`Ctrl+Alt+F3`), log in, `pkill hyprlock` |
| Want to roll everything back | pick GNOME at GDM, or boot the previous generation |

## Design notes

Decisions worth knowing the reasons for, including where this differs from the
first attempt at this setup:

- **Lua, not hyprlang.** Hyprland deprecated `hyprland.conf` in 0.55 ("a few
  releases" of grace). Home Manager can generate the Lua config, so there is no
  reason to build on the old format. It also means `hyprctl dispatch dpms off`
  style commands are gone; dispatchers are Lua expressions now (see `lock.nix`).
- **Home Manager starts the session target.** Hyprland 0.56 imports its
  environment into systemd but does not start `hyprland-session.target` (upstream
  `main` does). Home Manager's hook does, and its stop-then-start gives services a
  fresh environment after a compositor restart. A later nixpkgs bump makes it
  redundant, not wrong.
- **No UWSM.** It would compete for `graphical-session.target` with the scoping
  above. (The earlier worry that it flips the system D-Bus to dbus-broker is
  moot: broker is already the NixOS default.)
- **A composed stack, not a Quickshell "desktop shell".** Noctalia, Caelestia and
  DankMaterialShell are the current fashion and look great, but they are one
  fast-moving third-party shell that owns the bar, launcher, notifications,
  lock screen and settings, configured partly through its own GUI. For a daily
  driver that must stay boring, small separate components that each do one thing
  are easier to reason about, replace and keep declarative. Revisit if you want
  the extra polish and accept the churn.
- **Real wallpapers over a generated gradient.** Wallpapers are the biggest single
  part of how a rice reads, so they are first-class and palette-derived.
- **Verify, don't assume.** The first attempt documented several things that were
  wrong (which services honour the scoping, what UWSM changes, that the config
  format was current). The tests exist so those claims are checked by machines.
