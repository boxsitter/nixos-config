# modules/nixos/services/komga.nix
# Komga manga/comic server

{ pkgs, ... }:

{
  # Create komga user and group
  users.users.komga = {
    isSystemUser = true;
    group = "komga";
    home = "/var/lib/komga";
    createHome = true;
  };
  
  users.groups.komga = {};
  
  # Add leyton to komga group for file access
  users.users.leyton.extraGroups = [ "komga" ];
  
  # Create manga library directory
  systemd.tmpfiles.rules = [
    "d /var/lib/komga 0755 komga komga -"
    "d /var/lib/komga/data 0755 komga komga -"
    "d /var/lib/komga/manga 0775 komga komga -"
  ];
  
  # Komga systemd service
  systemd.services.komga = {
    description = "Komga manga/comic server";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    
    environment = {
      KOMGA_CONFIGDIR = "/var/lib/komga/data";
      SERVER_PORT = "8080";
      SERVER_SERVLET_CONTEXT_PATH = "/";
    };
    
    serviceConfig = {
      User = "komga";
      Group = "komga";
      WorkingDirectory = "/var/lib/komga";
      ExecStart = "${pkgs.komga}/bin/komga";
      Restart = "on-failure";
      RestartSec = "10s";
      
      # Security hardening
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ReadWritePaths = [ "/var/lib/komga" ];
    };
  };
}
