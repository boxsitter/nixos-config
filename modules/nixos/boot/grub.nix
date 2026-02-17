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
      # Speed up: Don't re-run os-prober on every rebuild
      # Set to false after initial setup, manually re-enable if Windows updates
      extraPerEntryConfig = "insmod all_video";
      configurationLimit = 10;  # Keep only last 10 generations in menu
      
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
