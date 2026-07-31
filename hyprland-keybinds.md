# Hyprland Keybinds Cheatsheet

`$mod` = **Super** (Windows key). Defined in
[modules/home-manager/hyprland/hyprland.nix](modules/home-manager/hyprland/hyprland.nix).

## Launching

| Keys | Action |
|---|---|
| `Super` + `Return` | Terminal (kitty) |
| `Super` + `Space` | App launcher (rofi) |
| `Super` + `E` | File manager (nautilus) |
| `Super` + `C` | Clipboard history picker |

## Windows

| Keys | Action |
|---|---|
| `Super` + `Q` | Close active window |
| `Super` + `F` | Fullscreen |
| `Super` + `V` | Toggle floating |
| `Super` + `←/→/↑/↓` | Move focus |
| `Super` + `Shift` + `←/→/↑/↓` | Move window |
| `Super` + hold left-mouse | Drag to move window |
| `Super` + hold right-mouse | Drag to resize window |

## Workspaces

| Keys | Action |
|---|---|
| `Super` + `1`–`9`, `0` | Switch to workspace 1–10 |
| `Super` + `Shift` + `1`–`9`, `0` | Send window to workspace 1–10 |

## Screenshots

| Keys | Action |
|---|---|
| `Print` | Region (frozen) → clipboard |
| `Shift` + `Print` | Active window (frozen) → clipboard |
| `Ctrl` + `Print` | Whole monitor → clipboard |

## Session

| Keys | Action |
|---|---|
| `Super` + `L` | Lock screen (hyprlock) |
| `Super` + `Shift` + `E` | Power menu (logout/reboot/shutdown) |
| `Super` + `M` | Exit Hyprland (back to GDM) |

## Media & Hardware Keys

| Keys | Action |
|---|---|
| `Volume Up` / `Down` | Adjust volume (5% steps) |
| `Mute` | Toggle output mute |
| `Mic Mute` | Toggle microphone mute |
| `Brightness Up` / `Down` | Adjust screen brightness |
| `Play` / `Next` / `Prev` | Media control (playerctl) |

> Volume, brightness, and media keys work even while the screen is locked.

## Idle behaviour

- **5 min** → lock · **10 min** → screen off · **20 min** → suspend *(laptop only)*
