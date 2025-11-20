# ./modules/core.nix
# Shared base configuration for all systems

{ config, pkgs, lib, ... }:

{
  # Configure console with a modern font and Catppuccin theme
  console = {
    font = "${pkgs.terminus_font}/share/consolefonts/ter-v20n.psf.gz";
    packages = with pkgs; [ terminus_font ];
  };
  
  # Catppuccin TTY theme
  catppuccin.tty.enable = true;

  # Networking - common across systems
  networking.networkmanager.enable = lib.mkDefault true;

  # Time and locale
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

  # Security configuration
  security.sudo.wheelNeedsPassword = true;
  security.polkit.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
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

  # Common system packages across all environments
  environment.systemPackages = with pkgs; [
    # Core system tools
    git nano wget curl pciutils usbutils lshw htop tree

    # Shell and terminal
    fish fastfetch eza starship direnv

    # Development tools
    gcc mono jdk python3 racket bc

    # Archive utilities
    unzip zip

    # Network tools
    networkmanagerapplet
  ];

  # 1Password (GUI only on desktop/VM, CLI everywhere)
  programs._1password.enable = true;
}
