# modules/nixos/services/sabnzbd.nix
# SABnzbd usenet client

{ lib, ... }:

{
  # Add the sabnzbd user to the shared 'media' group
  users.users.sabnzbd.extraGroups = [ "media" ];

  services.sabnzbd = {
    enable = true;
    settings.misc = {
      port = 8085; # Default 8080 is used by Komga
      host_whitelist = "usenet.lhsv.net";
      # Use the same download directory as qBittorrent
      complete_dir = "/var/lib/media/downloads";
      download_dir = "/var/lib/media/downloads/.incomplete";
      # Set permissions for downloaded files and folders
      permissions = "0775"; # rwxrwxr-x for folders and files
    };
  };

  # Ensure any files created by SABnzbd are group-writable.
  systemd.services.sabnzbd.serviceConfig = {
    UMask = lib.mkForce "0002";
    # Allow writing to the shared downloads directory
    ReadWritePaths = [ "/var/lib/media/downloads" ];
  };
}