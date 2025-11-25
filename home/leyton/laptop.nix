# home/leyton/laptop.nix
# Laptop-specific user configuration with GUI apps

{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../modules/home-manager/common.nix
    ../../modules/home-manager/shell.nix
    ../../modules/home-manager/hyprland.nix
  ];

  # Laptop-specific overrides
  programs.kitty.font.size = 13;  # Slightly smaller for laptop screen
}
