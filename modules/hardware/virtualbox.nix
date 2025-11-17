# ./modules/hardware/virtualbox.nix
# VirtualBox guest additions for VM

{ config, pkgs, ... }:

{
  # VirtualBox guest additions
  virtualisation.virtualbox.guest.enable = true;
  virtualisation.virtualbox.guest.x11 = true;  # Enable X11 support
  
  # Basic graphics for VM (no NVIDIA)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  
  # Use a stable kernel for VirtualBox compatibility
  boot.kernelPackages = pkgs.linuxPackages;
}
