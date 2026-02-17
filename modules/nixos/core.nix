# modules/nixos/core.nix
# Shared base configuration for all systems

{ pkgs, lib, ... }:

{
  imports = [
    ./services/ssh.nix
    ./services/tailscale.nix
  ];

  networking.networkmanager.enable = lib.mkDefault true;

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  users.users.leyton = {
    isNormalUser = true;
    description = "Leyton Houck";
    home = "/home/leyton";
    extraGroups = [ "wheel" "networkmanager" "video" "input" ];
    shell = pkgs.fish;
  };

  programs.fish.enable = true;

  security.sudo = {
    wheelNeedsPassword = true;
    extraRules = [{
      users = [ "leyton" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/nix flake update";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/journalctl -u minecraft-server-main -f --no-hostname -o cat";
          options = [ "NOPASSWD" ];
        }
      ];
    }];
  };
  security.polkit.enable = lib.mkDefault true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    # Speed up builds - with 20 cores, limit to avoid memory pressure
    max-jobs = 12;  # Parallel package builds
    cores = 4;      # Cores per build job (12 * 4 = 48 effective, uses hyperthreading)
    # Enable binary cache
    substituters = [
      "https://cache.nixos.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
    # Optimize nix store
    auto-optimise-store = true;  # Automatically deduplicate
    # Use new experimental fetcher for faster downloads
    use-xdg-base-directories = true;
    # Download in parallel
    http-connections = 128;
    # Trust your user to use flake config settings
    trusted-users = [ "root" "@wheel" ];
    # Suppress dirty tree warnings system-wide
    warn-dirty = false;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  boot.kernel.sysctl = {
    "kernel.perf_event_paranoid" = 1;
    "kernel.kptr_restrict" = 0;
  };

  # Performance: Use systemd in initrd for faster parallel boot
  boot.initrd.systemd.enable = lib.mkDefault true;

  # Performance: Don't wait for all devices during boot
  systemd.services.systemd-udev-settle.enable = false;

  # Disable slow man page cache generation (only needed for man -k / apropos)
  documentation.man.generateCaches = false;

  environment.systemPackages = with pkgs; [
    # Core utilities
    git nano vim wget curl pciutils usbutils lshw htop btop tree file which
    strace lsof tcpdump sysprof
    
    # Nix tools
    nix-output-monitor  # Beautiful progress for nix builds (use: nom build)
    nix-fast-build      # Parallel builds for faster rebuilds
    
    # Shell and CLI enhancements
    fish fastfetch eza starship direnv nnn fzf ripgrep fd bat tmux
    
    # Text processing
    jq yq-go gnused gawk gnugrep
    
    # Networking tools
    dig nmap netcat-gnu inetutils openssh rsync iftop nload vnstat speedtest-cli nethogs
    
    # Git tools
    git git-lfs lazygit gh
    
    # Container and cluster management
    docker docker-compose lazydocker kubectl k9s helm
    
    # Databases
    postgresql sqlite
    
    # Nix development tools
    nixd nixpkgs-fmt nix-tree nix-index
    
    # Archive utilities
    unzip zip gzip bzip2 xz p7zip
    
    # Documentation and utilities
    bc man-pages man-pages-posix tldr entr watchexec

    # Mouse configuration
    piper
  ];

  # DO NOT CHANGE - set once at initial install
  system.stateVersion = "24.11";
}
