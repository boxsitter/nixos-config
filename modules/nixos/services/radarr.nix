{ config, lib, ... }:

with lib;

let
  cfg = config.services.radarr-custom;
in {
  options.services.radarr-custom = {
    enable = mkOption {
      type = types.bool;
      default = true; # enable on import
      description = "Enable Radarr";
    };

    downloadDir = mkOption {
      type = types.str;
      default = "/home/leyton/downloads";
      description = "Directory where torrents are downloaded";
    };

    mediaDir = mkOption {
      type = types.str;
      default = "/home/leyton/media/jellyfin/movies";
      description = "Directory for organized movies";
    };
  };

  config = mkIf cfg.enable {
    services.radarr = {
      enable = true;
      openFirewall = true;
      dataDir = "/var/lib/radarr";
    };

    # Ensure media directories exist
    systemd.tmpfiles.rules = [
      "d ${cfg.downloadDir} 2775 radarr media -"
      "d ${cfg.mediaDir} 2775 radarr media -"
    ];

    # Add radarr user to media group
    users.users.radarr.extraGroups = [ "media" ];
  };
}
