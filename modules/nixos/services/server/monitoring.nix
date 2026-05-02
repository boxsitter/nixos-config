# modules/nixos/services/server/monitoring.nix
# Prometheus + Grafana + Loki/Promtail with per-service CPU & network metrics.
# All bind 127.0.0.1; UIs are reached via Caddy at system.lhsv.net (Prometheus)
# and status.lhsv.net (Grafana) over Tailscale only.

{ config, lib, pkgs, ... }:

let
  ports = {
    prometheus       = 9090;
    grafana          = 3001;
    loki             = 3100;
    alloy            = 12345;
    nodeExporter     = 9100;
    systemdExporter  = 9558;
    processExporter  = 9256;
    smartctlExporter = 9633;
    sabnzbdExporter  = 9387;
    sonarrExporter   = 9707;
    radarrExporter   = 9708;
    lidarrExporter   = 9709;
    prowlarrExporter = 9710;
    caddyAdmin       = 2019;
  };

  fetchDash = id: rev: hash: pkgs.fetchurl {
    url  = "https://grafana.com/api/dashboards/${toString id}/revisions/${toString rev}/download";
    inherit hash;
  };

  dashboards = {
    # Hashes pinned to specific revisions on grafana.com.
    # To bump a dashboard: change rev, set hash to lib.fakeHash, rebuild — Nix
    # will print the new hash for you to paste back.
    "node-exporter-full.json" = fetchDash 1860  41 "sha256-EywgxEayjwNIGDvSmA/S56Ld49qrTSbIYFpeEXBJlTs=";
    "systemd-services.json"   = fetchDash 13978  1 "sha256-lrDxYEwG/2/YpJIv1PtgLinK1uf+YHLKDNiGumgBeVc=";
    "process-exporter.json"   = fetchDash  249   1 "sha256-4LLYY72jA+ih/JAbxy24prcW1bW+SUDHJ/FNGNR5SAk=";
    "smartctl.json"           = fetchDash 22381  1 "sha256-E1f+UvVNxg9DsvkLIsUwIqfFm5K+Wd4kKIg+8h1uxpg=";
    "logs-explorer.json"      = fetchDash 13639  2 "sha256-2dRUkooIA1E0Qshg58N+9duIW25iRruu1oW8ckBUNIA=";
    "exportarr.json"          = fetchDash 17665  1 "sha256-IYdsoVqc8Y6KVqr2FkoEuZnvPUg6HOhatcPTNC0M2+U=";
    # Caddy: no community dashboard with a stable grafana.com URL — metrics are
    # still scraped to Prometheus, import a dashboard manually if desired.
  };
in
{
  # --- systemd accounting (linchpin for per-service network metrics) ---
  # cgroup v2 + DefaultIPAccounting is what makes systemd_unit_ip_{ingress,egress}_bytes
  # available on the systemd_exporter (which itself needs --collector.ip-accounting).
  # Takes effect on next boot or after `systemctl daemon-reexec` + unit restart.
  systemd.settings.Manager = {
    DefaultCPUAccounting    = true;
    DefaultMemoryAccounting = true;
    DefaultIOAccounting     = true;
    DefaultIPAccounting     = true;
    DefaultTasksAccounting  = true;
  };

  # --- Exporters ---
  services.prometheus.exporters = {
    node = {
      enable = true;
      port = ports.nodeExporter;
      listenAddress = "127.0.0.1";
      enabledCollectors = [ "systemd" "processes" "interrupts" "tcpstat" "network_route" ];
    };

    systemd = {
      enable = true;
      port = ports.systemdExporter;
      listenAddress = "127.0.0.1";
      extraFlags = [ "--systemd.collector.enable-ip-accounting" ];
    };

    process = {
      enable = true;
      port = ports.processExporter;
      listenAddress = "127.0.0.1";
      settings.process_names = [
        { name = "{{.Comm}}"; cmdline = [ ".+" ]; }
      ];
    };

    smartctl = {
      enable = true;
      port = ports.smartctlExporter;
      listenAddress = "127.0.0.1";
      # Edit if `lsblk -d -o NAME,TYPE,MODEL,TRAN` lists different devices.
      devices = [ "/dev/nvme0" "/dev/sda" ];
    };

    exportarr-sonarr = {
      enable = true;
      port = ports.sonarrExporter;
      listenAddress = "127.0.0.1";
      url = "http://127.0.0.1:8989";
      apiKeyFile = config.sops.secrets.sonarr-api-key.path;
    };

    exportarr-radarr = {
      enable = true;
      port = ports.radarrExporter;
      listenAddress = "127.0.0.1";
      url = "http://127.0.0.1:7878";
      apiKeyFile = config.sops.secrets.radarr-api-key.path;
    };

    exportarr-lidarr = {
      enable = true;
      port = ports.lidarrExporter;
      listenAddress = "127.0.0.1";
      url = "http://127.0.0.1:8686";
      apiKeyFile = config.sops.secrets.lidarr-api-key.path;
    };

    exportarr-prowlarr = {
      enable = true;
      port = ports.prowlarrExporter;
      listenAddress = "127.0.0.1";
      url = "http://127.0.0.1:9696";
      apiKeyFile = config.sops.secrets.prowlarr-api-key.path;
    };

    sabnzbd = {
      enable = true;
      port = ports.sabnzbdExporter;
      listenAddress = "127.0.0.1";
      servers = [{
        baseUrl = "http://127.0.0.1:8085";
        apiKeyFile = config.sops.secrets.sabnzbd-api-key.path;
      }];
    };
  };

  # Caddy's /metrics endpoint requires the `metrics` global option.
  # Enabling it here keeps the wiring co-located with the scrape job below.
  services.caddy.globalConfig = lib.mkAfter ''
    servers {
      metrics
    }
  '';

  # --- Prometheus ---
  services.prometheus = {
    enable = true;
    port = ports.prometheus;
    listenAddress = "127.0.0.1";
    retentionTime = "30d";
    globalConfig.scrape_interval = "15s";
    scrapeConfigs = [
      { job_name = "prometheus";
        static_configs = [{ targets = [ "127.0.0.1:${toString ports.prometheus}" ]; }]; }
      { job_name = "node";
        static_configs = [{ targets = [ "127.0.0.1:${toString ports.nodeExporter}" ]; }]; }
      { job_name = "systemd";
        static_configs = [{ targets = [ "127.0.0.1:${toString ports.systemdExporter}" ]; }]; }
      { job_name = "process";
        static_configs = [{ targets = [ "127.0.0.1:${toString ports.processExporter}" ]; }]; }
      { job_name = "smartctl";
        scrape_interval = "60s";
        static_configs = [{ targets = [ "127.0.0.1:${toString ports.smartctlExporter}" ]; }]; }
      { job_name = "caddy";
        static_configs = [{ targets = [ "127.0.0.1:${toString ports.caddyAdmin}" ]; }]; }
      { job_name = "exportarr-sonarr";
        static_configs = [{ targets = [ "127.0.0.1:${toString ports.sonarrExporter}" ]; }]; }
      { job_name = "exportarr-radarr";
        static_configs = [{ targets = [ "127.0.0.1:${toString ports.radarrExporter}" ]; }]; }
      { job_name = "exportarr-lidarr";
        static_configs = [{ targets = [ "127.0.0.1:${toString ports.lidarrExporter}" ]; }]; }
      { job_name = "exportarr-prowlarr";
        static_configs = [{ targets = [ "127.0.0.1:${toString ports.prowlarrExporter}" ]; }]; }
      { job_name = "sabnzbd";
        static_configs = [{ targets = [ "127.0.0.1:${toString ports.sabnzbdExporter}" ]; }]; }
      { job_name = "loki";
        static_configs = [{ targets = [ "127.0.0.1:${toString ports.loki}" ]; }]; }
      { job_name = "alloy";
        static_configs = [{ targets = [ "127.0.0.1:${toString ports.alloy}" ]; }]; }
    ];
  };

  # --- Loki ---
  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;
      server = {
        http_listen_address = "127.0.0.1";
        http_listen_port = ports.loki;
        grpc_listen_address = "127.0.0.1";
      };
      common = {
        path_prefix = "/var/lib/loki";
        replication_factor = 1;
        ring = {
          instance_addr = "127.0.0.1";
          kvstore.store = "inmemory";
        };
      };
      schema_config.configs = [{
        from = "2024-01-01";
        store = "tsdb";
        object_store = "filesystem";
        schema = "v13";
        index = { prefix = "index_"; period = "24h"; };
      }];
      storage_config = {
        tsdb_shipper = {
          active_index_directory = "/var/lib/loki/tsdb-index";
          cache_location = "/var/lib/loki/tsdb-cache";
        };
        filesystem.directory = "/var/lib/loki/chunks";
      };
      limits_config = {
        allow_structured_metadata = true;
        retention_period = "30d";
      };
      compactor = {
        working_directory = "/var/lib/loki/compactor";
        retention_enabled = true;
        delete_request_store = "filesystem";
      };
      analytics.reporting_enabled = false;
    };
  };

  # --- Alloy (journal -> Loki). Replaces Promtail, which was retired upstream. ---
  services.alloy = {
    enable = true;
    extraFlags = [
      "--server.http.listen-addr=127.0.0.1:${toString ports.alloy}"
      "--disable-reporting"
    ];
  };

  environment.etc."alloy/config.alloy".text = ''
    loki.write "default" {
      endpoint {
        url = "http://127.0.0.1:${toString ports.loki}/loki/api/v1/push"
      }
    }

    loki.relabel "journal" {
      forward_to = []
      rule {
        source_labels = ["__journal__systemd_unit"]
        target_label  = "unit"
      }
      rule {
        source_labels = ["__journal__hostname"]
        target_label  = "host"
      }
      rule {
        source_labels = ["__journal_priority_keyword"]
        target_label  = "level"
      }
    }

    loki.source.journal "read" {
      forward_to    = [loki.write.default.receiver]
      relabel_rules = loki.relabel.journal.rules
      labels        = {
        job = "systemd-journal",
      }
      max_age       = "12h"
    }
  '';

  # Pass secrets via GF_*__FILE env vars — the only mechanism Grafana reliably
  # processes before writing the initial admin user to the DB. The $__file{}
  # ini syntax only works in datasource provisioning, not in grafana.ini.
  systemd.services.grafana.environment = {
    GF_SECURITY_ADMIN_PASSWORD__FILE = config.sops.secrets.grafana-admin-password.path;
    GF_SECURITY_SECRET_KEY__FILE     = config.sops.secrets.grafana-secret-key.path;
  };

  # --- Grafana ---
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "127.0.0.1";
        http_port = ports.grafana;
        domain = "status.lhsv.net";
        root_url = "https://status.lhsv.net/";
      };
      security.admin_user = "admin";
      analytics.reporting_enabled = false;
      "auth.anonymous".enabled = false;
    };
    provision = {
      enable = true;
      datasources.settings.datasources = [
        { name = "Prometheus";
          type = "prometheus";
          url  = "http://127.0.0.1:${toString ports.prometheus}";
          isDefault = true; }
        { name = "Loki";
          type = "loki";
          url  = "http://127.0.0.1:${toString ports.loki}"; }
      ];
      dashboards.settings.providers = [{
        name = "default";
        options.path = "/var/lib/grafana/dashboards";
      }];
    };
  };

  # --- Dashboard provisioning ---
  systemd.tmpfiles.rules =
    [ "d /var/lib/grafana/dashboards 0755 grafana grafana -" ]
    ++ lib.mapAttrsToList
         (name: src: "L+ /var/lib/grafana/dashboards/${name} - - - - ${src}")
         dashboards;
}
