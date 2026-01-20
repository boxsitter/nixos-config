# hosts/server/configuration.nix
# Headless server configuration

{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/core.nix
    ../../modules/nixos/boot/systemd-boot.nix
    ../../modules/nixos/services/minecraft.nix
    ../../modules/nixos/services/samba.nix
    ../../modules/nixos/services/playit.nix
    ../../modules/nixos/services/immich.nix
  ];

  networking.hostName = "nixos-server";

  # Performance settings
  powerManagement.cpuFreqGovernor = "performance";

  # Enable VS Code Server for Remote-SSH
  programs.nix-ld.enable = true;
  
  # Server-specific packages
  environment.systemPackages = with pkgs; [
    mcrcon  # Minecraft RCON client for interactive console
  ];

  # Server-specific configurations
  services.timesyncd.enable = true;  # NTP time sync
  
  # Automatic security updates
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;  # Set to true if you want automatic reboots
    dates = "daily";
    flake = "/home/leyton/nixos-config";
  };

  # Firewall - only allow SSH through Tailscale
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ ];  # SSH already allowed via Tailscale in ssh.nix
    allowedUDPPorts = [ ];
  };
}
