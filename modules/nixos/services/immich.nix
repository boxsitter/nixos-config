# modules/nixos/services/immich.nix
# Immich self-hosted photo and video backup server

{ ... }:

{
  services.immich = {
    enable = true;
    mediaLocation = "/home/leyton/media/photos";
  };

  # Ensure media directory exists with correct permissions
  systemd.tmpfiles.rules = [
    "d /home/leyton/media/photos 0755 leyton users -"
  ];
}
