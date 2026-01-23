# modules/nixos/services/immich.nix
# Immich self-hosted photo and video backup server

{ lib, ... }:

{
  services.immich = {
    enable = true;
    host = "0.0.0.0";
    mediaLocation = "/var/lib/immich";
  };
  
  users.users.leyton.extraGroups = [ "immich" ];

  # Allow group (immich) to read/write new files by using umask 0002
  systemd.services.immich-server.serviceConfig.UMask = lib.mkForce "0002";
  
  # Ensure proper permissions on Immich media directory (default location)
  systemd.tmpfiles.rules = [
    "d /var/lib/immich 2775 immich immich -"
    "d /var/lib/immich/encoded-video 2775 immich immich -"
    "f /var/lib/immich/encoded-video/.immich 0664 immich immich -"
    "d /var/lib/immich/profile 2775 immich immich -"
    "f /var/lib/immich/profile/.immich 0664 immich immich -"
    "d /var/lib/immich/thumbs 2775 immich immich -"
    "f /var/lib/immich/thumbs/.immich 0664 immich immich -"
    "d /var/lib/immich/upload 2775 immich immich -"
    "f /var/lib/immich/upload/.immich 0664 immich immich -"
    "d /var/lib/immich/library 2775 immich immich -"
    "f /var/lib/immich/library/.immich 0664 immich immich -"
    "d /var/lib/immich/backups 2775 immich immich -"
    "f /var/lib/immich/backups/.immich 0664 immich immich -"
  ];
}
