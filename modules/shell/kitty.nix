# ./modules/shell/kitty.nix
{ pkgs, ... }:

{
  # Install Nerd Fonts system-wide for all applications
  fonts.packages = [
    pkgs.nerd-fonts._0xproto
    pkgs.nerd-fonts.droid-sans-mono
  ];

  # Kitty configuration is now in Home Manager
  # This module just ensures fonts are available
}
