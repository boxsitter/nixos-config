# modules/nixos/boot/systemd-boot.nix
# Systemd-boot bootloader configuration for UEFI systems

{ ... }:

{
  boot.loader = {
    systemd-boot = {
      enable = true;
      consoleMode = "auto";
    };
    efi.canTouchEfiVariables = true;
    timeout = 3;
  };
}
