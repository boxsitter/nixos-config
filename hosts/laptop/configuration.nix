# ./hosts/laptop/configuration.nix
# Laptop system with NVIDIA RTX 3050 Mobile, optimized for battery life and portability

{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/core.nix
    ../../modules/nixos/secrets.nix
    ../../modules/nixos/boot/grub.nix
    ../../modules/nixos/hardware/nvidia-laptop.nix
    ../../modules/nixos/hardware/dual-boot.nix
    ../../modules/nixos/hardware/intel-wifi.nix
    ../../modules/nixos/services/gnome.nix
    # ../../modules/nixos/services/samba-client.nix  # TODO: Re-enable after running setup script
    ../../modules/nixos/programs/1password-gui.nix
  ];

  environment.systemPackages = with pkgs; [
    brightnessctl
    powertop
    acpi
  ];

  networking.hostName = "nixos-laptop";

  nixpkgs = {
    config = {
      allowUnfree = true;
      nvidia.acceptLicense = true;
    };
  };

  # `auto-cpufreq` conflicts with `power-profiles-daemon`.
  # Prefer `auto-cpufreq` for laptops since it applies cpu/battery tuning
  # automatically without relying on desktop power profile integration.
  services.power-profiles-daemon.enable = false;

  services.thermald.enable = true;
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

  programs.light.enable = true;

  services.ratbagd.enable = true;
}
