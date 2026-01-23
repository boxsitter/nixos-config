{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.transmission-custom;
in {
  options.services.transmission-custom = {
    enable = mkOption {
      type = types.bool;
      default = true; # enable on import
      description = "Enable Transmission BitTorrent daemon";
    };

    downloadDir = mkOption {
      type = types.str;
      default = "/home/leyton/downloads";
      description = "Directory to store downloaded files";
    };

    rpcPort = mkOption {
      type = types.int;
      default = 9091;
      description = "Port for RPC interface";
    };

    peerPort = mkOption {
      type = types.int;
      default = 51413;
      description = "Port for incoming peer connections";
    };
  };

  config = mkIf cfg.enable {
    # Ensure download directories exist before service starts
    systemd.tmpfiles.rules = [
      "d ${cfg.downloadDir} 2775 transmission media -"
      "d ${cfg.downloadDir}/.incomplete 2775 transmission media -"
    ];

    # Add transmission user to media group
    users.users.transmission.extraGroups = [ "media" ];

    services.transmission = {
      enable = true;
      package = pkgs.transmission_4;

      settings = {
        # Download settings
        download-dir = cfg.downloadDir;
        incomplete-dir-enabled = true;
        incomplete-dir = "${cfg.downloadDir}/.incomplete";

        # Network settings
        peer-port = cfg.peerPort;
        port-forwarding-enabled = true;

        # RPC (Remote) settings
        rpc-enabled = true;
        rpc-port = cfg.rpcPort;
        rpc-bind-address = "0.0.0.0";
        rpc-whitelist-enabled = false;
        rpc-host-whitelist-enabled = false;
        rpc-authentication-required = false;

        # Performance settings
        speed-limit-down-enabled = false;
        speed-limit-up-enabled = false;
        upload-slots-per-torrent = 14;

        # Privacy
        dht-enabled = true;
        pex-enabled = true;
        lpd-enabled = true;
        encryption = 2; # Require encryption

        # Misc
        umask = 2;
        message-level = 2;
      };
    };

    # Install CLI tools for the user
    environment.systemPackages = with pkgs; [
      transmission_4  # Includes transmission-cli, transmission-remote
      tremc          # Terminal UI for transmission
    ];

    # Open firewall ports
    networking.firewall = {
      allowedTCPPorts = [ cfg.peerPort ];
      allowedUDPPorts = [ cfg.peerPort ];
    };
  };
}
