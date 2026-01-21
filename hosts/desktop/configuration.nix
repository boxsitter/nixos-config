# ./hosts/desktop/configuration.nix
# Desktop system with NVIDIA RTX 5080, dual-boot, and GNOME

{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/core.nix
    ../../modules/nixos/boot/grub.nix
    ../../modules/nixos/hardware/nvidia-desktop.nix
    ../../modules/nixos/hardware/dual-boot.nix
    ../../modules/nixos/hardware/intel-wifi.nix
    ../../modules/nixos/services/gnome.nix
    ../../modules/nixos/services/hyprland.nix
    ../../modules/nixos/services/samba-client.nix
    ../../modules/nixos/programs/1password-gui.nix
  ];

  networking.hostName = "nixos-desktop";

  powerManagement.cpuFreqGovernor = "performance";
  services.power-profiles-daemon.enable = false;
  
  boot.kernelParams = [ "preempt=none" ];
}
