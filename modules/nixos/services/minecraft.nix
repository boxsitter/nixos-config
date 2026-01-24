# modules/nixos/services/minecraft.nix
# Minecraft Paper Server Configuration

{ pkgs, lib, ... }:

{
  services.minecraft-servers = {
    enable = true;
    eula = true;
    dataDir = "/var/lib/minecraft";

    servers.main = {
      enable = true;
      autoStart = true;
      openFirewall = false;  # Using Tailscale/Playit instead
      
      # Use Paper server for plugin support
      package = pkgs.paperServers.paper-1_21_11;
      
      # JVM memory allocation - 8GB for 10-20 players
      jvmOpts = lib.concatStringsSep " " [
        "-Xmx8G"
        "-Xms8G"
        "-XX:+UseG1GC"
        "-XX:+ParallelRefProcEnabled"
        "-XX:MaxGCPauseMillis=200"
        "-XX:+UnlockExperimentalVMOptions"
        "-XX:+DisableExplicitGC"
        "-XX:+AlwaysPreTouch"
        "-XX:G1NewSizePercent=30"
        "-XX:G1MaxNewSizePercent=40"
        "-XX:G1HeapRegionSize=8M"
        "-XX:G1ReservePercent=20"
        "-XX:G1HeapWastePercent=5"
        "-XX:G1MixedGCCountTarget=4"
        "-XX:InitiatingHeapOccupancyPercent=15"
        "-XX:G1MixedGCLiveThresholdPercent=90"
        "-XX:G1RSetUpdatingPauseTimePercent=5"
        "-XX:SurvivorRatio=32"
        "-XX:+PerfDisableSharedMem"
        "-XX:MaxTenuringThreshold=1"
      ];
      
      # Server properties
      serverProperties = {
        # Basic server settings
        motd = "Knox's Minecraft Server";
        server-port = 25565;
        max-players = 20;
        gamemode = "survival";
        difficulty = "normal";
        hardcore = false;
        
        # World settings
        level-name = "world";
        level-seed = "";
        pvp = true;
        spawn-protection = 16;
        max-world-size = 29999984;
        
        # Performance settings
        view-distance = 16;
        simulation-distance = 16;
        max-tick-time = 60000;
        
        # Entity/mob spawning
        spawn-animals = true;
        spawn-monsters = true;
        spawn-npcs = true;
        
        # Network/security
        online-mode = true;
        white-list = false;
        enforce-whitelist = false;
        prevent-proxy-connections = false;
        enforce-secure-profile = false;
        
        # RCON for remote console
        enable-rcon = true;
        "rcon.port" = 25575;
        "rcon.password" = "minecraft";
      };
    };
  };

  # Add leyton to minecraft group for file access via Samba
  users.users.leyton.extraGroups = [ "minecraft" ];

  # Allow all loopback addresses (127.0.0.0/8) to connect to Minecraft
  # This is needed because Playit connects from various 127.x.x.x addresses
  networking.firewall.extraCommands = ''
    iptables -w -A nixos-fw-tailscale -s 127.0.0.0/8 -p tcp -m multiport --dports 25565,25575 -j ACCEPT
  '';

  # Automatic daily backups
  systemd.services.minecraft-backup = {
    description = "Backup Minecraft world";
    serviceConfig = {
      Type = "oneshot";
      User = "root"; # Run as root to have permissions to create the backup dir
      ExecStart = ''
        ${pkgs.bash}/bin/bash -c '
          mkdir -p /var/lib/minecraft/backups
          cd /var/lib/minecraft/main
          ${pkgs.gnutar}/bin/tar -czf /var/lib/minecraft/backups/world-$(date +%Y%m%d-%H%M%S).tar.gz world
          chown -R minecraft:minecraft /var/lib/minecraft/backups
        '
      '';
    };
  };

  # Timer to run the backup service daily at 3 AM
  systemd.timers.minecraft-backup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}

