# modules/nixos/boot/grub.nix
# GRUB bootloader configuration

{ lib, ... }:

{
  boot.loader = {
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      useOSProber = true;
      
      # Auto-detect best resolution (works across different displays)
      gfxmodeEfi = "auto";
      
      # Remember last booted OS (convenient for dual-boot)
      default = "saved";
      
      # Theme for better appearance
      theme = null;  # Uses default theme (clean and modern)
      
      # Console-only mode for simplicity and speed
      extraConfig = ''
        terminal_input console
        terminal_output console
      '';
    };
    
    timeout = lib.mkDefault 5;  # Can be overridden per-host
    efi.canTouchEfiVariables = true;
  };
}
