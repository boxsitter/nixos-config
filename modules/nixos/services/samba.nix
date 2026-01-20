# modules/nixos/services/samba.nix
# Samba/SMB file sharing for Windows Explorer access

{ ... }:

{
  services.samba = {
    enable = true;
    openFirewall = false;  # Only accessible via Tailscale
    enableNmbd = false;  # Disable NetBIOS (not needed for Tailscale)
    enableWinbindd = false;  # Disable Active Directory support
    
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "NixOS Server";
        "security" = "user";
        "hosts allow" = "100.64.0.0/10";  # Only Tailscale IPs
        "hosts deny" = "0.0.0.0/0";
        "map to guest" = "never";
      };
      
      # Minecraft server files
      minecraft = {
        "path" = "/var/lib/minecraft";
        "browseable" = "yes";
        "read only" = "no";
        "valid users" = "leyton";
        "force user" = "minecraft";
        "force group" = "minecraft";
        "create mask" = "0664";
        "directory mask" = "0775";
        "comment" = "Minecraft Server Files";
      };
      
      # Immich photos (read-only access)
      photos = {
        "path" = "/var/lib/immich";
        "browseable" = "yes";
        "read only" = "yes";
        "valid users" = "leyton";
        "force group" = "immich";
        "comment" = "Immich Photos";
      };
      
      # Manga library for Komga
      manga = {
        "path" = "/var/lib/komga/manga";
        "browseable" = "yes";
        "read only" = "no";
        "valid users" = "leyton";
        "force user" = "komga";
        "force group" = "komga";
        "create mask" = "0664";
        "directory mask" = "0775";
        "comment" = "Manga Library";
      };
      
      # Optional: Your home directory
      homes = {
        "path" = "/home/leyton";
        "browseable" = "yes";
        "read only" = "no";
        "valid users" = "leyton";
        "create mask" = "0644";
        "directory mask" = "0755";
        "comment" = "Home Directory";
      };
    };
  };
  
  # After rebuild, set Samba password with: sudo smbpasswd -a leyton
}
