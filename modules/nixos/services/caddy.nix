# modules/nixos/services/caddy.nix
# Caddy reverse proxy for tailnet-only hostnames via DNS-01 (Cloudflare)

{ config, pkgs, ... }:

{
  services.caddy = {
    enable = true;

    # Build Caddy with the Cloudflare DNS plugin for DNS-01 challenges.
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/cloudflare@v0.2.2" ];
      hash = "sha256-dnhEjopeA0UiI+XVYHYpsjcEI6Y1Hacbi28hVKYQURg=";
    };

    email = "admin@lhsv.net";  # ACME contact email

    virtualHosts = {
      "photos.lhsv.net".extraConfig = ''
        tls {
          dns cloudflare {env.CLOUDFLARE_API_TOKEN}
        }
        reverse_proxy 127.0.0.1:2283
      '';

      "manga.lhsv.net".extraConfig = ''
        tls {
          dns cloudflare {env.CLOUDFLARE_API_TOKEN}
        }
        reverse_proxy 127.0.0.1:8080
      '';
    };
  };

  # Load Cloudflare API token from sops-managed secret
  systemd.services.caddy.serviceConfig.EnvironmentFile = config.sops.secrets.cloudflare-dns-token.path;
}
