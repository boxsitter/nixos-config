# modules/nixos/services/immich.nix
# Immich self-hosted photo and video backup server

{ lib, ...}:

{
  # Add the immich user to the shared 'media' group
  users.users.immich.extraGroups = [ "media" ];

  services.immich = {
    enable = true;
    # Let immich use its default data directory for the database, thumbnails, etc.
    # We will only override the location for the original photo files.
    settings = {
      storage.uploadLocation = "/var/lib/media/photos";
    };

    host = "0.0.0.0";
  };

  # Ensure new files created by Immich (thumbnails, etc.) are group-writable
  # within its own data directory (/var/lib/immich).
  systemd.services.immich-server.serviceConfig.UMask = lib.mkForce "0002";
}
