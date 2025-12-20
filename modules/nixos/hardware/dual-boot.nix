# modules/nixos/hardware/dual-boot.nix
# Dual-boot configuration for systems with Windows

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    os-prober
    ntfs3g
  ];
}
