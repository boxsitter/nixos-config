{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.filebrowser-custom;
in {
  options.services.filebrowser-custom = {
    enable = mkEnableOption "FileBrowser web-based file manager";

    port = mkOption {
      type = types.int;
      default = 8082;
      description = "Port for FileBrowser web interface";
    };

    rootDir = mkOption {
      type = types.str;
      default = "/home/leyton/media";
      description = "Root directory for file browsing";
    };
  };

  config = mkIf cfg.enable {
    # FileBrowser doesn't have a native NixOS service, so we'll create one
    systemd.services.filebrowser = {
      description = "FileBrowser web-based file manager";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = "filebrowser";
        Group = "media";
        ExecStart = "${pkgs.filebrowser}/bin/filebrowser -a 127.0.0.1 -p ${toString cfg.port} -r ${cfg.rootDir} -d /var/lib/filebrowser/filebrowser.db";
        Restart = "on-failure";
        RestartSec = "10s";
        
        # Security settings
        StateDirectory = "filebrowser";
        
        # Hardening
        NoNewPrivileges = true;
        PrivateTmp = true;
      };

      # Ensure clean restart on activation
      restartIfChanged = true;
      stopIfChanged = true;
    };

    # Create filebrowser user
    users.users.filebrowser = {
      isSystemUser = true;
      group = "media";
      home = "/var/lib/filebrowser";
      createHome = true;
    };

    environment.systemPackages = [ pkgs.filebrowser ];
    
    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
