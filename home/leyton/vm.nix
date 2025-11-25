# home/leyton/vm.nix
# VM-specific user configuration

{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../modules/home/common.nix
    ../../modules/home/hyprland.nix
  ];
}