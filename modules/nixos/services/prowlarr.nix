# modules/nixos/services/prowlarr.nix
# Prowlarr indexer manager for Radarr/Sonarr

{ ... }:

{
  # Define the prowlarr user and group
  users.users.prowlarr = {
    isSystemUser = true;
    group = "prowlarr";
    extraGroups = [ "media" ];
  };
  users.groups.prowlarr = {};

  services.prowlarr = {
    enable = true;
    openFirewall = false; # Accessed via Caddy
  };

  # Ensure any files created by Prowlarr are group-writable.
  systemd.services.prowlarr.serviceConfig.UMask = "0002";
}
