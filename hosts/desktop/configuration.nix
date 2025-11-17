# ./hosts/desktop/configuration.nix
# Desktop system with NVIDIA RTX 5080, dual-boot, and Hyprland

{ config, pkgs, ... }:

{
  imports = [
    # Hardware detection - references the system's hardware config
    /etc/nixos/hardware-configuration.nix
    
    # Shared modules
    ../../modules/core.nix
    ../../modules/shell/fish.nix
    ../../modules/shell/kitty.nix
    
    # Desktop-specific
    ../../modules/boot/grub.nix
    ../../modules/hardware/nvidia.nix
    ../../modules/gui/hyprland.nix
  ];

  # Set the flavor system-wide for Catppuccin modules
  catppuccin.flavor = "macchiato";

  # Hostname for desktop
  networking.hostName = "nixos-desktop";

  # Desktop-specific firmware
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;
  boot.kernelModules = [ "iwlwifi" ];  # Intel WiFi

  # 1Password GUI for desktop
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "leyton" ];
  };

  # Desktop-specific packages
  environment.systemPackages = with pkgs; [
    os-prober   # For detecting Windows in dual-boot
    ntfs3g      # For Windows partition support
  ];

  system.stateVersion = "24.11";
}
