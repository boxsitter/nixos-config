# modules/nixos/services/lidarr.nix
# Lidarr music collection manager

{ lib, ... }:

{
  # Add the lidarr user to the shared 'media' group
  users.users.lidarr.extraGroups = [ "media" ];

  services.lidarr = {
    enable = true;
    openFirewall = false; # Accessed via Caddy
  };

  # Ensure any files created by Lidarr are group-writable.
  systemd.services.lidarr.serviceConfig = {
    UMask = lib.mkForce "0002";
    StateDirectory = "lidarr";
  };
}
