# modules/nixos/core.nix
# Shared base configuration for all systems

{ pkgs, lib, ... }:

{
  imports = [
    ./services/ssh.nix
    ./services/tailscale.nix
  ];

  console = {
    font = "${pkgs.terminus_font}/share/consolefonts/ter-v20n.psf.gz";
    packages = with pkgs; [ terminus_font ];
  };

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

  nixpkgs = {
    config = {
      allowUnfree = true;
      nvidia.acceptLicense = true;
    };
  };

  # Fonts (system-wide)
  # Ensures "FiraCode Nerd Font" is available for Kitty/VS Code/etc.
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
  ];

  environment.systemPackages = with pkgs; [
    # Core utilities
    git nano vim wget curl pciutils usbutils lshw htop btop tree file which
    strace lsof tcpdump
    
    # Shell and CLI enhancements
    fish fastfetch eza starship direnv nnn fzf ripgrep fd bat tmux
    
    # Text processing
    jq yq-go gnused gawk gnugrep
    
    # Networking tools
    dig nmap netcat-gnu inetutils openssh rsync iftop nload vnstat speedtest-cli
    
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
  ];

  # DO NOT CHANGE - set once at initial install
  system.stateVersion = "24.11";
}
