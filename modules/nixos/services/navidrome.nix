# modules/nixos/services/navidrome.nix
# Navidrome music server

{ lib, ... }:

{
  # Add the navidrome user to the shared 'media' group
  users.users.navidrome.extraGroups = [ "media" ];

  services.navidrome = {
    enable = true;
    settings = {
      # Point to the shared, global music library
      MusicFolder = "/var/lib/media/music";
      Address = "127.0.0.1"; # Accessed via Caddy reverse proxy
      Port = 4533;
      EnableCoverAnimation = true;
      Scanner.ExtractFullAudioMetadata = true;
      TranscodingCacheSize = "1GB";
    };
  };

  # Ensure new files created by Navidrome are group-writable.
  systemd.services.navidrome.serviceConfig.UMask = lib.mkForce "0002";
}
