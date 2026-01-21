# modules/nixos/services/minecraft.nix
# Minecraft Paper Server Configuration

{ pkgs, lib, ... }:

{
  services.minecraft-servers = {
    enable = true;
    eula = true;
    dataDir = "/home/leyton/media/minecraft";
    
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
  
  # Override ProtectHome to allow access to /home/leyton/media
  systemd.services.minecraft-server-main.serviceConfig.ProtectHome = lib.mkForce false;
  
  # Automatic daily backups
  systemd.services.minecraft-backup = {
    description = "Backup Minecraft world";
    serviceConfig = {
      Type = "oneshot";
      User = "minecraft";
      ExecStart = "${pkgs.bash}/bin/bash -c 'cd /home/leyton/media/minecraft/main && ${pkgs.gnutar}/bin/tar -czf /home/leyton/media/minecraft/backups/world-$(date +%Y%m%d-%H%M%S).tar.gz world'";
    };
  };
  
  systemd.timers.minecraft-backup = {
    description = "Backup Minecraft world daily";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
  
  systemd.tmpfiles.rules = [
    "d /home/leyton/media/minecraft/backups 0755 minecraft minecraft -"
  ];
}

