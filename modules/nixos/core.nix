# modules/nixos/core.nix
# Shared base configuration for all systems

{ pkgs, lib, ... }:

{
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
      commands = [{
        command = "/run/current-system/sw/bin/nixos-rebuild";
        options = [ "NOPASSWD" ];
      }];
    }];
  };
  security.polkit.enable = lib.mkDefault true;

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

  environment.systemPackages = with pkgs; [
    git nano vim wget curl pciutils usbutils lshw htop btop tree file which
    strace lsof tcpdump
    fish fastfetch eza starship direnv nnn fzf ripgrep fd bat
    jq yq-go gnused gawk gnugrep
    dig nmap netcat-gnu inetutils openssh rsync
    git git-lfs lazygit gh
    docker docker-compose lazydocker kubectl k9s helm
    postgresql sqlite
    nil nixpkgs-fmt nix-tree nix-index
    unzip zip gzip bzip2 xz p7zip
    bc man-pages man-pages-posix tldr entr watchexec
  ];

  # DO NOT CHANGE - set once at initial install
  system.stateVersion = "24.11";
}
