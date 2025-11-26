# home/leyton/vm.nix
# VM-specific user configuration

{ ... }:

{
  imports = [
    ../../modules/home/common.nix
    ../../modules/home/hyprland.nix
  ];
}