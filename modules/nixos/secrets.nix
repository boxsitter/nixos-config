# modules/nixos/secrets.nix
# Declarative secrets management with sops-nix

{ config, lib, ... }:

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
      # Cloudflare API token for Caddy DNS-01 challenges (server only)
      cloudflare-dns-token = lib.mkIf config.services.caddy.enable {
        owner = config.services.caddy.user;
        group = config.services.caddy.group;
        mode = "0400";
      };

      # Grafana admin password (read at startup via Grafana's $__file{...} syntax)
      grafana-admin-password = lib.mkIf config.services.grafana.enable {
        owner = "grafana";
        group = "grafana";
        mode = "0400";
      };

      # Grafana secret_key — encrypts datasource credentials and other DB-stored
      # secrets. No longer has a default in nixpkgs 26.05+.
      grafana-secret-key = lib.mkIf config.services.grafana.enable {
        owner = "grafana";
        group = "grafana";
        mode = "0400";
      };

      # *arr API keys consumed by exportarr-* exporters via systemd LoadCredential.
      # Mode 0444 is fine: each exporter runs as its own DynamicUser and the file
      # is loaded into the unit's credentials store, not read directly by clients.
      sonarr-api-key   = lib.mkIf config.services.prometheus.exporters.exportarr-sonarr.enable   { mode = "0444"; };
      radarr-api-key   = lib.mkIf config.services.prometheus.exporters.exportarr-radarr.enable   { mode = "0444"; };
      lidarr-api-key   = lib.mkIf config.services.prometheus.exporters.exportarr-lidarr.enable   { mode = "0444"; };
      prowlarr-api-key = lib.mkIf config.services.prometheus.exporters.exportarr-prowlarr.enable { mode = "0444"; };
      sabnzbd-api-key  = lib.mkIf config.services.prometheus.exporters.sabnzbd.enable            { mode = "0444"; };
    };
  };
}
