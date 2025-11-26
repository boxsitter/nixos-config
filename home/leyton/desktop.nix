# home/leyton/desktop.nix
# Desktop-specific user configuration

{ ... }:

{
  imports = [
    ../../modules/home/common.nix
    ../../modules/home/hyprland.nix
  ];
}
