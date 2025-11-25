# ./hosts/desktop/configuration.nix
# Desktop system with NVIDIA RTX 5080, dual-boot, and Hyprland

{ config, pkgs, ... }:

{
  imports = [
    # Hardware detection
    ./hardware.nix
    
    # Shared modules
    ../../modules/nixos/common.nix
    ../../modules/nixos/shell/fish.nix
    ../../modules/nixos/shell/kitty.nix
    
    # Desktop-specific
    ../../modules/nixos/boot/grub.nix
    ../../modules/nixos/hardware/nvidia.nix
    ../../modules/nixos/gui/hyprland.nix
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

  # Desktop-specific packages
  environment.systemPackages = with pkgs; [
    os-prober   # For detecting Windows in dual-boot
    ntfs3g      # For Windows partition support
    vscode
  ];

  system.stateVersion = "24.11";
}
