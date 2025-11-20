# ./hosts/wsl/configuration.nix
# WSL2 configuration - no GUI, no bootloader

{ config, pkgs, ... }:

{
  imports = [
    # Shared modules
    ../../modules/core.nix
    ../../modules/shell/fish.nix
    # Note: No kitty.nix - terminal is provided by Windows
  ];

  # Enable WSL integration
  wsl = {
    enable = true;
    defaultUser = "leyton";
    startMenuLaunchers = true;
    
    # Disable Windows PATH appending for faster startup
    interop.appendWindowsPath = false;
    
    # Always start in home directory
    wslConf.automount.root = "/mnt";
  };
  
  # Set default directory to home for Fish shell
  programs.fish.loginShellInit = ''
    cd ~
  '';

  # Enable VS Code server for Remote-WSL
  programs.nix-ld.enable = true;

  # Set the flavor system-wide for Catppuccin modules
  catppuccin.flavor = "macchiato";

  # Hostname for WSL
  networking.hostName = "nixos-wsl";

  # WSL-specific: disable services that don't work
  networking.networkmanager.enable = false;  # WSL handles networking
  
  # Disable time sync - WSL syncs time with Windows host
  services.chrony.enable = pkgs.lib.mkForce false;
  
  # WSL doesn't need these
  console.font = null;
  console.packages = [];

  # 1Password CLI only (no GUI in WSL)
  # Already enabled in core.nix

  system.stateVersion = "24.11";
}
