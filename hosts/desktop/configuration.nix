# ./hosts/desktop/configuration.nix
# Desktop system with NVIDIA RTX 5080, dual-boot, and GNOME

{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/core.nix
    ../../modules/nixos/secrets.nix
    ../../modules/nixos/boot/grub.nix
    ../../modules/nixos/hardware/nvidia-desktop.nix
    ../../modules/nixos/hardware/dual-boot.nix
    ../../modules/nixos/hardware/intel-wifi.nix
    ../../modules/nixos/services/gnome.nix
    ../../modules/nixos/services/hyprland.nix
    ../../modules/nixos/programs/1password-gui.nix
    ../../modules/nixos/programs/steam.nix
  ];

  networking.hostName = "nixos-desktop";

  nixpkgs = {
    config = {
      allowUnfree = true;
      nvidia.acceptLicense = true;
    };
  };

  powerManagement.cpuFreqGovernor = "performance";
  services.power-profiles-daemon.enable = false;
  
  # Use full preemption for desktop responsiveness
  boot.kernelParams = [ "preempt=full" ];

  # Docker
  virtualisation.docker.enable = true;

  services.ratbagd.enable = true;
}
