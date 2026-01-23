{ config, lib, ... }:

with lib;

let
  cfg = config.services.prowlarr-custom;
in {
  options.services.prowlarr-custom = {
    enable = mkEnableOption "Prowlarr indexer manager";
  };

  config = mkIf cfg.enable {
    services.prowlarr = {
      enable = true;
      openFirewall = true;
    };
  };
}
