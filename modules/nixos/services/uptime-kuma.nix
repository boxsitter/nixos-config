{ config, lib, ... }:

with lib;

let
  cfg = config.services.uptime-kuma-custom;
in {
  options.services.uptime-kuma-custom = {
    enable = mkEnableOption "Uptime Kuma service monitoring";

    port = mkOption {
      type = types.int;
      default = 3001;
      description = "Port for Uptime Kuma web interface";
    };
  };

  config = mkIf cfg.enable {
    services.uptime-kuma = {
      enable = true;
      settings = {
        PORT = toString cfg.port;
        HOST = "127.0.0.1";
      };
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
