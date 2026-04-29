# modules/nixos/services/netdata.nix
# Netdata real-time performance monitoring

{ config, lib, pkgs, ... }:

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
      package = pkgs.netdata.override {
        withCloudUi = true;
      };
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
      configDir."python.d.conf" = pkgs.writeText "python.d.conf" ''
        samba: yes
      '';
    };

    # Add samba and sudo to path of netdata service
    systemd.services.netdata.path = [ pkgs.samba "/run/wrappers" ];

    # Permit netdata to run sudo smbstatus -P
    security.sudo.extraConfig = ''
      netdata ALL=(root) NOPASSWD: ${pkgs.samba}/bin/smbstatus
    '';

    # Add capability for samba plugin
    systemd.services.netdata.serviceConfig.CapabilityBoundingSet = ["CAP_SETGID"];

    # Only allow local connections via firewall
    networking.firewall.interfaces.lo.allowedTCPPorts = [ cfg.port ];
  };
}
