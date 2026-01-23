{ config, lib, ... }:

with lib;

let
  cfg = config.services.cockpit-custom;
in {
  options.services.cockpit-custom = {
    enable = mkOption {
      type = types.bool;
      default = true; # enable on import
      description = "Enable Cockpit web UI";
    };

    port = mkOption {
      type = types.int;
      default = 9090;
      description = "Port for Cockpit web interface";
    };
  };

  config = mkIf cfg.enable {
    services.cockpit = {
      enable = true;
      port = cfg.port;

      settings = {
        WebService = {
          AllowUnencrypted = true;  # Since we're behind Caddy with TLS
          ProtocolHeader = "X-Forwarded-Proto";
          LoginTitle = "NixOS Server";
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
