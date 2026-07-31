# Hyprland Alongside GNOME

Hyprland is a second, fully independent session on `desktop` and `laptop`, picked
per-login from GDM's session picker. GNOME remains byte-identical — no GNOME module
is functionally changed. The end goal is an r/unixporn-quality rice that stays a
full daily driver.

**Phases:** (1) fully functional session, default styling → (2) the rice, via a
custom theme-manager module, starting with a single Catppuccin Macchiato palette.

**Decisions:** custom palette module as theme manager (the catppuccin/nix input
stays for its current app-level uses — kitty/fish are already macchiato); Waybar;
keep GDM; shared apps may carry Catppuccin in both sessions, GTK apps themed only
inside Hyprland via a session-scoped `GTK_THEME`.

**Constraints:** 100% declarative/nix-pure (anything non-declarative is left out);
Hyprland from nixpkgs (repo is on nixos-unstable), not the Hyprland flake;
server/wsl/mac untouched.

## Architecture facts (verified against pinned home-manager/nixpkgs source)

- HM has one scoping knob, `wayland.systemd.target` (default
  `graphical-session.target`), honored by `services.swaync`, `services.hypridle`,
  `services.hyprpaper`, `services.hyprpolkitagent`, `services.cliphist`, and
  `programs.waybar.systemd`. HM's Hyprland module creates `hyprland-session.target`
  when `systemd.enable = true` → clean "Hyprland-only" rally point so nothing leaks
  into GNOME.
- Exception: `services.network-manager-applet` hardcodes `graphical-session.target`
  + `Requires=tray.target` — manually rescoped, or it would start in GNOME and drag
  Waybar in via `tray.target`.
- `programs.hyprland.withUWSM` pulls in `programs.uwsm`, which switches
  `services.dbus.implementation` to dbus-broker **system-wide** — would change the
  GNOME session. → **`withUWSM = false`**; HM systemd integration
  (`hyprland-session.target`) does the scoping instead. If UWSM is ever revisited:
  the dbus flip must be `mkForce`d back, and HM `systemd.enable` must be false,
  which dismantles the scoping scheme here.
- `pkgs.rofi` is Wayland-capable on current nixpkgs (rofi-wayland merged upstream).
- NixOS `programs.hyprlock.enable` provides the PAM service hyprlock needs to
  unlock — don't enable it home-manager-only.
- Portal configs merge safely: the GNOME module ships
  `configPackages = mkDefault [ gnome-session ]`, the Hyprland module
  `mkDefault [ hyprland ]` — equal-priority list merge, no conflict.
- `tests/eval/hosts.nix` force-evaluates desktop+laptop toplevels, so
  `nix flake check` eval-tests all Hyprland modules automatically.

## Component choices

| Role | Choice | Why |
|---|---|---|
| Session mgmt | `programs.hyprland` (nixpkgs), `withUWSM = false` | UWSM flips system dbus to dbus-broker (touches GNOME) and fights GNOME for `graphical-session.target` |
| Bar | Waybar (`programs.waybar`, systemd-scoped) | CSS fully declarative |
| Launcher | rofi (`programs.rofi`, kitty as terminal) | Wayland-capable upstream; rasi themeable from palette |
| Notifications | swaync (`services.swaync`) | notification center + history (closest to GNOME UX); plain CSS → same theming pipeline as Waybar |
| Lock / idle | hyprlock + hypridle | official; declaratively configured; PAM via system module |
| Wallpaper | hyprpaper (`services.hyprpaper`) | fully static declarative config; swww needs imperative IPC calls |
| Screenshots | hyprshot + existing wl-clipboard | window/region/monitor modes, `--freeze`; no daemon |
| Clipboard history | cliphist (`services.cliphist`) + rofi picker | scoped service; copyq stays GNOME-side |
| Polkit agent | hyprpolkitagent (`services.hyprpolkitagent`) | scoped to Hyprland; GNOME keeps gnome-shell's agent |
| Network / BT | nm-applet (rescoped) + blueman-applet (`systemdTargets`) + `services.blueman` (system) | tray applets only in Hyprland; gnome-bluetooth unaffected |
| Media/volume/brightness | wpctl / playerctl (+`services.playerctld`) / brightnessctl keybinds | uses existing pipewire |
| Automount | udiskie, tray-scoped | GNOME has gvfs; Hyprland needs this |
| GTK in session (P2) | `pkgs.magnetic-catppuccin-gtk` via session-scoped `GTK_THEME` | upstream catppuccin/gtk is archived; global `GTK_THEME=adw-gtk3` stays for GNOME |
| Skipped | wlogout (rofi power menu instead), swww, UWSM | less surface, purity |

## File layout

```
hyprland.md                               # this document
modules/nixos/services/hyprland.nix       # session registration, portals, hyprlock PAM, blueman, assertions
modules/home-manager/hyprland/
  default.nix                             # aggregator: single import point for hosts
  hyprland.nix                            # compositor: scoping master switch, settings, binds, env
  waybar.nix                              # bar: modules layout (P1), themed CSS (P2)
  rofi.nix                                # launcher + clipboard/power-menu modes (P1), rasi theme (P2)
  notifications.nix                       # swaync (P1), themed CSS (P2)
  hyprlock.nix                            # lock screen (P1 default, P2 styled)
  hypridle.nix                            # lock 300s, dpms 600s; laptop adds suspend listener
  wallpaper.nix                           # hyprpaper; P1 generated gradient, P2 theme.wallpaper
  session-services.nix                    # nm-applet rescope, blueman-applet, polkit, cliphist, playerctld, udiskie
  gtk.nix                                 # P2: session GTK_THEME/XCURSOR override
  theme/
    default.nix                           # P2: theme.* options + wiring
    palettes/catppuccin-macchiato.nix     # P2: palette attrset (bare hex + accent alias)
```

Host wiring — the only edits to existing files (GNOME imports untouched;
`modules/home-manager/desktop.nix` deliberately NOT touched):
- `hosts/{desktop,laptop}/configuration.nix`: import `modules/nixos/services/hyprland.nix`.
- `hosts/{desktop,laptop}/leyton.nix`: import `modules/home-manager/hyprland` + per-host
  monitor/GPU env blocks (desktop: NVIDIA env, `no_hardware_cursors`; laptop:
  `AQ_DRM_DEVICES` iGPU-first for PRIME, idle-suspend listener).

## Shared infra: gnome.nix is left alone (no refactor)

`hyprland.nix` relies on gnome.nix's pipewire/bluetooth/fonts/keyring/GDM and
encodes that as `assertions` (CI-checked via eval-hosts). A zero-diff gnome.nix is
the only provably GNOME-identical option; both GUI hosts always import both
modules, so an extracted `desktop-common.nix` would be abstraction with no
differing consumer. If a Hyprland-only host ever appears, extract then.

Keyring needs nothing Hyprland-specific: GDM's PAM unlock
(`security.pam.services.gdm.enableGnomeKeyring`) fires for any session it
launches; `org.freedesktop.secrets` is D-Bus-activated inside Hyprland.

## Pitfalls → mitigations

1. **Services leaking into GNOME** → `wayland.systemd.target = hyprland-session.target`;
   blueman-applet via `systemdTargets`; verify in GNOME with
   `systemctl --user list-dependencies graphical-session.target`.
2. **nm-applet drags Waybar into GNOME** via `tray.target` → the `mkForce` rescope
   in session-services.nix is mandatory, not cosmetic.
3. **Notification clash** (gnome-shell owns `org.freedesktop.Notifications`) →
   covered by scoping; verify with `busctl --user status org.freedesktop.Notifications`.
4. **Portal regression in GNOME** (slow GTK apps, delayed notifications) → gnome.nix
   portal lines untouched; only additive `[hyprland]` config; retest GNOME
   screenshot/screenshare after switching.
5. **Double hyprland/portal packages** → HM `package = null; portalPackage = null`.
6. **NVIDIA cursor/flicker (desktop)** → `no_hardware_cursors = true` initially;
   no `GBM_BACKEND=nvidia-drm` (legacy advice, breaks current drivers).
7. **Laptop renders on dGPU** (battery drain, breaks RTD3) → `AQ_DRM_DEVICES`
   by-path iGPU-first; verify `runtime_status = suspended` at idle.
8. **`GTK_THEME` persisting across session switch** → bounded: `user@` stops at
   logout (no lingering), resetting the user environment.
9. **libadwaita apps + forced GTK_THEME render oddly** → fallback: drop the
   override, keep adw-gtk3 dark in-session.
10. **Insync autostarts in Hyprland too** (gnome.nix user service on
    `graphical-session.target`) — intended (sync everywhere), not a leak.

## Verification

Build-time: `nix flake check` → `nixos-rebuild build --flake .#desktop` /
`.#laptop` → optional `nvd diff /run/current-system ./result` (change should be
additive).

Post-switch checklist (Phase 1):
- GDM lists "Hyprland"; **GNOME session first** — identical behavior; scoped units
  all inactive (`systemctl --user status waybar swaync hypridle hyprpaper
  network-manager-applet blueman-applet hyprpolkitagent`); GNOME
  screenshot/screenshare still fine.
- Hyprland: waybar + tray applets; `notify-send` → swaync; `$mod+L` lock/unlock
  (PAM); idle lock/dpms; browser screenshare shows picker (portal); hyprshot to
  clipboard; cliphist picker; volume/media/brightness keys; `pkexec true` →
  polkit dialog; `secret-tool lookup` without prompt (keyring); XWayland app runs;
  Electron app native Wayland.
- Laptop: iGPU renders; NVIDIA suspended at idle; suspend on lid + idle timeout;
  resume OK. Desktop: crisp scaling incl. XWayland; later trial-remove
  `no_hardware_cursors`.
- Phase 2: palette visible everywhere (borders/bar/rofi/swaync/hyprlock/
  wallpaper/GTK); log back into GNOME → still adw-gtk3 (`echo $GTK_THEME`).

## To resolve during/after implementation

- Exact monitor connectors/modes/scales per host: placeholders ship with
  `mkDefault`; fill from `hyprctl monitors` after first login.
- Final keybind scheme beyond the initial set (workspace count, resize chords) —
  adjustable post-switch.
- Phase 2 wallpaper image: pick/commit a Macchiato-friendly image to `wallpapers/`
  (P1 uses a Nix-generated gradient meanwhile).
