# hosts/server/leyton.nix
# User configuration for leyton on server

{ ... }:

{
  imports = [
    ../../modules/home-manager/users/leyton.nix
    ../../modules/home-manager/core.nix
  ];
}
