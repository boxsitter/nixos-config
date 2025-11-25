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
      
      # Fix tiny text on high-resolution displays
      # Use 1024x768 for better readability on 4K+ displays
      gfxmodeEfi = "1024x768";
      
      # Set Windows as default boot option (starts counting from 0)
      # Typically: 0=NixOS current, 1=NixOS generations submenu, 2=Windows
      default = 2;
    };
    timeout = 10;
    efi.canTouchEfiVariables = true;
  };
  
  # Performance: reduce input lag in GRUB
  boot.loader.grub.extraConfig = ''
    # Disable graphical terminal for faster input response
    terminal_input console
    terminal_output console
  '';
}
