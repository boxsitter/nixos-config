# modules/nixos/services/readarr.nix
# Readarr ebook/manga collection manager

{ ... }:

{
  # Add the readarr user to the shared 'media' group
  users.users.readarr.extraGroups = [ "media" ];

  services.readarr = {
    enable = true;
    openFirewall = false; # Accessed via Caddy
  };

  # Ensure any files created by Readarr are group-writable.
  systemd.services.readarr.serviceConfig = {
    UMask = "0002";
    StateDirectory = "readarr";
  };
}
