# modules/nixos/services/server/audiobookshelf.nix
# Audiobookshelf audiobook/podcast server

{ lib, ... }:

{
  users.users.audiobookshelf.extraGroups = [ "media" ];

  services.audiobookshelf = {
    enable = true;
    host = "127.0.0.1";
    port = 13378;
    openFirewall = false;
  };

  systemd.services.audiobookshelf.serviceConfig = {
    UMask = lib.mkForce "0002";
    ReadWritePaths = [ "/var/lib/media/audiobooks" ];
  };
}
