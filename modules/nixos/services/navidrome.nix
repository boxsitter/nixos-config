# modules/nixos/services/navidrome.nix
# Navidrome music server

{ lib, ... }:

{
  services.navidrome = {
    enable = true;
    settings = {
      Address = "127.0.0.1";
      Port = 4533;
      MusicFolder = "/home/leyton/media/navidrome/music";
      EnableCoverAnimation = true;
      Scanner.ExtractFullAudioMetadata = true;
      TranscodingCacheSize = "1GB";
    };
  };

  users.groups.media = { };

  users.users.navidrome.extraGroups = [ "media" ];
  users.users.leyton.extraGroups = [ "media" ];

  # Allow group writes to newly created files
  systemd.services.navidrome.serviceConfig.UMask = lib.mkForce "0002";
  
  # Disable ProtectHome so Navidrome can access /home/leyton/media
  systemd.services.navidrome.serviceConfig.ProtectHome = lib.mkForce false;

  systemd.tmpfiles.rules = [
    "d /home/leyton/media/navidrome 2775 leyton media -"
    "d /home/leyton/media/navidrome/music 2775 leyton media -"
  ];
}
