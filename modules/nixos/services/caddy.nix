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

    globalConfig = ''
      acme_dns cloudflare {env.CLOUDFLARE_API_TOKEN}
    '';

    virtualHosts = {
      "lhsv.net".extraConfig = ''
        tls {
          dns cloudflare {env.CLOUDFLARE_API_TOKEN}
        }
        reverse_proxy 127.0.0.1:3000
      '';

      "photos.lhsv.net".extraConfig = ''
        tls {
          dns cloudflare {env.CLOUDFLARE_API_TOKEN}
        }
        reverse_proxy [::1]:2283
      '';

      "manga.lhsv.net".extraConfig = ''
        tls {
          dns cloudflare {env.CLOUDFLARE_API_TOKEN}
        }
        reverse_proxy 127.0.0.1:8080
      '';

      "music.lhsv.net".extraConfig = ''
        tls {
          dns cloudflare {env.CLOUDFLARE_API_TOKEN}
        }
        reverse_proxy 127.0.0.1:4533
      '';

      "video.lhsv.net".extraConfig = ''
        tls {
          dns cloudflare {env.CLOUDFLARE_API_TOKEN}
        }
        reverse_proxy 127.0.0.1:8096
      '';

      "dl.lhsv.net".extraConfig = ''
        tls {
          dns cloudflare {env.CLOUDFLARE_API_TOKEN}
        }
        reverse_proxy 127.0.0.1:8081
      '';

      "indexer.lhsv.net".extraConfig = ''
        tls {
          dns cloudflare {env.CLOUDFLARE_API_TOKEN}
        }
        reverse_proxy 127.0.0.1:9696
      '';

      "movies.lhsv.net".extraConfig = ''
        tls {
          dns cloudflare {env.CLOUDFLARE_API_TOKEN}
        }
        reverse_proxy 127.0.0.1:7878
      '';

      "tv.lhsv.net".extraConfig = ''
        tls {
          dns cloudflare {env.CLOUDFLARE_API_TOKEN}
        }
        reverse_proxy 127.0.0.1:8989 {
          header_up X-Forwarded-Host {host}
          header_up X-Forwarded-Proto {scheme}
        }
      '';

      "system.lhsv.net".extraConfig = ''
        tls {
          dns cloudflare {env.CLOUDFLARE_API_TOKEN}
        }
        reverse_proxy 127.0.0.1:9090
      '';

      "status.lhsv.net".extraConfig = ''
        tls {
          dns cloudflare {env.CLOUDFLARE_API_TOKEN}
        }
        reverse_proxy 127.0.0.1:3001
      '';

      "audio.lhsv.net".extraConfig = ''
        tls {
          dns cloudflare {env.CLOUDFLARE_API_TOKEN}
        }
        reverse_proxy 127.0.0.1:8686
      '';

      "usenet.lhsv.net".extraConfig = ''
        tls {
          dns cloudflare {env.CLOUDFLARE_API_TOKEN}
        }
        reverse_proxy 127.0.0.1:8085
      '';

      "recipes.lhsv.net".extraConfig = ''
        tls {
          dns cloudflare {env.CLOUDFLARE_API_TOKEN}
        }
        reverse_proxy 127.0.0.1:9925
      '';

      "monitor.lhsv.net".extraConfig = ''
        tls {
          dns cloudflare {env.CLOUDFLARE_API_TOKEN}
        }
        reverse_proxy 127.0.0.1:19999 {
          header_up Host {http.reverse_proxy.upstream.hostport}
        }
      '';
    };
  };

  # Load Cloudflare API token from sops-managed secret
  systemd.services.caddy.serviceConfig.EnvironmentFile = config.sops.secrets.cloudflare-dns-token.path;
}
