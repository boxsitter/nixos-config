# modules/nixos/secrets.nix
# Declarative secrets management with sops-nix

{ config, ... }:

{
  # Enable sops-nix for secrets management
  sops = {
    # Default sops file for all secrets
    defaultSopsFile = ../../secrets/secrets.yaml;
    
    # Use age for encryption (simpler than GPG)
    age = {
      # Server's age key will be generated at /etc/sops/age/keys.txt
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true; # Auto-generate on first boot
    };

    # Define secrets and their deployment locations
    secrets = {
      # Cloudflare API token for Caddy DNS-01 challenges
      cloudflare-dns-token = {
        owner = config.services.caddy.user;
        group = config.services.caddy.group;
        mode = "0400";
      };
    };
  };
}
