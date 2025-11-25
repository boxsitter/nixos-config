# modules/nixos/packages/dual-boot.nix
# Packages for dual-boot systems (desktop/laptop only)

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    os-prober
    ntfs3g
  ];
}
