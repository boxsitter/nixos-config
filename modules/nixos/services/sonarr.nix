{ config, lib, ... }:

with lib;

let
  cfg = config.services.sonarr-custom;
in {
  options.services.sonarr-custom = {
    enable = mkEnableOption "Sonarr TV show automation";

    downloadDir = mkOption {
      type = types.str;
      default = "/home/leyton/downloads";
      description = "Directory where torrents are downloaded";
    };

    mediaDir = mkOption {
      type = types.str;
      default = "/home/leyton/media/jellyfin/shows";
      description = "Directory for organized TV shows";
    };
  };

  config = mkIf cfg.enable {
    services.sonarr = {
      enable = true;
      openFirewall = true;
      dataDir = "/var/lib/sonarr";
    };

    # Ensure media directories exist
    systemd.tmpfiles.rules = [
      "d ${cfg.downloadDir} 2775 sonarr media -"
      "d ${cfg.mediaDir} 2775 sonarr media -"
    ];

    # Add sonarr user to media group
    users.users.sonarr.extraGroups = [ "media" ];
  };
}
