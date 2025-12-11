# modules/nixos/common.nix
# Shared base configuration for all systems

{ pkgs, lib, ... }:

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

  # Enable fish shell system-wide
  programs.fish.enable = true;

  # Security configuration
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
  security.polkit.enable = lib.mkDefault true;  # Disabled in WSL

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
  # Packages are now organized in modules/nixos/packages/
  # Import cli.nix, gui.nix, etc. per-host as needed

  # 1Password (GUI only on desktop/VM, CLI everywhere)
  programs._1password.enable = true;
}
