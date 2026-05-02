# modules/nixos/services/komga.nix
# Komga manga/comic server

{ lib, ... }:

{
  # Add the komga user to the shared 'media' group
  users.users.komga.extraGroups = [ "media" ];

  services.komga = {
    enable = true;
    settings = {}; # This empty block is now required by the module
    # In the Komga UI, you will need to add a library pointing to /var/lib/media/manga
  };

  # Ensure new files created by Komga are group-writable.
  systemd.services.komga.serviceConfig = {
    UMask = lib.mkForce "0002";
    # Allow Komga to read the shared media folder.
    # It already has write access to its own state dir in /var/lib/komga.
    ReadOnlyPaths = [ "/var/lib/media/manga" ];
  };
}
