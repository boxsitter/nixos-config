# modules/home-manager/hyprland/default.nix
# The Hyprland user session. Single import point for a host's leyton.nix, kept
# apart from desktop.nix (GNOME) so the two sessions' home configs never
# entangle. See ../../../docs/hyprland.md for the design.

{ ... }:

{
  imports = [
    ./theme
    ./scripts.nix
    ./hyprland.nix
    ./appearance.nix
    ./binds.nix
    ./rules.nix
    ./waybar.nix
    ./rofi.nix
    ./notifications.nix
    ./osd.nix
    ./lock.nix
    ./wallpaper.nix
    ./session-services.nix
  ];
}
