# modules/nixos/services/mealie.nix
# Mealie recipe manager and meal planner

{ config, lib, ... }:

with lib;

let
  cfg = config.services.mealie-custom;
in {
  options.services.mealie-custom = {
    enable = mkOption {
      type = types.bool;
      default = true; # enable on import
      description = "Enable Mealie recipe manager";
    };

    port = mkOption {
      type = types.int;
      default = 9925;
      description = "Port for Mealie web interface";
    };
  };

  config = mkIf cfg.enable {
    services.mealie = {
      enable = true;
      port = cfg.port;
      listenAddress = "127.0.0.1";
    };
  };
}
