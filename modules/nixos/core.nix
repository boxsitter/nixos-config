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
    # Speed up builds
    max-jobs = "auto";  # Use all CPU cores
    cores = 0;  # Use all cores per job
    # Enable binary cache
    substituters = [
      "https://cache.nixos.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
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

  environment.systemPackages = with pkgs; [
    # Core utilities
    git nano vim wget curl pciutils usbutils lshw htop btop tree file which
    strace lsof tcpdump sysprof
    
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
