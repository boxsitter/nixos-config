{ config, lib, pkgs, ... }:

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
          Origins = lib.mkForce "https://system.lhsv.net wss://system.lhsv.net http://127.0.0.1:9090 ws://127.0.0.1:9090";
        };
      };
    };

    # Enable Prometheus Node Exporter for metrics
    services.prometheus.exporters.node = {
      enable = true;
      port = 9100;
      enabledCollectors = [ "systemd" "processes" ];
      openFirewall = false;  # Only accessible locally
    };

    # Add packages for full Cockpit functionality
    environment.systemPackages = with pkgs; [
      cockpit
      kexec-tools  # For kdump/crash diagnostics
    ];
  };
}
