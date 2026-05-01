# modules/nixos/services/sonarr.nix
# Sonarr TV show collection manager

{ ... }:

{
  # Add the sonarr user to the shared 'media' group
  users.users.sonarr.extraGroups = [ "media" ];

  services.sonarr = {
    enable = true;
    openFirewall = false; # Accessed via Caddy
  };

  # Ensure any files created by Sonarr are group-writable.
  systemd.services.sonarr.serviceConfig = {
    UMask = "0002";
    StateDirectory = "sonarr";
    
    # Restart configuration to handle unresponsive service
    Restart = "on-failure";
    RestartSec = "5s";
    
    # Timeout settings to prevent hanging
    TimeoutStopSec = "20s";
    TimeoutStartSec = "60s";
    
    # Kill settings - ensure all processes are terminated properly
    KillMode = "mixed";
    KillSignal = "SIGTERM";
    
    # Limit restart frequency to prevent restart loops
    StartLimitBurst = 5;
    StartLimitIntervalSec = 300;
  };
}
