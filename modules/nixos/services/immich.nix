# modules/nixos/services/immich.nix
# Immich self-hosted photo and video backup server

{ ... }:

{
  services.immich = {
    enable = true;
    host = "0.0.0.0";
  };
  
  users.users.leyton.extraGroups = [ "immich" ];
}
