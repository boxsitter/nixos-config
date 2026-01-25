# modules/nixos/services/netdata.nix
# Netdata real-time performance monitoring

{ config, lib, ... }:

with lib;

let
  cfg = config.services.netdata-custom;
in {
  options.services.netdata-custom = {
    enable = mkOption {
      type = types.bool;
      default = true; # enable on import
      description = "Enable Netdata monitoring";
    };

    port = mkOption {
      type = types.int;
      default = 19999;
      description = "Port for Netdata web interface";
    };
  };

  config = mkIf cfg.enable {
    services.netdata = {
      enable = true;
      config = {
        global = {
          "default port" = toString cfg.port;
          "bind to" = "*";
        };
        web = {
          "allow connections from" = "*";
          "allow dashboard from" = "*";
        };
      };
    };

    # Only allow local connections via firewall
    networking.firewall.interfaces.lo.allowedTCPPorts = [ cfg.port ];
  };
}
