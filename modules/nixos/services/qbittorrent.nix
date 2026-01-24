{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.qbittorrent-custom;
in {
  options.services.qbittorrent-custom = {
    enable = mkOption {
      type = types.bool;
      default = true; # enable on import
      description = "Enable qBittorrent BitTorrent daemon";
    };

    downloadDir = mkOption {
      type = types.str;
      default = "/var/lib/media/downloads";
      description = "Directory to store downloaded files";
    };

    webUIPort = mkOption {
      type = types.int;
      default = 8081;
      description = "Port for Web UI";
    };

    peerPort = mkOption {
      type = types.int;
      default = 51413;
      description = "Port for incoming peer connections";
    };
  };

  config = mkIf cfg.enable {
    # Define the qbittorrent user and group
    users.users.qbittorrent = {
      isSystemUser = true;
      group = "qbittorrent";
      extraGroups = [ "media" ];
      home = "/var/lib/qbittorrent";
      createHome = true;
    };
    users.groups.qbittorrent = {};

    # qBittorrent service
    systemd.services.qbittorrent = {
      description = "qBittorrent BitTorrent Client";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        User = "qbittorrent";
        UMask = "0002"; # Create files as group-writable
        ExecStart = "${pkgs.qbittorrent-nox}/bin/qbittorrent-nox --webui-port=${toString cfg.webUIPort}";
        Restart = "on-failure";
        StateDirectory = "qbittorrent";
        
        # Security: Allow writing to its own state dir and the global downloads dir.
        ReadWritePaths = [ 
          cfg.downloadDir
        ];
      };
    };

    # Configure qBittorrent preferences
    environment.etc."qbittorrent/qBittorrent.conf".text = ''
      [Preferences]
      Downloads\SavePath=${cfg.downloadDir}
      Downloads\TempPath=${cfg.downloadDir}/.incomplete
      Downloads\TempPathEnabled=true
      Downloads\FinishedTorrentExportDir=
      Downloads\PreAllocation=false
      
      Connection\PortRangeMin=${toString cfg.peerPort}
      Connection\UPnP=true
      Connection\GlobalDLLimitAlt=0
      Connection\GlobalUPLimitAlt=0
      
      BitTorrent\DHT=true
      BitTorrent\PeX=true
      BitTorrent\LSD=true
      BitTorrent\Encryption=1
      BitTorrent\MaxRatioAction=0
      
      WebUI\Port=${toString cfg.webUIPort}
      WebUI\Address=0.0.0.0
      WebUI\LocalHostAuth=false
      WebUI\AuthSubnetWhitelistEnabled=true
      WebUI\AuthSubnetWhitelist=0.0.0.0/0, ::/0
      WebUI\Username=admin
      WebUI\Password_PBKDF2="@ByteArray(ARQ77eY1NUZaQsuDHbIMCA==:0WMRkYTUWVT9wVvdDtHAjU9b3b7uB8NR1Gur2hmQCvCDpm39Q+PsJRJPaCU51dEiz+dTzh8qbPsL8WkFljQYFQ==)"
      WebUI\CSRFProtection=false
      WebUI\ClickjackingProtection=false
      WebUI\HostHeaderValidation=false
      
      General\Locale=en
    '';

    # Copy config file to qbittorrent home directory at startup
    systemd.services.qbittorrent.preStart = ''
      mkdir -p /var/lib/qbittorrent/.config/qBittorrent
      cp -f /etc/qbittorrent/qBittorrent.conf /var/lib/qbittorrent/.config/qBittorrent/qBittorrent.conf
      chown -R qbittorrent:qbittorrent /var/lib/qbittorrent
    '';

    # Install CLI tools
    environment.systemPackages = with pkgs; [
      qbittorrent-nox
    ];

    # Open firewall ports
    networking.firewall = {
      allowedTCPPorts = [ cfg.peerPort ];
      allowedUDPPorts = [ cfg.peerPort ];
    };
  };
}
