# modules/home-manager/hyprland/rofi.nix
# Application launcher / dmenu for the Hyprland session. pkgs.rofi is
# Wayland-capable on current nixpkgs (rofi-wayland merged upstream). Phase 1
# uses a built-in theme; Phase 2 swaps in a rasi theme generated from the
# palette.

{ ... }:

{
  programs.rofi = {
    enable = true;
    terminal = "kitty";
    theme = "gruvbox-dark"; # placeholder built-in theme; replaced in Phase 2
  };
}
