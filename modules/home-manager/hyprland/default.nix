# modules/home-manager/hyprland/default.nix
# Aggregator for the Hyprland user session. This is the single import point for
# a host's leyton.nix. Kept separate from desktop.nix (GNOME) so the two
# sessions' home configs never entangle.
#
# Phase 1 (functional) modules only. Phase 2 (the rice) adds ./theme and
# ./gtk.nix here.

{ ... }:

{
  imports = [
    ./hyprland.nix
    ./waybar.nix
    ./rofi.nix
    ./notifications.nix
    ./hyprlock.nix
    ./hypridle.nix
    ./wallpaper.nix
    ./session-services.nix
  ];
}
