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
  };
}
