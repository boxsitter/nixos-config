# modules/nixos/services/jellyfin.nix
# Jellyfin media server (movies/TV/music)

{ lib, ... }:

{
  # Add the jellyfin user to the shared 'media' group
  users.users.jellyfin.extraGroups = [ "media" "video" "render" ];

  services.jellyfin = {
    enable = true;
    openFirewall = false; # Accessed via Caddy reverse proxy
  };

  # Ensure new files created by Jellyfin (metadata, etc.) are group-writable.
  systemd.services.jellyfin.serviceConfig.UMask = lib.mkForce "0002";
}
