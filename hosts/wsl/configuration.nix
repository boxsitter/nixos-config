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
  };

  # Set the flavor system-wide for Catppuccin modules
  catppuccin.flavor = "macchiato";

  # Hostname for WSL
  networking.hostName = "nixos-wsl";

  # WSL-specific: disable services that don't work
  networking.networkmanager.enable = false;  # WSL handles networking
  
  # WSL doesn't need these
  console.font = null;
  console.packages = [];

  # 1Password CLI only (no GUI in WSL)
  # Already enabled in core.nix

  system.stateVersion = "24.11";
}
