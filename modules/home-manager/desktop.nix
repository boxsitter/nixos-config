# modules/home-manager/desktop.nix
# Desktop/laptop GUI configuration
# Adds GUI programs to core config

{ ... }:

{
  imports = [
    ./theming.nix
    ./gnome.nix
    ./programs/kitty.nix
    ./programs/hyprland.nix
    ./programs/rofi.nix
    ./programs/waybar.nix
    ./programs/swaync.nix
    ./desktop-apps.nix
  ];
}
