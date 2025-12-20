# hosts/desktop/leyton.nix
# User configuration for leyton on desktop

{ ... }:

{
  imports = [
    ../../modules/home-manager/users/leyton.nix
    ../../modules/home-manager/core.nix
    ../../modules/home-manager/desktop.nix
  ];
}
