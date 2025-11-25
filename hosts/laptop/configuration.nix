# ./hosts/laptop/configuration.nix
# Laptop system with NVIDIA RTX 3050 Mobile, optimized for battery life and portability

{ config, pkgs, ... }:

{
  imports = [
    # Hardware detection
    ./hardware.nix
    
    # Shared modules
    ../../modules/nixos/common.nix
    ../../modules/nixos/shell/fish.nix
    ../../modules/nixos/shell/kitty.nix
    
    # Laptop-specific
    ../../modules/nixos/boot/grub.nix
    ../../modules/nixos/hardware/nvidia-laptop.nix
    ../../modules/nixos/gui/hyprland.nix
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

  # Laptop-specific packages
  environment.systemPackages = with pkgs; [
    os-prober   # For detecting Windows in dual-boot
    ntfs3g      # For Windows partition support
    vscode
    brightnessctl  # Screen brightness control
    powertop      # Power consumption monitoring
    acpi          # Battery status
  ];

  system.stateVersion = "24.11";
}
