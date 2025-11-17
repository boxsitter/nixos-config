# ./modules/boot/grub.nix
# GRUB bootloader configuration for dual-boot

{ config, pkgs, ... }:

{
  boot.loader = {
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      useOSProber = true;  # This detects Windows
      timeout = 10;
    };
    efi.canTouchEfiVariables = true;
  };
}
