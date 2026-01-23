{ config, lib, ... }:

with lib;

let
  cfg = config.services.prowlarr-custom;
in {
  options.services.prowlarr-custom = {
    enable = mkOption {
      type = types.bool;
      default = true; # enable on import
      description = "Enable Prowlarr";
    };
  };

  config = mkIf cfg.enable {
    services.prowlarr = {
      enable = true;
      openFirewall = true;
    };
  };
}
