# hosts/server/configuration.nix
# Headless server configuration

{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/core.nix
    ../../modules/nixos/boot/grub.nix
  ];

  networking.hostName = "nixos-server";
}
