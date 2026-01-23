{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.homepage-dashboard-custom;
in {
  options.services.homepage-dashboard-custom = {
    enable = mkOption {
      type = types.bool;
      default = true; # enable on import
      description = "Enable Homepage dashboard";
    };

    port = mkOption {
      type = types.int;
      default = 3000;
      description = "Port for Homepage dashboard";
    };
  };

  config = mkIf cfg.enable {
    services.homepage-dashboard = {
      enable = true;
      listenPort = cfg.port;
      
      environmentFile = "${pkgs.writeText "homepage-env" ''
        HOMEPAGE_ALLOWED_HOSTS=lhsv.net
      ''}";

      settings = {
        title = "Home";
        favicon = "https://www.svgrepo.com/show/363696/house-duotone.svg";
        theme = "dark";
        color = "gray";
        headerStyle = "underlined";
        hideVersion = true;
        cardBlur = "";
        
          # Keep navigation on the same tab (so browser back works nicely)
          target = "_self";
        
        layout = [
          {
            System = {
              style = "column";
              columns = 1;
            };
          }
          {
            Downloads = {
              style = "column";
              columns = 1;
            };
          }
          {
            Media = {
              style = "column";
              columns = 1;
            };
          }
        ];
      };

      services = [
        {
          "System" = [
            {
              "Cockpit" = {
                href = "https://system.lhsv.net";
                icon = "cockpit.png";
              };
            }
            {
              "Uptime Kuma" = {
                href = "https://status.lhsv.net";
                icon = "uptime-kuma.png";
              };
            }
          ];
        }
      
        {
          "Media" = [
            {
              "Jellyfin" = {
                href = "https://video.lhsv.net";
                icon = "jellyfin.png";
              };
            }
            {
              "Navidrome" = {
                href = "https://music.lhsv.net";
                icon = "navidrome.png";
              };
            }
            {
              "Komga" = {
                href = "https://manga.lhsv.net";
                icon = "komga.png";
              };
            }
            {
              "Immich" = {
                href = "https://photos.lhsv.net";
                icon = "immich.png";
              };
            }
          ];
        }

        {
          "Downloads" = [
            {
              "qBittorrent" = {
                href = "https://dl.lhsv.net";
                icon = "qbittorrent.png";
              };
            }
            {
              "Radarr" = {
                href = "https://movies.lhsv.net";
                icon = "radarr.png";
              };
            }
            {
              "Sonarr" = {
                href = "https://tv.lhsv.net";
                icon = "sonarr.png";
              };
            }
            {
              "Prowlarr" = {
                href = "https://indexer.lhsv.net";
                icon = "prowlarr.png";
              };
            }
          ];
        }
      ];

      widgets = [
        {
          resources = {
            cpu = true;
            memory = true;
            disk = "/";
          };
        }
      ];
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}
