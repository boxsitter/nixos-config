# home/leyton/laptop.nix
# Laptop-specific user configuration

{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../modules/home/common.nix
    ../../modules/home/hyprland.nix
  ];

  # Laptop-specific overrides
  programs.kitty.font.size = 13;  # Slightly smaller for laptop screen
}
