# ./hosts/desktop/configuration.nix
# Desktop system with NVIDIA RTX 5080, dual-boot, and Hyprland

{ config, pkgs, ... }:

{
  imports = [
    # Hardware and system modules
    ./hardware-configuration.nix
    ../../modules/nixos/common.nix
    ../../modules/nixos/boot/grub.nix
    ../../modules/nixos/hardware/nvidia.nix
    ../../modules/nixos/gui/hyprland.nix
    
    # Package imports
    ../../modules/nixos/packages/cli.nix
    ../../modules/nixos/packages/gui.nix
    ../../modules/nixos/packages/dual-boot.nix
  ];

  # Set the flavor system-wide for Catppuccin modules
  catppuccin.flavor = "macchiato";

  # Hostname for desktop
  networking.hostName = "nixos-desktop";

  # Desktop-specific firmware
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;
  boot.kernelModules = [ "iwlwifi" ];  # Intel WiFi

  # Performance-focused power management for desktop
  powerManagement.cpuFreqGovernor = "performance";
  services.power-profiles-daemon.enable = false;  # Disable to avoid conflicts
  
  # Performance tuning
  boot.kernelParams = [
    "preempt=none"  # Better for desktop performance
  ];

  # 1Password GUI for desktop
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "leyton" ];
  };

  system.stateVersion = "24.11";
}
