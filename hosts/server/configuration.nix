# hosts/server/configuration.nix
# Headless server configuration

{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/core.nix
    ../../modules/nixos/boot/systemd-boot.nix
  ];

  networking.hostName = "nixos-server";

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
