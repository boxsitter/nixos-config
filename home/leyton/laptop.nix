# home/leyton/laptop.nix
# Laptop-specific user configuration

{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../modules/home/common.nix
    ../../modules/home/hyprland.nix
  ];

  # Override monitor config for laptop - auto-detect display
  wayland.windowManager.hyprland.settings.monitor = [
    ",preferred,auto,1"  # Auto-detect laptop screen
  ];

  # Laptop-specific overrides
  programs.kitty.font.size = 13;  # Slightly smaller for laptop screen
}
