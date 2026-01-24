# modules/nixos/services/radarr.nix
# Radarr movie collection manager

{ ... }:

{
  # Add the radarr user to the shared 'media' group
  users.users.radarr.extraGroups = [ "media" ];

  services.radarr = {
    enable = true;
    openFirewall = false; # Accessed via Caddy
  };

  # Ensure any files created by Radarr are group-writable.
  systemd.services.radarr.serviceConfig = {
    UMask = "0002";
    StateDirectory = "radarr";
  };
}
