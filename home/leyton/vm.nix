# home/leyton/vm.nix
# VM-specific user configuration with GUI apps

{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../modules/home-manager/common.nix
    ../../modules/home-manager/shell.nix
    ../../modules/home-manager/hyprland.nix
  ];

  home.username = "leyton";
  home.homeDirectory = "/home/leyton";
}