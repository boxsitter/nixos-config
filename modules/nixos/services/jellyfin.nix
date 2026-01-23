# modules/nixos/services/jellyfin.nix
# Jellyfin media server (movies/TV/music)

{ lib, ... }:

{
  services.jellyfin = {
    enable = true;
    user = "jellyfin";
    group = "media";
    openFirewall = false;
  };

  users.groups.media = { };

  users.users.jellyfin.extraGroups = [ "media" "video" "render" ];
  users.users.leyton.extraGroups = [ "media" ];

  # Keep group write on media created by Jellyfin
  systemd.services.jellyfin.serviceConfig.UMask = lib.mkForce "0002";

  # Ensure Jellyfin state directory exists with shared group
  systemd.tmpfiles.rules = [
    "d /var/lib/jellyfin 2770 jellyfin media -"
    "d /home/leyton/media/jellyfin 2775 leyton media -"
    "d /home/leyton/media/jellyfin/movies 2775 leyton media -"
    "d /home/leyton/media/jellyfin/shows 2775 leyton media -"
  ];
}
