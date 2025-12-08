# modules/nixos/packages/cli.nix
# Core CLI packages for all systems (including WSL)

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Core system tools
    git nano wget curl pciutils usbutils lshw htop tree

    # Shell and terminal
    fish fastfetch eza starship direnv nnn

    # Development tools
    gcc mono jdk python3 bc
    
    # Nix development
    nil nixpkgs-fmt

    # Archive utilities
    unzip zip
  ];
}
