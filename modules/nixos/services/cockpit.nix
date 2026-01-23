{ config, lib, ... }:

with lib;

let
  cfg = config.services.cockpit-custom;
in {
  options.services.cockpit-custom = {
    enable = mkEnableOption "Cockpit web-based server management";

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

    # Cockpit includes monitoring, so we don't need separate tools
    # It provides: system stats, service management, logs, terminal, storage, networking
    
    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
