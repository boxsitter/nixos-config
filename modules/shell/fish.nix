# ./modules/shell/fish.nix
{ pkgs, ... }:

{
  # Enable the fish shell program system-wide
  # User configuration is now in Home Manager
  programs.fish.enable = true;
}