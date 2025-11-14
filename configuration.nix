# ./configuration.nix

{ pkgs, ... }:

{
  imports = [
    # Using relative paths makes your configuration portable.
    ./modules/core.nix
    ./modules/gui/hyprland.nix     # Switch to Hyprland
    ./modules/shell/fish.nix
    ./modules/shell/kitty.nix
  ];

  # Set the flavor system-wide for other Catppuccin modules to use
  catppuccin.flavor = "macchiato";

  # Set the system's state version
  system.stateVersion = "24.11";
}