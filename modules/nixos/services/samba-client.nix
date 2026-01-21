# modules/nixos/services/samba-client.nix
# Auto-mount Samba shares from server

{ config, pkgs, ... }:

{
  # Install Samba client utilities
  environment.systemPackages = [ pkgs.cifs-utils ];

  # Samba credentials managed via sops
  sops.secrets.samba-credentials = {
    mode = "0600";
  };

  # Mount server's home directory via Samba
  fileSystems."/mnt/server" = {
    device = "//nixos-server/home";
    fsType = "cifs";
    options = [
      "x-systemd.automount"              # Auto-mount on access
      "noauto"                            # Don't mount at boot
      "x-systemd.idle-timeout=600"       # Unmount after 10min idle
      "x-systemd.device-timeout=10s"     # Timeout if server unavailable
      "nofail"                            # Don't fail boot if unavailable
      "user"                              # Allow regular users to mount
      "uid=1000"                          # Mount as user leyton
      "gid=100"                           # Mount as group users
      "file_mode=0644"                    # Default file permissions
      "dir_mode=0755"                     # Default directory permissions
      "credentials=${config.sops.secrets.samba-credentials.path}"
    ];
  };

  # Create mount point
  systemd.tmpfiles.rules = [
    "d /mnt/server 0755 root root -"
  ];
}
