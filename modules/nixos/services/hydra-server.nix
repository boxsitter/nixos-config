# modules/nixos/services/hydra-server.nix
# Hydra Server - notification backend for Hydra Reddit client

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.hydra-server-custom;
  hydra-server = pkgs.callPackage ../../../pkgs/hydra-server { };
in {
  options.services.hydra-server-custom = {
    enable = mkOption {
      type = types.bool;
      default = true; # enable on import
      description = "Enable Hydra Server notification backend";
    };

    port = mkOption {
      type = types.int;
      default = 3002;
      description = "Port for Hydra Server";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/hydra-server";
      description = "Directory to store Hydra Server data (database)";
    };
  };

  config = mkIf cfg.enable {
    # Create system user
    users.users.hydra-server = {
      isSystemUser = true;
      group = "hydra-server";
      description = "Hydra Server service user";
      home = cfg.dataDir;
      createHome = true;
    };

    users.groups.hydra-server = {};

    # Ensure data directory exists with correct permissions
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 hydra-server hydra-server -"
    ];

    # Systemd service
    systemd.services.hydra-server = {
      description = "Hydra Server - Reddit notification backend";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      environment = {
        NODE_ENV = "production";
        PORT = toString cfg.port;
        IS_CUSTOM_SERVER = "true";
      };

      serviceConfig = {
        Type = "simple";
        User = "hydra-server";
        Group = "hydra-server";
        WorkingDirectory = "${hydra-server}/lib/hydra-server";
        ExecStart = "${hydra-server}/bin/hydra-server";
        Restart = "always";
        RestartSec = "5";

        # Security hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        
        # Bind mount dataDir to /data for the hardcoded path
        BindPaths = "${cfg.dataDir}:/data";
        ReadWritePaths = [ cfg.dataDir ];

        # Load secrets from sops
        EnvironmentFile = config.sops.secrets.hydra-server-env.path;
      };
    };

    # Configure sops secret
    sops.secrets.hydra-server-env = {
      sopsFile = ../../../secrets/secrets.yaml;
      owner = "hydra-server";
      group = "hydra-server";
      mode = "0400";
    };
  };
}
