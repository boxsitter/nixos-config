# ./hosts/laptop/configuration.nix
# Laptop system with NVIDIA RTX 3050 Mobile, optimized for battery life and portability

{ config, pkgs, ... }:

{
  imports = [
    # Hardware and system modules
    ./hardware-configuration.nix
    ../../modules/nixos/common.nix
    ../../modules/nixos/boot/grub.nix
    ../../modules/nixos/hardware/nvidia-laptop.nix
    ../../modules/nixos/gui/hyprland.nix
    
    # Package imports
    ../../modules/nixos/packages/cli.nix
    ../../modules/nixos/packages/gui.nix
    ../../modules/nixos/packages/dual-boot.nix
    ../../modules/nixos/packages/laptop.nix
  ];

  # Set the flavor system-wide for Catppuccin modules
  catppuccin.flavor = "macchiato";

  # Hostname for laptop
  networking.hostName = "nixos-laptop";

  # Laptop-specific firmware
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;
  boot.kernelModules = [ "iwlwifi" ];  # Intel WiFi

  # Laptop power management
  services.thermald.enable = true;  # Thermal management
  services.auto-cpufreq = {
    enable = true;
    settings = {
      battery = {
        governor = "powersave";
        turbo = "auto";
      };
      charger = {
        governor = "performance";
        turbo = "auto";
      };
    };
  };

  # TLP for advanced battery management (conflicts with auto-cpufreq, choose one)
  # services.tlp.enable = true;

  # Backlight control
  programs.light.enable = true;

  # 1Password GUI
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "leyton" ];
  };

  # TLP for battery management  system.stateVersion = "24.11";
}
