# hosts/server/configuration.nix
# Headless server configuration

{ pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/core.nix
    ../../modules/nixos/secrets.nix
    ../../modules/nixos/boot/systemd-boot.nix
    ../../modules/nixos/services/server/minecraft.nix
    ../../modules/nixos/services/server/samba.nix
    ../../modules/nixos/services/server/playit.nix
    ../../modules/nixos/services/server/immich.nix
    ../../modules/nixos/services/server/komga.nix
    ../../modules/nixos/services/server/caddy.nix
    ../../modules/nixos/services/server/navidrome.nix
    ../../modules/nixos/services/server/jellyfin.nix
    ../../modules/nixos/services/server/qbittorrent.nix
    ../../modules/nixos/services/server/homepage.nix
    ../../modules/nixos/services/server/prowlarr.nix
    ../../modules/nixos/services/server/radarr.nix
    ../../modules/nixos/services/server/sonarr.nix
    ../../modules/nixos/services/server/sabnzbd.nix
    ../../modules/nixos/services/server/lidarr.nix
    ../../modules/nixos/services/server/mealie.nix
    ../../modules/nixos/services/server/hydra-server.nix
    ../../modules/nixos/services/server/monitoring.nix
  ];

  networking.hostName = "nixos-server";

  nixpkgs.config.allowUnfree = true;

  # Allow derivations that set __noChroot = true to bypass the sandbox.
  # Required for hydra-server. All other derivations remain sandboxed.
  nix.settings.sandbox = "relaxed";

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

  users.groups.media = {};
  users.users.leyton.extraGroups = [ "media" ];

  systemd.tmpfiles.rules = [
    "d /var/lib/media 2775 root media -"
    "d /var/lib/media/movies 2775 root media -"
    "d /var/lib/media/shows 2775 root media -"
    "d /var/lib/media/music 2775 root media -"
    "d /var/lib/media/manga 2775 root media -"
    "Z /var/lib/media/manga 2775 root media -"  # Recursively fix permissions on subdirectories
    "d /var/lib/media/photos 2775 root media -"
    "d /var/lib/media/books 2775 root media -"
    "d /var/lib/media/downloads 2775 root media -"
  ];
}
