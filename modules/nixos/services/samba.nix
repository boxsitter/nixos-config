# modules/nixos/services/samba.nix
# Samba/SMB file sharing for Windows Explorer access

{ ... }:

{
  services.samba = {
    enable = true;
    openFirewall = false;  # Only accessible via Tailscale
    nmbd.enable = false;  # Disable NetBIOS (not needed for Tailscale)
    winbindd.enable = false;  # Disable Active Directory support
    
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "NixOS Server";
        "security" = "user";
        "hosts allow" = "100.64.0.0/10";  # Only Tailscale IPs
        "hosts deny" = "0.0.0.0/0";
        "map to guest" = "never";
      };
      
      # Home directory share
      home = {
        "path" = "/home/leyton";
        "browseable" = "yes";
        "read only" = "no";
        "valid users" = "leyton";
        "create mask" = "0644";
        "directory mask" = "0755";
        "comment" = "Home Directory";
      };

      # Media library share
      media = {
        "path" = "/var/lib/media";
        "browseable" = "yes";
        "read only" = "no";
        "valid users" = "leyton";
        "force group" = "media";  # Ensure all files/dirs are owned by media group
        "create mask" = "0664";  # rw-rw-r--
        "directory mask" = "2775"; # rwxrwsr-x with SetGID
        "comment" = "Media Library";
      };

      # Minecraft server data
      minecraft = {
        "path" = "/var/lib/minecraft";
        "browseable" = "yes";
        "read only" = "no";
        "valid users" = "leyton";
        "create mask" = "0664";
        "directory mask" = "0775";
        "comment" = "Minecraft Server Data";
      };
    };
  };
  
  # After rebuild, set Samba password with: sudo smbpasswd -a leyton
}
